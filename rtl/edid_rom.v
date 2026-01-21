`timescale 1ns / 1ps

module edid_rom
       #(
           parameter HEX_FILE = "D:/G7_Code_DVI2LVDS/rtl_code/C103HAN09.0.hex"
       )
       (
           input wire clk,
           input wire [7:0] addr,
           output reg [7:0] dout
       );
reg [7:0] mem [0:255];

initial begin
    // 若 Simulation 報錯找不到檔案，請將 hex 檔放在 project_name.sim/sim_1/behav/xsim/ 目錄下
    // 或者使用絕對路徑
    $readmemh(HEX_FILE, mem);
end

always @(posedge clk) begin
    dout <= mem[addr];
end
endmodule
