/*
 * Userspace program that communicates with the vga_ball device driver
 * through ioctls
 *
 * Stephen A. Edwards
 * Columbia University
 */

#include <stdio.h>
#include "vga_ball.h"
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>

int vga_ball_fd;

uint hMax = 640-17;
uint vMax = 480-17;

// go from position to 3 byte values
 //horizontal uses 10 bits (0-639), vertical uses 9 bits (0-479)
static vga_ball_color_t position_to_chars(uint horizontal, uint vertical)
{
  printf("\n");
  //red = pos3, green = pos4, blue = pos5
  vga_ball_color_t pos;
  pos.red   = (unsigned char) (horizontal & 255);
  pos.green = (unsigned char) ((vertical << 2) | ((horizontal >> 8) & 3));
  pos.blue  = (unsigned char) ((vertical >> 6) & 7);
  printf("%d %d %d \n",pos.blue,pos.green,pos.red);
  /*
  printf("h: %d: ",horizontal);
  for (int i = 0; i < 12; i++) {
    printf("%d",((horizontal = (horizontal >> i)) & 1));
  }

  printf("\nv: %d: ",vertical);
  for (int i = 0; i < 12; i++) {
    printf("%d",((vertical = (vertical >> i)) & 1));
  }
  printf("\n");
  */
  return pos;
}


/* Read and print the background color */
// void print_position() {
//   vga_ball_arg_t vla;
  
//   if (ioctl(vga_ball_fd, VGA_BALL_READ_BACKGROUND, &vla)) {
//       perror("ioctl(VGA_BALL_READ_BACKGROUND) failed");
//       return;
//   }
//   printf("%02x %02x %02x\n",
//    vla.background.red, vla.background.green, vla.background.blue);
// }

  static const vga_ball_color_t colors[] = {
    { 0xff, 0x00, 0x00 }, /* Red */
    { 0x00, 0xff, 0x00 }, /* Green */
    { 0x00, 0x00, 0xff }, /* Blue */
    { 0xff, 0xff, 0x00 }, /* Yellow */
    { 0x00, 0xff, 0xff }, /* Cyan */
    { 0xff, 0x00, 0xff }, /* Magenta */
    { 0x80, 0x80, 0x80 }, /* Gray */
    { 0x00, 0x00, 0x00 }, /* Black */
    { 0xff, 0xff, 0xff }  /* White */
  };

  # define COLORS 9

/* Set the background color */
void set_position(uint horizontal, uint vertical)//const vga_ball_color_t *c)
{
  vga_ball_arg_t vla;

  vla.background = position_to_chars(horizontal, vertical) ;//*c;
  if (ioctl(vga_ball_fd, VGA_BALL_WRITE_POSITION, &vla)) {
      perror("ioctl(VGA_BALL_WRITE_POSITION) failed");
      return;
  }
}

/* Set the background color */
void print_position()//const vga_ball_color_t *c)
{
  vga_ball_arg_t vla;
  
  if (ioctl(vga_ball_fd, VGA_BALL_READ_POSITION, &vla)) {
      perror("ioctl(VGA_BALL_READ_POSITION) failed");
      return;
  }
  printf("%d %d %d\n",
   vla.background.blue, vla.background.green, vla.background.red);
}


/* Read and print the background color */
void print_background_color() {
  vga_ball_arg_t vla;
  
  if (ioctl(vga_ball_fd, VGA_BALL_READ_BACKGROUND, &vla)) {
      perror("ioctl(VGA_BALL_READ_BACKGROUND) failed");
      return;
  }
  printf("%02x %02x %02x\n",
	 vla.background.red, vla.background.green, vla.background.blue);
}

/* Set the background color */
void set_background_color(const vga_ball_color_t *c)
{
  vga_ball_arg_t vla;
  vla.background = *c;
  if (ioctl(vga_ball_fd, VGA_BALL_WRITE_BACKGROUND, &vla)) {
      perror("ioctl(VGA_BALL_SET_BACKGROUND) failed");
      return;
  }
}

void bounce(uint start_h, uint start_v)
{
  int i = 0;
  int up = 1;
  int right = 1;
  for (;;) {
    set_position(start_h, start_v);
    usleep(8000);
    if (up){
      start_v += 2;
      if (start_v >= vMax-1) {
        i++;
        set_background_color(&colors[i % COLORS ]);
        up = 0;
      }
    }
    else {
      start_v -= 2;
      if (start_v <= 17) {
        i++;
        set_background_color(&colors[i % COLORS ]);
        up = 1;
      }
    }

    if (right) {
      start_h += 1;
      if (start_h >= hMax) {
        i++;
        set_background_color(&colors[i % COLORS ]);
        right = 0;
      }
    }
    else {
      start_h -= 1;
      if (start_h <= 17) {
        i++;
        set_background_color(&colors[i % COLORS ]);
        right = 1;
      }
    }

  }

}

int main()
{
  vga_ball_arg_t vla;
  int i;
  static const char filename[] = "/dev/vga_ball";

  // static const vga_ball_color_t colors[] = {
  //   { 0xff, 0x00, 0x00 }, /* Red */
  //   { 0x00, 0xff, 0x00 }, /* Green */
  //   { 0x00, 0x00, 0xff }, /* Blue */
  //   { 0xff, 0xff, 0x00 }, /* Yellow */
  //   { 0x00, 0xff, 0xff }, /* Cyan */
  //   { 0xff, 0x00, 0xff }, /* Magenta */
  //   { 0x80, 0x80, 0x80 }, /* Gray */
  //   { 0x00, 0x00, 0x00 }, /* Black */
  //   { 0xff, 0xff, 0xff }  /* White */
  // };

//# define COLORS 9

  printf("VGA ball Userspace program started\n");

  if ( (vga_ball_fd = open(filename, O_RDWR)) == -1) {
    fprintf(stderr, "could not open %s\n", filename);
    return -1;
  }

  printf("initial state: ");
  print_background_color();

  //set_background_color(&colors[3]);
  bounce(220,400);

  // for (i = 0 ; i < 24 ; i++) {
  //   printf("position set: %d, %d",  i*26,240);
  //   set_position(i*26,240);
  //   print_position();
  //   set_background_color(&colors[i % COLORS ]);
  //   print_background_color();
  //   usleep(400000);
  // }
  
  printf("VGA BALL Userspace program terminating\n");
  return 0;
}
