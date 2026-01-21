`timescale 1ns / 1ps

module i2c_edid
       #(
           parameter HEX_FILE = "D:/G7_Code_DVI2LVDS/rtl_code/C103HAN09.0.hex",
           parameter DEVICE_ADDR = 7'h50 // 0xA0 >> 1
       )
       (
           input wire clk, // System Clock (e.g. 50MHz - 100MHz)
           input wire rst_n, // Active Low Reset
           input wire scl, // I2C Clock
           inout wire sda // I2C Data
       );

// --- 1. 訊號同步與濾波 (Synchronization) ---
reg [2:0] scl_r, sda_r;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        scl_r <= 3'b111;
        sda_r <= 3'b111;
    end
    else begin
        scl_r <= {scl_r[1:0], scl};
        sda_r <= {sda_r[1:0], sda};
    end
end

wire scl_in = scl_r[1];
wire sda_in = sda_r[1];

// 邊緣檢測 (Edge Detection)
wire scl_rise = (scl_r[2:1] == 2'b01);
wire scl_fall = (scl_r[2:1] == 2'b10);

// Start / Stop 條件偵測
wire start_cond = (scl_in && sda_r[2:1] == 2'b10);
wire stop_cond = (scl_in && sda_r[2:1] == 2'b01);

// --- 2. 狀態機定義 ---
localparam S_IDLE = 0;
localparam S_GET_ADDR = 1;
localparam S_ACK_ADDR = 2;
localparam S_GET_OFFSET = 3;
localparam S_ACK_OFFSET = 4;
localparam S_SEND_DATA = 5;
localparam S_WAIT_ACK = 6;

reg [3:0] state;
reg [2:0] bit_cnt;
reg [7:0] shift_reg; // 用於接收或發送數據
reg [7:0] offset_reg; // 當前 EDID 讀取指標
reg sda_wen; // 1=拉低(0), 0=釋放(Z)

// --- 3. ROM 實例化 ---
wire [7:0] rom_dout;

// 注意：這裡假設 ROM 是純組合邏輯或同步讀取
// 在此設計中，我們利用 offset_reg 持續給出地址，
// 並在需要發送資料的前一刻鎖存 rom_dout。
edid_rom #(.HEX_FILE(HEX_FILE)) rom_inst (
             .clk(clk),
             .addr(offset_reg),
             .dout(rom_dout)
         );

// I2C Open-Drain 輸出邏輯
assign sda = (sda_wen) ? 1'b0 : 1'bz;

// --- 4. 主邏輯 ---
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= S_IDLE;
        sda_wen <= 1'b0;
        bit_cnt <= 0;
        shift_reg <= 0;
        offset_reg <= 0;
    end
    else begin
        if (start_cond) begin
            state <= S_GET_ADDR;
            bit_cnt <= 7;
            sda_wen <= 1'b0;
        end
        else if (stop_cond) begin
            state <= S_IDLE;
            sda_wen <= 1'b0;
        end
        else begin
            case (state)
                S_IDLE: begin
                    sda_wen <= 1'b0;
                end

                // --- 接收 7-bit 地址 + R/W ---
                S_GET_ADDR: begin
                    if (scl_rise) begin
                        shift_reg <= {shift_reg[6:0], sda_in};
                        if (bit_cnt == 0)
                            state <= S_ACK_ADDR;
                        else
                            bit_cnt <= bit_cnt - 1;
                    end
                end

                // --- 判斷地址並回應 ACK ---
                S_ACK_ADDR: begin
                    // 檢查地址是否為 0x50
                    if (shift_reg[7:1] == DEVICE_ADDR) begin
                        // 在 SCL 下降緣拉低 SDA (ACK)
                        if (scl_fall)
                            sda_wen <= 1'b1;

                        // 在 ACK 結束後的那個 SCL 下降緣，決定下一步
                        // 這是一個完整的 I2C Bit Cycle 結束
                        // 我們必須在這裡準備好下一個狀態的資料
                        if (scl_fall && sda_wen) begin
                            if (shift_reg[0] == 1'b0) begin
                                // R/W=0 (Write) -> 準備接收 Offset
                                sda_wen <= 1'b0; // 釋放 SDA
                                state <= S_GET_OFFSET;
                                bit_cnt <= 7;
                            end
                            else begin
                                // R/W=1 (Read) -> 準備發送資料
                                // [關鍵修正]：直接載入 ROM 資料並驅動 MSB
                                shift_reg <= rom_dout; // 載入目前 Offset 的資料
                                sda_wen <= ~rom_dout[7]; // 如果 Bit7是0，sda_wen=1(拉低)
                                state <= S_SEND_DATA;
                                bit_cnt <= 7; // 從 Bit 7 開始，下次 SCL 下降緣處理 Bit 6
                            end
                        end
                    end
                    else begin
                        // 地址不對，忽略
                        state <= S_IDLE;
                    end
                end

                // --- 接收 Offset (Word Address) ---
                S_GET_OFFSET: begin
                    if (scl_rise) begin
                        offset_reg <= {offset_reg[6:0], sda_in};
                        if (bit_cnt == 0)
                            state <= S_ACK_OFFSET;
                        else
                            bit_cnt <= bit_cnt - 1;
                    end
                end

                // --- Offset ACK ---
                S_ACK_OFFSET: begin
                    if (scl_fall)
                        sda_wen <= 1'b1; // Drive ACK

                    if (scl_fall && sda_wen) begin
                        sda_wen <= 1'b0; // Release
                        state <= S_IDLE; // 等待 Repeated Start
                    end
                end

                // --- 發送資料 (Read Mode) ---
                S_SEND_DATA: begin
                    // 注意：Bit 7 已經在進入此狀態時驅動了
                    if (scl_fall) begin
                        if (bit_cnt == 0) begin
                            // 8 bits 發送完畢，釋放 SDA 等待主機 ACK
                            sda_wen <= 1'b0;
                            state <= S_WAIT_ACK;
                        end
                        else begin
                            // 準備下一個 Bit
                            // 因為 bit_cnt 還沒減，這裡用 bit_cnt-1 或是移位後的 shift_reg
                            sda_wen <= ~shift_reg[6]; // 下一個 Bit 是 shift_reg[6]
                            shift_reg <= {shift_reg[6:0], 1'b0};
                            bit_cnt <= bit_cnt - 1;
                        end
                    end
                end

                // --- 等待主機 ACK/NACK ---
                S_WAIT_ACK: begin
                    if (scl_rise) begin
                        if (sda_in == 1'b0) begin
                            // Master ACKed (想要更多資料)
                            offset_reg <= offset_reg + 1; // 準備下一個 Byte
                        end
                        else begin
                            // Master NACKed (讀取結束)
                            state <= S_IDLE;
                        end
                    end

                    if (scl_fall && state == S_WAIT_ACK && sda_in == 1'b0) begin
                        // Master 已經 ACK，準備發送下一個 Byte 的 Bit 7
                        // 此時 offset_reg 已經加 1，rom_dout 是新資料
                        shift_reg <= rom_dout;
                        sda_wen <= ~rom_dout[7];
                        state <= S_SEND_DATA;
                        bit_cnt <= 7;
                    end
                end

                default:
                    state <= S_IDLE;
            endcase
        end
    end
end
endmodule
