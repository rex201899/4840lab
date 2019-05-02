/*
 * Avalon memory-mapped peripheral that generates VGA
 *
 * Stephen A. Edwards
 * Columbia University
 */

module vga_ball(input logic        clk,
	        input logic 	   reset,
		input logic [7:0]  writedata,
		input logic 	   write,
		input 		   chipselect,
		input logic [2:0]  address,

		output logic [7:0] VGA_R, VGA_G, VGA_B,
		output logic 	   VGA_CLK, VGA_HS, VGA_VS,
		                   VGA_BLANK_n,
		output logic 	   VGA_SYNC_n);

   logic [10:0]	   hcount;
   logic [9:0]     vcount;

   logic [9:0]     hpos, hposnext, hmax;
   logic [8:0]     vpos, vposnext, vmax;

   logic [7:0] 	   background_r, background_g, background_b;
	
   vga_counters counters(.clk50(clk), .*);




   always_comb begin

	case (address)
	  3'h3 : begin
		   hposnext    = {hpos[9:8], writedata};
		   vposnext    = vpos;
		 end
	  3'h4 : begin
		   hposnext    = {writedata[1:0], hpos[7:0]};
		   vposnext    = {vpos[8:6], writedata[7:2]};
	 	 end
	  3'h5 : begin
		   hposnext    = hpos;
		   vposnext    = {writedata[2:0], vpos[5:0]};
		 end
	  default: begin
		   hposnext    = hpos;
		   vposnext    = vpos;
		 end
        endcase
	
        // 10 1000 0000  640	       1 1110 0000  480
	hmax 	 = ( hposnext[9] & (hposnext[8] | hposnext[7]) );
	vmax 	 = ( vposnext[8:5] == 4'b1111 );

	hposnext = (hmax) ? 10'd639 : hposnext;
	vposnext = (vmax) ? 9'd479  : vposnext;

   end

   always_ff @(posedge clk)
   begin
	hpos <= hpos;
	vpos <= vpos;
     if (reset) begin
	hpos <= 10'd56;
	vpos <=  9'd56;
	background_r <= 8'h0;
	background_g <= 8'h0;
	background_b <= 8'h80;
     end else if (chipselect && write)
       case (address)
	 3'h0 : background_r <= writedata;
	 3'h1 : background_g <= writedata;
	 3'h2 : background_b <= writedata;
	 default: begin
		hpos <= hposnext;
		vpos <= vposnext;
	   end
       endcase
   end

   always_comb begin
      {VGA_R, VGA_G, VGA_B} = {8'h0, 8'h0, 8'h0};
      if (VGA_BLANK_n )
	if ( ((hcount[10:1] - hpos)*(hcount[10:1] - hpos) + (vcount[8:0] - vpos)*(vcount[8:0] - vpos)) <= 256 )
	  {VGA_R, VGA_G, VGA_B} = {8'h80, 8'h00, 8'hff};
	else
	  {VGA_R, VGA_G, VGA_B} =
             {background_r, background_g, background_b};
   end
	       
endmodule

module vga_counters(
 input logic 	     clk50, reset,
 output logic [10:0] hcount,  // hcount[10:1] is pixel column
 output logic [9:0]  vcount,  // vcount[9:0] is pixel row
 output logic 	     VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_n, VGA_SYNC_n);

/*
 * 640 X 480 VGA timing for a 50 MHz clock: one pixel every other cycle
 * 
 * HCOUNT 1599 0             1279       1599 0
 *             _______________              ________
 * ___________|    Video      |____________|  Video
 * 
 * 
 * |SYNC| BP |<-- HACTIVE -->|FP|SYNC| BP |<-- HACTIVE
 *       _______________________      _____________
 * |____|       VGA_HS          |____|
 */
   // Parameters for hcount
   parameter HACTIVE      = 11'd 1280,
             HFRONT_PORCH = 11'd 32,
             HSYNC        = 11'd 192,
             HBACK_PORCH  = 11'd 96,   
             HTOTAL       = HACTIVE + HFRONT_PORCH + HSYNC +
                            HBACK_PORCH; // 1600
   
   // Parameters for vcount
   parameter VACTIVE      = 10'd 480,
             VFRONT_PORCH = 10'd 10,
             VSYNC        = 10'd 2,
             VBACK_PORCH  = 10'd 33,
             VTOTAL       = VACTIVE + VFRONT_PORCH + VSYNC +
                            VBACK_PORCH; // 525

   logic endOfLine;
   
   always_ff @(posedge clk50 or posedge reset)
     if (reset)          hcount <= 0;
     else if (endOfLine) hcount <= 0;
     else  	         hcount <= hcount + 11'd 1;

   assign endOfLine = hcount == HTOTAL - 1;
       
   logic endOfField;
   
   always_ff @(posedge clk50 or posedge reset)
     if (reset)          vcount <= 0;
     else if (endOfLine)
       if (endOfField)   vcount <= 0;
       else              vcount <= vcount + 10'd 1;

   assign endOfField = vcount == VTOTAL - 1;

   // Horizontal sync: from 0x520 to 0x5DF (0x57F)
   // 101 0010 0000 to 101 1101 1111
   assign VGA_HS = !( (hcount[10:8] == 3'b101) &
		      !(hcount[7:5] == 3'b111));
   assign VGA_VS = !( vcount[9:1] == (VACTIVE + VFRONT_PORCH) / 2);

   assign VGA_SYNC_n = 1'b0; // For putting sync on the green signal; unused
   
   // Horizontal active: 0 to 1279     Vertical active: 0 to 479
   // 101 0000 0000  1280	       01 1110 0000  480
   // 110 0011 1111  1599	       10 0000 1100  524
   assign VGA_BLANK_n = !( hcount[10] & (hcount[9] | hcount[8]) ) &
			!( vcount[9] | (vcount[8:5] == 4'b1111) );

   /* VGA_CLK is 25 MHz
    *             __    __    __
    * clk50    __|  |__|  |__|
    *        
    *             _____       __
    * hcount[0]__|     |_____|
    */
   assign VGA_CLK = hcount[0]; // 25 MHz clock: rising edge sensitive
   
endmodule
