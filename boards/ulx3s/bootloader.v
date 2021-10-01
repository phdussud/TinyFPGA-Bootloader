// no timescale needed

module ulx3s_top(
  input  wire clk_25mhz, // -- main clock input from 25MHz clock source must be lowercase

  inout  usb_fpga_dp,
  inout  usb_fpga_dn,
  
  output usb_fpga_pu_dp,
  inout user_programn,

  output [7:0] led,

  input  flash_miso,
  output flash_mosi,
  output flash_csn,
  output flash_wpn,
  output flash_holdn,
 
  input [6:0] btn
);

    wire clk_60mhz;
	wire noop;
    wire clk_ready;
	clk_60 usb_clk(
	.CLKI(clk_25mhz),
	.CLKOP(clk_60mhz),
	.CLKOS(noop),
	.LOCK(clk_ready)
	);
	

  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////
  //////// instantiate tinyfpga bootloader
  ////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////

  reg [15:0] reset_counter = 0; // counter for debouce and prolong reset
  wire reset;
  assign reset = ~reset_counter[15];
  wire usb_p_tx;
  wire usb_n_tx;
  wire usb_p_rx;
  wire usb_n_rx;
  wire usb_tx_en;
  wire pin_led;
  wire [7:0] debug_led;
  wire boot;
  wire S_flash_clk;
  wire S_flash_csn;
  wire reset_usb;
 
  
    tinyfpga_bootloader #(
    .USB_CLOCK_MULT(5) //4->48MHz, 5->60MHz
    ) tinyfpga_bootloader_inst (
    .clk_usb(clk_60mhz),
    .clk(clk_25mhz),
    .reset(reset_usb | reset),
    .usb_p_tx(usb_p_tx),
    .usb_n_tx(usb_n_tx),
    .usb_p_rx(usb_p_rx),
    .usb_n_rx(usb_n_rx),
    .usb_tx_en(usb_tx_en),
    .led(pin_led),
    .spi_miso(flash_miso),
    .spi_mosi(flash_mosi),
    .spi_sck(S_flash_clk),
    .spi_cs(S_flash_csn),
    .boot(boot)
    );

    usb_reset_det usb_reset_det_inst(
    .clk(clk_60mhz),
    .reset(reset_usb),
    .usb_p_rx(usb_p_rx),
    .usb_n_rx(usb_n_rx)
    );
	

  assign usb_fpga_dp = reset ? 1'b0 : (usb_tx_en ? usb_p_tx : 1'bz);
  assign usb_fpga_dn = reset ? 1'b0 : (usb_tx_en ? usb_n_tx : 1'bz);
  assign usb_p_rx = usb_tx_en ? 1'b1 : usb_fpga_dp;
  assign usb_n_rx = usb_tx_en ? 1'b0 : usb_fpga_dn;

  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////
  //////// Vendor-specific clock output to SPI config flash
  ////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  USRMCLK usrmclk_inst (
    .USRMCLKI(S_flash_clk),
    .USRMCLKTS(S_flash_csn)
  ) /* synthesis syn_noprune=1 */;
  assign flash_csn = S_flash_csn;

  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////
  //////// Debonuce and prolong RESET
  ////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  always @(posedge clk_60mhz)
  begin
    if (btn[1])
      reset_counter <= 0;
    else
        reset_counter <= reset_counter + (reset_counter[15] ? 0 : 1);
  end
  

  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////
  //////// ULX3S board buttons and LEDs
  ////////
  ////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  assign wifi_gpio0 = btn[0];
  assign led[0] = pin_led;
  assign led[1] = ~pin_led;
  assign led[2] = ~reset_counter[15];
  assign led[3] = 1;
  assign led[5] = 0;
  assign led[7] = boot;
  // assign led[3:0] = {flash_miso, flash_mosi, S_flash_clk, S_flash_csn}; 
  
  // PULLUP 1.5k D+
  assign usb_fpga_pu_dp = 1;

  // set 1 to holdn wpn for use as single bit mode spi
  assign flash_holdn = 1;
  assign flash_wpn = 1;

  // delay for BTN0 is required
  reg [3:0] R_progn = 0;
  always @(posedge clk_25mhz)
      if(btn[0])
        R_progn <= 0;
      else
        R_progn <= R_progn + 1;

  // EXIT from BOOTLOADER
  assign user_programn = ~boot & ~R_progn[3];


endmodule


module clk_60 (CLKI, CLKOP, CLKOS, LOCK)/* synthesis NGD_DRC_MASK=1 */;
    input wire CLKI;
    output wire CLKOP;
    output wire CLKOS;
    output wire LOCK;

    wire REFCLK;
    wire CLKOP_t;
    wire CLKOS_t;
    wire scuba_vhi;
    wire scuba_vlo;

    VHI scuba_vhi_inst (.Z(scuba_vhi));

    VLO scuba_vlo_inst (.Z(scuba_vlo));

    defparam PLLInst_0.PLLRST_ENA = "DISABLED" ;
    defparam PLLInst_0.INTFB_WAKE = "DISABLED" ;
    defparam PLLInst_0.STDBY_ENABLE = "DISABLED" ;
    defparam PLLInst_0.DPHASE_SOURCE = "DISABLED" ;
    defparam PLLInst_0.CLKOS3_FPHASE = 0 ;
    defparam PLLInst_0.CLKOS3_CPHASE = 0 ;
    defparam PLLInst_0.CLKOS2_FPHASE = 0 ;
    defparam PLLInst_0.CLKOS2_CPHASE = 0 ;
    defparam PLLInst_0.CLKOS_FPHASE = 0 ;
    defparam PLLInst_0.CLKOS_CPHASE = 3 ;
    defparam PLLInst_0.CLKOP_FPHASE = 0 ;
    defparam PLLInst_0.CLKOP_CPHASE = 9 ;
    defparam PLLInst_0.PLL_LOCK_MODE = 2 ;
    defparam PLLInst_0.CLKOS_TRIM_DELAY = 0 ;
    defparam PLLInst_0.CLKOS_TRIM_POL = "FALLING" ;
    defparam PLLInst_0.CLKOP_TRIM_DELAY = 0 ;
    defparam PLLInst_0.CLKOP_TRIM_POL = "FALLING" ;
    defparam PLLInst_0.OUTDIVIDER_MUXD = "DIVD" ;
    defparam PLLInst_0.CLKOS3_ENABLE = "DISABLED" ;
    defparam PLLInst_0.OUTDIVIDER_MUXC = "DIVC" ;
    defparam PLLInst_0.CLKOS2_ENABLE = "DISABLED" ;
    defparam PLLInst_0.OUTDIVIDER_MUXB = "DIVB" ;
    defparam PLLInst_0.CLKOS_ENABLE = "ENABLED" ;
    defparam PLLInst_0.OUTDIVIDER_MUXA = "DIVA" ;
    defparam PLLInst_0.CLKOP_ENABLE = "ENABLED" ;
    defparam PLLInst_0.CLKOS3_DIV = 1 ;
    defparam PLLInst_0.CLKOS2_DIV = 1 ;
    defparam PLLInst_0.CLKOS_DIV = 4 ;
    defparam PLLInst_0.CLKOP_DIV = 10 ;
    defparam PLLInst_0.CLKFB_DIV = 6 ;
    defparam PLLInst_0.CLKI_DIV = 1 ;
    defparam PLLInst_0.FEEDBK_PATH = "CLKOS" ;
    EHXPLLL PLLInst_0 (.CLKI(CLKI), .CLKFB(CLKOS_t), .PHASESEL1(scuba_vlo), 
        .PHASESEL0(scuba_vlo), .PHASEDIR(scuba_vlo), .PHASESTEP(scuba_vlo), 
        .PHASELOADREG(scuba_vlo), .STDBY(scuba_vlo), .PLLWAKESYNC(scuba_vlo), 
        .RST(scuba_vlo), .ENCLKOP(scuba_vlo), .ENCLKOS(scuba_vlo), .ENCLKOS2(scuba_vlo), 
        .ENCLKOS3(scuba_vlo), .CLKOP(CLKOP_t), .CLKOS(CLKOS_t), .CLKOS2(), 
        .CLKOS3(), .LOCK(LOCK), .INTLOCK(), .REFCLK(REFCLK), .CLKINTFB())
             /* synthesis FREQUENCY_PIN_CLKOS="150.000000" */
             /* synthesis FREQUENCY_PIN_CLKOP="60.000000" */
             /* synthesis FREQUENCY_PIN_CLKI="25.000000" */
             /* synthesis ICP_CURRENT="5" */
             /* synthesis LPF_RESISTOR="16" */;

    assign CLKOS = CLKOS_t;
    assign CLKOP = CLKOP_t;

endmodule