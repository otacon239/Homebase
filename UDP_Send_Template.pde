// This file contains all of the necessary setup components to send UDP frames to a remote display within Processing
// Note the `Code goes here` line - This is where all draws to the frame should be done
// Be sure to update the destination IP and port to match your setup

import hypermedia.net.*; // UDP library

int targetFramerate = 60;

static final String DEST_IP = "127.0.0.1";
static final int DEST_PORT = 8888; // Port on the receiving server
static final int SEND_PORT = 9999; // Port data ill be sent from
UDP udp; // Create UDP object for sending frames

void setup() {
  size(64,32); // Remote display size
  frameRate(targetFramerate);
  background(0);
  colorMode(HSB, 1.0, 1.0, 1.0, 1.0);
  
  noSmooth();
  
  udp = new UDP(this, SEND_PORT); // Initialize UDP
  udp.log(false); // Disable logging for performance
}

void draw() {
  background(0);
  
  // Code goes here
  
  udpSend();
}

void udpSend() {
    // Capture the frame as an image
    PImage frame = get();

    // Convert the image to a byte array
    byte[] frameBytes = new byte[frame.pixels.length * 4];
    for (int i = 0; i < frame.pixels.length; i++) {
      frameBytes[i * 4] = byte((frame.pixels[i] >> 16) & 0xFF); // Red
      frameBytes[i * 4 + 1] = byte((frame.pixels[i] >> 8) & 0xFF); // Green
      frameBytes[i * 4 + 2] = byte(frame.pixels[i] & 0xFF); // Blue
      frameBytes[i * 4 + 3] = byte((frame.pixels[i] >> 24) & 0xFF); // Alpha
    };

    // Send the byte array over UDP
    udp.send(frameBytes, DEST_IP, DEST_PORT);
}
