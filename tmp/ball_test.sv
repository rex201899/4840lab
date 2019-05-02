// void line(unit16 x0, unit16 y0, unit16 x1, unit16 y1)
// initiate 
signal ball_y_motion: STD_LOGIC_VECTOR(9 downto 0):= "0000000100";
signal ball_x_motion: STD_LOGIC_VECTOR(9 downto 0):= "0000000100";

void display(unit16 x_initial, unit16 y_initial)
{
	// sint16 dx, dy;	
	// int right, down;

	// dx = x1 - x0; right = dx > 0; 	if(!right) dx = -dx;
	// dy = y1 - y0; up = dy > 0;  	if(!down) dy = -dy; // right and down are direction



	unit16 ball_x, ball_y;
	constant size = 8;

	for(;;) {
		plot(ball_x,ball_y); //input is the middle x,y of coordinate
		if ball_x + size >= 640 then
			ball_x_motion <= "11111111110"; //-- -2 pixels
		else if ball_y <= size then
			ball_x_motion <= "00000000010"; //-- +2 pixels
		end if;
		ball_x = ball_x + ball_x_motion

		if ball_y + size >= 480 then
			ball_y_motion <= "11111111100"; //-- -4 pixels
		else if ball_y <= size then
			ball_y_motion <= "00000000100"; //-- +4 pixels
		end if;
		ball_y <= ball_y + ball_y_motion;
		}
}
