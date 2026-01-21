`timescale 1ns / 1ps

module tb_i2c_edid();

reg clk;
reg rst_n;
reg scl_driver;
reg sda_driver;
wire scl;
wire sda;

// 模擬上拉電阻 (Pull-up)
assign scl = (scl_driver) ? 1'bz : 1'b0;
assign sda = (sda_driver) ? 1'bz : 1'b0;
pullup(scl);
pullup(sda);

// 參數設置
localparam CLK_PERIOD = 10; // 100MHz system clock
localparam I2C_BIT_DLY = 2000; // I2C 速度模擬 (半週期)

// 實例化 DUT
i2c_edid #(
             .HEX_FILE("D:/G7_Code_DVI2LVDS/rtl_code/C103HAN09.0.hex")
         ) dut (
             .clk(clk),
             .rst_n(rst_n),
             .scl(scl),
             .sda(sda)
         );

// 時鐘產生
initial
    clk = 0;
always #(CLK_PERIOD/2) clk = ~clk;

// 變數
integer i, err;
reg [7:0] rx_data;
reg [7:0] expected_mem [0:255];

// --- 測試流程 ---
initial begin
    // 1. 建立測試用的 Hex 檔案 (內容: 00, 01, 02 ... FF)
    // create_hex_file();
    $readmemh("D:/G7_Code_DVI2LVDS/rtl_code/C103HAN09.0.hex", expected_mem); // Load expected data

    // 2. 初始化訊號
    rst_n = 0;
    scl_driver = 1;
    sda_driver = 1;
    err = 0;

    #500 rst_n = 1;
    #500;

    $display("=== Simulation Start ===");

    // 3. 設定讀取地址 (Write 0xA0 -> Offset 0x00)
    i2c_start();
    i2c_write(8'hA0); // Slave Addr + Write
    check_ack();
    i2c_write(8'h00); // Word Address 0
    check_ack();
    // 這裡不送 Stop，直接送 Repeated Start

    // 4. 開始讀取 (Read 0xA1)
    i2c_start();
    i2c_write(8'hA1); // Slave Addr + Read
    check_ack();

    // 5. 連續讀取 128 個 Byte
    for (i=0; i<128; i=i+1) begin
        i2c_read(rx_data);

        // 比對資料 (因為我們寫入的 hex 是 00, 01, 02...)
        if (rx_data !== expected_mem[i]) begin
            $display("[ERROR] Addr 0x%02x: Expected %02x, Got %02x", i, expected_mem[i], rx_data);
            err = err + 1;
        end
        else begin
            $display("[PASS] Addr 0x%02x: Got %02x", i, rx_data);
        end

        // 最後一個 Byte 送 NACK，其他送 ACK
        if (i == 127)
            i2c_nack();
        else
            i2c_ack();
    end

    i2c_stop();

    if (err == 0)
        $display("=== TEST PASSED ===");
    else
        $display("=== TEST FAILED with %d errors ===", err);

    $finish;
end

// --- I2C Tasks ---

// 建立 hex 檔 task
task create_hex_file;
    integer f, k;
    begin
        f = $fopen("edid_tb_data.hex", "w");
        if (f) begin
            for (k=0; k<256; k=k+1)
                $fwrite(f, "%02x\n", k);
            $fclose(f);
            $display("Hex file created.");
        end
        else begin
            $display("Error creating hex file.");
        end
    end
endtask

task i2c_start;
    begin
        sda_driver = 1;
        scl_driver = 1;
        #I2C_BIT_DLY;
        sda_driver = 0;
        #I2C_BIT_DLY;
        scl_driver = 0;
        #I2C_BIT_DLY;
    end
endtask

task i2c_stop;
    begin
        sda_driver = 0;
        scl_driver = 0;
        #I2C_BIT_DLY;
        scl_driver = 1;
        #I2C_BIT_DLY;
        sda_driver = 1;
        #I2C_BIT_DLY;
    end
endtask

task i2c_write(input [7:0] d);
    integer k;
    begin
        for(k=7; k>=0; k=k-1) begin
            sda_driver = d[k];
            #I2C_BIT_DLY;
            scl_driver = 1;
            #I2C_BIT_DLY;
            scl_driver = 0;
            #I2C_BIT_DLY;
        end
        sda_driver = 1; // Release for ACK
    end
endtask

task i2c_read(output [7:0] d);
    integer k;
    begin
        sda_driver = 1; // Release bus
        for(k=7; k>=0; k=k-1) begin
            #I2C_BIT_DLY;
            scl_driver = 1;
            d[k] = sda; // Sample
            #I2C_BIT_DLY;
            scl_driver = 0;
            #I2C_BIT_DLY;
        end
    end
endtask

task check_ack;
    begin
        #I2C_BIT_DLY;
        scl_driver = 1;
        #I2C_BIT_DLY;
        if (sda !== 0)
            $display("NACK detected where ACK expected!");
        scl_driver = 0;
        #I2C_BIT_DLY;
    end
endtask

task i2c_ack;
    begin
        sda_driver = 0;
        #I2C_BIT_DLY;
        scl_driver = 1;
        #I2C_BIT_DLY;
        scl_driver = 0;
        #I2C_BIT_DLY;
        sda_driver = 1;
    end
endtask

task i2c_nack;
    begin
        sda_driver = 1;
        #I2C_BIT_DLY;
        scl_driver = 1;
        #I2C_BIT_DLY;
        scl_driver = 0;
        #I2C_BIT_DLY;
    end
endtask

endmodule
