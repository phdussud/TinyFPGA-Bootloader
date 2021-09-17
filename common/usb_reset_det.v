// detects USB port reset signal from host
module usb_reset_det (
  input clk,
  output reset,

  input usb_p_rx,
  input usb_n_rx
);
  // reset detection
  reg [9:0] reset_timer = 0;

  //double flip for async input
  reg [3:0] dpair_q = 0;

  always @(posedge clk) begin
      dpair_q[3:0] <= {dpair_q[1:0], usb_p_rx, usb_n_rx};
  end
  
  wire [1:0] dpair = dpair_q[3:2];

  wire timer_expired = &reset_timer;
 
  assign reset = timer_expired;
 
  
  always @(posedge clk) begin
    if (dpair[0] || dpair[1]) begin
      reset_timer <= 0;
    end else begin
      // SE0 detected from host
      // timer not expired yet, keep counting
      reset_timer <= reset_timer + {8'b0, ~timer_expired};
    end
  end
  
endmodule