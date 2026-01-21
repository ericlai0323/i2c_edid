`timescale 1ns/1ps

module tb_edid_rom;

reg clk;
reg [7:0] addr;
wire [7:0] dout;

// clock
initial begin
    clk = 0;
    forever
        #5 clk = ~clk;
end

// DUT
edid_rom #(
             .HEX_FILE("D:/G7_Code_DVI2LVDS/rtl_code/C103HAN09.0.hex")
         ) dut (
             .clk (clk),
             .addr(addr),
             .dout(dout)
         );

initial begin
    addr = 0;

    #20;
    repeat (16) begin
        @(posedge clk);
        $display("addr=%02X data=%02X", addr, dout);
        addr = addr + 1;
    end

    #100;
    $finish;
end

endmodule
