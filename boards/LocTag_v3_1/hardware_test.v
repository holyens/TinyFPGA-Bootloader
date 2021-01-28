//
// Notes:
// 1. USB is disabled as unused pin_usb_pu are automatically blocked and the
//    pull-up termination is disabled ;
//
module hardware_test (
  // 16MHz clock input
  input  pin_clk,
  // detector
  output pin_lt5534_en,
  output pin_adc_cs,
  output pin_adc_clk,
  input  pin_adc_so,
  input  pin_trig,
  // reflector
  output pin_ctrl_1,
  // user interface io
  output pin_led,

  input  pin_key_1,
  input  pin_key_2,
  input  pin_key_3,
  input  pin_key_4,

  output pin_mio_1,
  output pin_mio_2,
  output pin_mio_3,
  output pin_mio_4,
  output pin_mio_7,
  output pin_mio_8,
  output pin_mio_9,
  output pin_mio_10,
  );

  /////////////////////////////////////////
  // generate 50 mhz clock
  /////////////////////////////////////////
  wire clk_50mhz;
  wire lock;
  wire reset = !lock;
  SB_PLL40_CORE #(
    .DIVR(4'b0000),
    .DIVF(7'b011_0001),
    .DIVQ(3'b100),
    .FILTER_RANGE(3'b001),
    .FEEDBACK_PATH("SIMPLE"),
    .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
    .FDA_FEEDBACK(4'b0000),
    .DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
    .FDA_RELATIVE(4'b0000),
    .SHIFTREG_DIV_MODE(2'b00),
    .PLLOUT_SELECT("GENCLK"),
    .ENABLE_ICEGATE(1'b0)
  ) usb_pll_inst (
    .REFERENCECLK(pin_clk),
    .PLLOUTCORE(clk_50mhz),
    .PLLOUTGLOBAL(),
    .EXTFEEDBACK(),
    .DYNAMICDELAY(),
    .RESETB(1'b1),
    .BYPASS(1'b0),
    .LATCHINPUTVALUE(),
    .LOCK(lock),
    .SDI(),
    .SDO(),
    .SCLK()
  );

  wire [3:0] key = {~pin_key_1, ~pin_key_2, ~pin_key_3, ~pin_key_4};

  assign pin_ctrl_1 = (key[0] & clk_50mhz) | key[1];
  assign pin_lt5534_en = key[2];
  assign pin_mio_7 = pin_trig ^ key[3];
  assign pin_mio_8 = pin_adc_cs;
  assign pin_mio_9 = pin_adc_so; 
  assign pin_mio_10 = pin_ctrl_1; 

  assign {pin_mio_1, pin_mio_2, pin_mio_3, pin_mio_4} = key;

  assign pin_adc_clk = pin_clk;
  // keep track of time and location in blink_pattern
  reg [22:0] t_counter;
  // increment the blink_counter every clock
  always @(posedge pin_clk) begin
      t_counter <= t_counter + 1;

  end
  
  // light up the LED according to the pattern
  assign pin_led = t_counter[21];
  assign pin_adc_cs = t_counter[5];

endmodule
