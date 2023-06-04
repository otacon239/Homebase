/*
TODO
- Implement UDP Notification receiver
- Create .conf file
- Subscriber counter
- Now playing ticker
- Custom font
*/

// Native Library imports
import java.text.SimpleDateFormat;
import java.util.Date;

// These can be added by going to Sketch >> Import Library >> Manage Library
// Minim
import ddf.minim.analysis.*;
import ddf.minim.*;
// UDP
import hypermedia.net.*;

// Setup OpenWeatherMap - You will need to download the most recent .zip (not source code) from here: https://github.com/jnsdbr/OpenWeatherMap/releases
import de.jnsdbr.openweathermap.*; // Go to Sketch >> Add File and choose the .jar found in the library folder to add this to the project - Other methods falied for me
final String API_KEY = "API_KEY"; // OWM API Key can be acquired here: https://openweathermap.org/api
final String location = "ZIP,COUNTRY_CODE"; // More information here: https://openweathermap.org/current#zip
int updateInterval = 15; // Number of minutes in between weather updates - Minimum 5 minutes, Recommended 10-20
OpenWeatherMap owm; // Initialize object

PVector bootlogo_origin = new PVector(0,0);
PImage bootlogo;
boolean boot = true; // This determines if the bootlogo should play - Reverts to false at the end of the animation
float bootX; // Keep track of the logo offset

Date now; // Variable for storing the current time
SimpleDateFormat clockFormat;

int targetFramerate = 60;

// Setup audio vizualizer variables
Minim minim;
AudioInput in;

static final int TS = 8; // Text height in pixels

static final String DEST_IP = "127.0.0.1";
static final int DEST_PORT = 9999; // Port on the receiving server
static final int SEND_PORT = 8888; // Port data ill be sent from
UDP udp; // Create UDP object for sending frames

ArrayList <Display> lines = new ArrayList<Display>(); // Setup array where each line is its own object

Notification notify = new Notification("."); // Initialize notification system
boolean notification = false; // Similar to `boot`

void setup() {
    size(64, 32); // Size of display in pixels
    frameRate(targetFramerate);
    background(0);
    colorMode(HSB, 1.0, 1.0, 1.0, 1.0); // Floating point is less efficient, but more straightforward to program for

    PFont font = createFont("04b03-8.ttf", 8, false); // Place font file in ../data/ directory. Recommended font found here: https://www.dafont.com/04b-03.font
    textFont(font, TS);
    noSmooth(); // As this is pixel perfect text, we want to disable smoothing

    bootlogo = loadImage("bootlogo.png"); // TODO: Create doc on image process
    bootX = width; // Push image to far-right of image
    bootlogo_origin.y = height; // Place image origin at the top of the screen

    // Initialize audio input
    minim = new Minim(this);
    in = minim.getLineIn(); // Defaults to primary audio source - More info here: https://code.compartmental.net/minim/minim_method_getlinein.html

    // Create lines based on screen size and text size
    for (int l = 0; l < height*TS; l++) {
        lines.add(new Display(l));
        lines.get(l).scrollSpeed = 2;
    }

    now = new Date();
    clockFormat = new SimpleDateFormat("MM|dd HH:mm:ss"); // More info here: https://docs.oracle.com/javase/8/docs/api/java/text/SimpleDateFormat.html
    updateWeather();

    // TODO: Move the following lines to external config file
    lines.get(0).setText("Omnigon");
    lines.get(0).rainbow = true;

    lines.get(1).lineMode = 2; // Clock
    lines.get(1).scrollMode = 2; // Force scrolling
    lines.get(1).scrollDelayInit = 0; // Forces constant scroll
    lines.get(1).tColor = color(1); // White

    lines.get(2).lineMode = 3; // Weather
    lines.get(2).tColor = color(.5); // Grey

    lines.get(3).lineMode = 1; // Visualizer
    lines.get(3).vMode = 1; // Spectrum analyzer
    lines.get(3).dbFloor = 75; // Set db floor - Lower is less sensitive - 25-100 recommended
    lines.get(3).hueCycles = .5;

    udp = new UDP(this, SEND_PORT); // Initialize UDP
    udp.log(false); // Disable logging for performance
}

void draw() {
    now = new Date(); // Update time every frame

    if (frameCount%(targetFramerate*60*max(5, updateInterval)) == 0) // Update weather only once every X minutes
        updateWeather();

    background(0); // Blank frame

    if (boot) {
        if (bootX > -bootlogo.width) {
            image(bootlogo, bootX, 0);
            bootX--;
        } else {
            boot = false;
        }
    } else {
        pushMatrix();
        translate(bootlogo_origin.x, bootlogo_origin.y);
        if (bootlogo_origin.y > 0 && !notification) {
            bootlogo_origin.y--;
        }
        if (notification) {
            notify.render();
        }
        for (int i = 0; i < lines.size(); i++) // Render lines
            lines.get(i).render();
        popMatrix();
    }

    udp_Send();
}

void updateWeather() { // Pull new weather information (only run this rarely as this will pull from the API key)
    println(clockFormat.format(now) + " - Updating Weather...");
    owm = new OpenWeatherMap(this, API_KEY, location);
}

void keyPressed() {
    if (keyCode == ESC || key == 'q' || key == 'Q')
        exit();
    if (key == 's' || key == 'S') // Press S to re-initialize audio input in case the source changes
        in = minim.getLineIn();
    if (key == 'b' || key == 'B') { // Re-run boot anim
        boot = true;
        bootlogo_origin.y = height;
        bootX = width;
    }
    if (key == 'n' || key == 'N') // Test notification trigger - First test
        if (!notification) {
            notify = new Notification("Bomb diggity");
            notify.tWidth = int(textWidth(notify.text));
        }
}

void udp_Send() {
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
