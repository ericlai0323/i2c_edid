module G7_DVI2LVDS (
           // Switch / reset
           input  iOSC, // 25MHz
           input  iRESET, // Low Active
           input  iSW0,
           input  iSW1,
           input  iSW2,
           input  iSW3,

           // EXPB bits (EXPB_Bit2 is noted as clock in your comment)
           input  EXPB_Bit0, // VS
           input  EXPB_Bit1, // HS
           input  EXPB_Bit2, // DCLK
           input  EXPB_Bit3, // DE
           input  EXPB_Bit4, // RE7
           input  EXPB_Bit5, // RE6
           input  EXPB_Bit6, // RE5
           input  EXPB_Bit7, // RE4
           input  EXPB_Bit8, // RE3
           input  EXPB_Bit9, // RE2
           input  EXPB_Bit10, // RE1
           input  EXPB_Bit11, // RE0
           input  EXPB_Bit12, // GE7
           input  EXPB_Bit13, // GE6
           input  EXPB_Bit14, // GE5
           input  EXPB_Bit15, // GE4
           input  EXPB_Bit16, // GE3
           input  EXPB_Bit17, // GE2
           input  EXPB_Bit18, // GE1
           input  EXPB_Bit19, // GE0
           input  EXPB_Bit20, // BE7
           input  EXPB_Bit21, // BE6
           input  EXPB_Bit22, // BE5
           input  EXPB_Bit23, // BE4
           input  EXPB_Bit24, // BE3
           input  EXPB_Bit25, // BE2
           input  EXPB_Bit26, // BE1
           input  EXPB_Bit27, // BE0
           inout wire EXPB_Bit28, //SDA
           input wire EXPB_Bit29, //SCL

           // STB
           output oSTB, // 1

           // A-side LVDS
           output A_rx0_p,
           output A_rx0_n,
           output A_rx1_p,
           output A_rx1_n,
           output A_rx2_p,
           output A_rx2_n,
           output A_rx3_p,
           output A_rx3_n,
           output A_rx4_p,
           output A_rx4_n,

           // B-side LVDS
           output B_rx0_p,
           output B_rx0_n,
           output B_rx1_p,
           output B_rx1_n,
           output B_rx2_p,
           output B_rx2_n,
           output B_rx3_p,
           output B_rx3_n,
           output B_rx4_p,
           output B_rx4_n,

           // Clock outputs
           output A_clkout_p,
           output A_clkout_n,
           output B_clkout_p,
           output B_clkout_n,

           // A-side LVDS
           output A2_rx0_p,
           output A2_rx0_n,
           output A2_rx1_p,
           output A2_rx1_n,
           output A2_rx2_p,
           output A2_rx2_n,
           output A2_rx3_p,
           output A2_rx3_n,
           output A2_rx4_p,
           output A2_rx4_n,

           // B-side LVDS
           output B2_rx0_p,
           output B2_rx0_n,
           output B2_rx1_p,
           output B2_rx1_n,
           output B2_rx2_p,
           output B2_rx2_n,
           output B2_rx3_p,
           output B2_rx3_n,
           output B2_rx4_p,
           output B2_rx4_n,

           // Clock outputs
           output A2_clkout_p,
           output A2_clkout_n,
           output B2_clkout_p,
           output B2_clkout_n,

           // Debug
           output EXIP_0_D7,
           output EXIP_1_D8
       );




wire [6:0]A_txd_0,A_txd_1,A_txd_2,A_txd_3,A_txd_4;
wire [6:0]B_txd_0,B_txd_1,B_txd_2,B_txd_3,B_txd_4;

wire [6:0]jA_txd_1,jA_txd_2,jA_txd_3,jA_txd_4;
wire [6:0]jB_txd_1,jB_txd_2,jB_txd_3,jB_txd_4;

wire [6:0]vA_txd_1,vA_txd_2,vA_txd_3,vA_txd_4;
wire [6:0]vB_txd_1,vB_txd_2,vB_txd_3,vB_txd_4;

wire[7:0] oRDATA_86,oGDATA_86,oBDATA_86;
wire[7:0] R_data_a,G_data_a,B_data_a,R_data_b,G_data_b,B_data_b;

wire[7:0] 	R_data_a_t,
    G_data_a_t,
    B_data_a_t,

    R_data_b_t,
    G_data_b_t,
    B_data_b_t;

wire DE,H_SYNC,V_SYNC,Tclk;

wire[7:0]					DVIrdata;
wire[7:0]					DVIgdata;
wire[7:0]					DVIbdata;

wire[7:0]					DVIrdata86;
wire[7:0]					DVIgdata86;
wire[7:0]					DVIbdata86;
wire							DVI_VS;
wire							DVI_HS;
wire							DVI_DE;
wire							DVI_clk;

// BUFG		iexpb_clk_bufg(.I(EXPB_Bit2), .O(DVI_clk));

assign DVI_clk = EXPB_Bit2;

assign DVI_DE = EXPB_Bit3;
assign DVI_HS = EXPB_Bit1;
assign DVI_VS = EXPB_Bit0;

assign DVIrdata = {EXPB_Bit4, EXPB_Bit5, EXPB_Bit6, EXPB_Bit7, EXPB_Bit8, EXPB_Bit9, EXPB_Bit10, EXPB_Bit11};
assign DVIgdata = {EXPB_Bit12, EXPB_Bit13, EXPB_Bit14, EXPB_Bit15, EXPB_Bit16, EXPB_Bit17, EXPB_Bit18, EXPB_Bit19};
assign DVIbdata = {EXPB_Bit20, EXPB_Bit21, EXPB_Bit22, EXPB_Bit23, EXPB_Bit24, EXPB_Bit25, EXPB_Bit26, EXPB_Bit27};

assign DVIrdata86=(iSW1==1'b0)?DVIrdata:{2'b00,DVIrdata[7:2]};
assign DVIgdata86=(iSW1==1'b0)?DVIgdata:{2'b00,DVIgdata[7:2]};
assign DVIbdata86=(iSW1==1'b0)?DVIbdata:{2'b00,DVIbdata[7:2]};

assign A_txd_4[6]=1;
assign A_txd_4[5]=1;
assign A_txd_4[4]=1;
assign A_txd_4[3]=1;
assign A_txd_4[2]=1;
assign A_txd_4[1]=1;
assign A_txd_4[0]=1;

assign B_txd_4[6]=1;
assign B_txd_4[5]=1;
assign B_txd_4[4]=1;
assign B_txd_4[3]=1;
assign B_txd_4[2]=1;
assign B_txd_4[1]=1;
assign B_txd_4[0]=1;

//JEIDA format.

assign jA_txd_1[6]=R_data_a[2];
assign jA_txd_1[5]=R_data_a[3];
assign jA_txd_1[4]=R_data_a[4];
assign jA_txd_1[3]=R_data_a[5];
assign jA_txd_1[2]=R_data_a[6];
assign jA_txd_1[1]=R_data_a[7];
assign jA_txd_1[0]=G_data_a[2];

assign jA_txd_2[6]=G_data_a[3];
assign jA_txd_2[5]=G_data_a[4];
assign jA_txd_2[4]=G_data_a[5];
assign jA_txd_2[3]=G_data_a[6];
assign jA_txd_2[2]=G_data_a[7];
assign jA_txd_2[1]=B_data_a[2];
assign jA_txd_2[0]=B_data_a[3];

assign jA_txd_3[6]=B_data_a[4];
assign jA_txd_3[5]=B_data_a[5];
assign jA_txd_3[4]=B_data_a[6];
assign jA_txd_3[3]=B_data_a[7];
assign jA_txd_3[2]=H_SYNC;
assign jA_txd_3[1]=V_SYNC;
assign jA_txd_3[0]=DE;

assign jA_txd_4[6]=R_data_a[0];
assign jA_txd_4[5]=R_data_a[1];
assign jA_txd_4[4]=G_data_a[0];
assign jA_txd_4[3]=G_data_a[1];
assign jA_txd_4[2]=B_data_a[0];
assign jA_txd_4[1]=B_data_a[1];
assign jA_txd_4[0]=1;

assign jB_txd_1[6]=R_data_b[2];
assign jB_txd_1[5]=R_data_b[3];
assign jB_txd_1[4]=R_data_b[4];
assign jB_txd_1[3]=R_data_b[5];
assign jB_txd_1[2]=R_data_b[6];
assign jB_txd_1[1]=R_data_b[7];
assign jB_txd_1[0]=G_data_b[2];

assign jB_txd_2[6]=G_data_b[3];
assign jB_txd_2[5]=G_data_b[4];
assign jB_txd_2[4]=G_data_b[5];
assign jB_txd_2[3]=G_data_b[6];
assign jB_txd_2[2]=G_data_b[7];
assign jB_txd_2[1]=B_data_b[2];
assign jB_txd_2[0]=B_data_b[3];

assign jB_txd_3[6]=B_data_b[4];
assign jB_txd_3[5]=B_data_b[5];
assign jB_txd_3[4]=B_data_b[6];
assign jB_txd_3[3]=B_data_b[7];
assign jB_txd_3[2]=H_SYNC;
assign jB_txd_3[1]=V_SYNC;
assign jB_txd_3[0]=DE;

assign jB_txd_4[6]=R_data_b[0];
assign jB_txd_4[5]=R_data_b[1];
assign jB_txd_4[4]=G_data_b[0];
assign jB_txd_4[3]=G_data_b[1];
assign jB_txd_4[2]=B_data_b[0];
assign jB_txd_4[1]=B_data_b[1];
assign jB_txd_4[0]=1;


//VESA format.

assign vA_txd_1[6]=R_data_a[0];
assign vA_txd_1[5]=R_data_a[1];
assign vA_txd_1[4]=R_data_a[2];
assign vA_txd_1[3]=R_data_a[3];
assign vA_txd_1[2]=R_data_a[4];
assign vA_txd_1[1]=R_data_a[5];
assign vA_txd_1[0]=G_data_a[0];

assign vA_txd_2[6]=G_data_a[1];
assign vA_txd_2[5]=G_data_a[2];
assign vA_txd_2[4]=G_data_a[3];
assign vA_txd_2[3]=G_data_a[4];
assign vA_txd_2[2]=G_data_a[5];
assign vA_txd_2[1]=B_data_a[0];
assign vA_txd_2[0]=B_data_a[1];

assign vA_txd_3[6]=B_data_a[2];
assign vA_txd_3[5]=B_data_a[3];
assign vA_txd_3[4]=B_data_a[4];
assign vA_txd_3[3]=B_data_a[5];
assign vA_txd_3[2]=H_SYNC;
assign vA_txd_3[1]=V_SYNC;
assign vA_txd_3[0]=DE;

assign vA_txd_4[6]=R_data_a[6];
assign vA_txd_4[5]=R_data_a[7];
assign vA_txd_4[4]=G_data_a[6];
assign vA_txd_4[3]=G_data_a[7];
assign vA_txd_4[2]=B_data_a[6];
assign vA_txd_4[1]=B_data_a[7];
assign vA_txd_4[0]=1;

assign vB_txd_1[6]=R_data_b[0];
assign vB_txd_1[5]=R_data_b[1];
assign vB_txd_1[4]=R_data_b[2];
assign vB_txd_1[3]=R_data_b[3];
assign vB_txd_1[2]=R_data_b[4];
assign vB_txd_1[1]=R_data_b[5];
assign vB_txd_1[0]=G_data_b[0];

assign vB_txd_2[6]=G_data_b[1];
assign vB_txd_2[5]=G_data_b[2];
assign vB_txd_2[4]=G_data_b[3];
assign vB_txd_2[3]=G_data_b[4];
assign vB_txd_2[2]=G_data_b[5];
assign vB_txd_2[1]=B_data_b[0];
assign vB_txd_2[0]=B_data_b[1];

assign vB_txd_3[6]=B_data_b[2];
assign vB_txd_3[5]=B_data_b[3];
assign vB_txd_3[4]=B_data_b[4];
assign vB_txd_3[3]=B_data_b[5];
assign vB_txd_3[2]=H_SYNC;
assign vB_txd_3[1]=V_SYNC;
assign vB_txd_3[0]=DE;

assign vB_txd_4[6]=R_data_b[6];
assign vB_txd_4[5]=R_data_b[7];
assign vB_txd_4[4]=G_data_b[6];
assign vB_txd_4[3]=G_data_b[7];
assign vB_txd_4[2]=B_data_b[6];
assign vB_txd_4[1]=B_data_b[7];
assign vB_txd_4[0]=1;



assign A_txd_0=(iSW0==1'b0)?jA_txd_1:vA_txd_1;
assign A_txd_1=(iSW0==1'b0)?jA_txd_2:vA_txd_2;
assign A_txd_2=(iSW0==1'b0)?jA_txd_3:vA_txd_3;
assign A_txd_3=(iSW0==1'b0)?jA_txd_4:vA_txd_4;
assign B_txd_0=(iSW0==1'b0)?jB_txd_1:vB_txd_1;
assign B_txd_1=(iSW0==1'b0)?jB_txd_2:vB_txd_2;
assign B_txd_2=(iSW0==1'b0)?jB_txd_3:vB_txd_3;
assign B_txd_3=(iSW0==1'b0)?jB_txd_4:vB_txd_4;



wire LDCLK,T_DE,T_HS,T_VS;
wire not_tx_mmcm_lckd;

wire tx_clk, pixel_clk;

assign EXIP_0_D7 = not_tx_mmcm_lckd;

top5x2_7to1_sdr_tx U0_0(
                       .Atxd0				(A_txd_0),
                       .Atxd1				(A_txd_1),
                       .Atxd2				(A_txd_2),
                       .Atxd3				(A_txd_3),
                       .Atxd4				(A_txd_4),
                       .Btxd0				(B_txd_0),
                       .Btxd1				(B_txd_1),
                       .Btxd2				(B_txd_2),
                       .Btxd3				(B_txd_3),
                       .Btxd4				(B_txd_4),
                       .freqgen_p			(LDCLK),

                       .reset				(~iRESET),
                       .clkout1_p			(A_clkout_p),
                       .clkout1_n			(A_clkout_n),
                       .dataoutA0_p		(A_rx0_p),
                       .dataoutA0_n		(A_rx0_n),
                       .dataoutA1_p		(A_rx1_p),
                       .dataoutA1_n		(A_rx1_n),
                       .dataoutA2_p		(A_rx2_p),
                       .dataoutA2_n		(A_rx2_n),
                       .dataoutA3_p		(A_rx3_p),
                       .dataoutA3_n		(A_rx3_n),
                       .dataoutA4_p		(A_rx4_p),
                       .dataoutA4_n		(A_rx4_n),
                       .clkout2_p			(B_clkout_p),
                       .clkout2_n			(B_clkout_n),
                       .dataoutB0_p		(B_rx0_p),
                       .dataoutB0_n		(B_rx0_n),
                       .dataoutB1_p		(B_rx1_p),
                       .dataoutB1_n		(B_rx1_n),
                       .dataoutB2_p		(B_rx2_p),
                       .dataoutB2_n		(B_rx2_n),
                       .dataoutB3_p		(B_rx3_p),
                       .dataoutB3_n		(B_rx3_n),
                       .dataoutB4_p		(B_rx4_p),
                       .dataoutB4_n		(B_rx4_n),
                       .txclk				(txclk),
                       .pixel_clk			(pixel_clk),
                       .not_tx_mmcm_lckd	(not_tx_mmcm_lckd)
                   ) ;

top5x2_7to1_sdr_tx_WO_clkgen U0_1(
                                 .Atxd0				(A_txd_0),
                                 .Atxd1				(A_txd_1),
                                 .Atxd2				(A_txd_2),
                                 .Atxd3				(A_txd_3),
                                 .Atxd4				(A_txd_4),
                                 .Btxd0				(B_txd_0),
                                 .Btxd1				(B_txd_1),
                                 .Btxd2				(B_txd_2),
                                 .Btxd3				(B_txd_3),
                                 .Btxd4				(B_txd_4),
                                 //.freqgen_p			(LDCLK),

                                 .reset				(~iRESET),
                                 .clkout1_p			(A2_clkout_p),
                                 .clkout1_n			(A2_clkout_n),
                                 .dataoutA0_p		(A2_rx0_p),
                                 .dataoutA0_n		(A2_rx0_n),
                                 .dataoutA1_p		(A2_rx1_p),
                                 .dataoutA1_n		(A2_rx1_n),
                                 .dataoutA2_p		(A2_rx2_p),
                                 .dataoutA2_n		(A2_rx2_n),
                                 .dataoutA3_p		(A2_rx3_p),
                                 .dataoutA3_n		(A2_rx3_n),
                                 .dataoutA4_p		(A2_rx4_p),
                                 .dataoutA4_n		(A2_rx4_n),
                                 .clkout2_p			(B2_clkout_p),
                                 .clkout2_n			(B2_clkout_n),
                                 .dataoutB0_p		(B2_rx0_p),
                                 .dataoutB0_n		(B2_rx0_n),
                                 .dataoutB1_p		(B2_rx1_p),
                                 .dataoutB1_n		(B2_rx1_n),
                                 .dataoutB2_p		(B2_rx2_p),
                                 .dataoutB2_n		(B2_rx2_n),
                                 .dataoutB3_p		(B2_rx3_p),
                                 .dataoutB3_n		(B2_rx3_n),
                                 .dataoutB4_p		(B2_rx4_p),
                                 .dataoutB4_n		(B2_rx4_n),
                                 .txclk				(txclk),
                                 .pixel_clk			(pixel_clk),
                                 .not_tx_mmcm_lckd	(not_tx_mmcm_lckd)


                             ) ;

assign oSTB = 1'b1;

wire DCLK;

two_port		U2( .iRESET(iRESET),.iclk(DVI_clk),
              .oclk(DCLK),.two_port_sel(~iSW2),.iSW3(iSW3),//iSW2=1port //iSW3=rising/falling
              .iRDATA_86(DVIrdata86),.iGDATA_86(DVIgdata86),.iBDATA_86(DVIbdata86),
              .iDE(DVI_DE),.iHS(DVI_HS),.iVS(DVI_VS),
              .R_data_a(R_data_a),
              .G_data_a(G_data_a),
              .B_data_a(B_data_a),
              .R_data_b(R_data_b),
              .G_data_b(G_data_b),
              .B_data_b(B_data_b),
              .oDE(DE),.oHS(H_SYNC),.oVS(V_SYNC));

BUFG			U3(.I(DCLK), .O(LDCLK));

wire clk_locked;
wire clk_i2c; // Clock 100MHz

assign EXIP_1_D8 = clk_locked;

clk_wiz_0 clk_inst
          (
              // Clock out ports
              .clk_out1(clk_i2c),
              // Status and control signals
              .reset(!iRESET),
              .locked(clk_locked),
              // Clock in ports
              .clk_in1(iOSC)
          );
// EXPB28	SDA
// EXPB29	SCL
// wire i2c_scl, i2c_sda;

// assign EXPB_Bit28 = i2c_sda;
// assign i2c_scl = EXPB_Bit29;

i2c_edid # (
             .HEX_FILE("D:/G7_Code_DVI2LVDS/rtl_code/C103HAN09.0.hex")
         ) i2c_edid_inst_0 (
             .clk(clk_i2c),
             .rst_n(iRESET),
             .scl(EXPB_Bit29),
             .sda(EXPB_Bit28)
         );

endmodule
