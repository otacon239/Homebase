/*
TODO
- Create .conf file
- Subscriber counter
- Now playing ticker
- RSS Feed
*/

// Library imports
import java.text.SimpleDateFormat;
import java.util.Date;
import de.jnsdbr.openweathermap.*;
import ddf.minim.analysis.*;
import ddf.minim.*;

PVector origin = new PVector(0,0);
PImage bootlogo;
boolean boot = true;
float bootX;

Date now; // Variable for storing the current time
SimpleDateFormat timeStampFormat;
int targetFramerate = 60;

// Setup OpenWeatherMap
OpenWeatherMap owm;
// OWM API Key can be acquired here: https://openweathermap.org/api
final String API_KEY = "[API Key]"; // TODO: place this in .conf file
final String location = "[location]"; // More information here: https://openweathermap.org/current
int updateMinutes = 60; // Number of minutes in between weather updates - Minimum 5 minutes, Recommended 15-60 minutes

// Setup audio vizualizer variables
Minim minim;
AudioInput in;

static final int TS = 8; // Text size in pixels

ArrayList <Display> lines = new ArrayList<Display>(); // Setup array where each line is its own object

Notification notify = new Notification(".");
boolean notification = false;

void setup() {
    size(64, 32); // Size of display in pixels
    frameRate(targetFramerate);
    background(0);
    colorMode(HSB, 1.0, 1.0, 1.0, 1.0);

    PFont font = createFont("04b03-8.ttf", 8, false); // Must use "Create Font" option to use others - See: 
    textFont(font, TS);
    noSmooth(); // As this is pixel perfect text, we want to disable smoothing

    bootlogo = loadImage("bootlogo.png");
    bootX = width;
    origin.y = height;

    // Initialize audio input
    minim = new Minim(this);
    in = minim.getLineIn();

    // Create lines based on screen size and text size
    for (int l = 0; l < height*TS; l++) {
        lines.add(new Display(l));
        lines.get(l).scrollSpeed = 2;
    }

    now = new Date();
    timeStampFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
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
    lines.get(3).dbFloor = 75; // Set db floor
    lines.get(3).hueCycles = .5;
}

void draw() {
    now = new Date(); // Update time every frame

    if (frameCount%(targetFramerate*60*max(5, updateMinutes)) == 0) // Update weather only once every X minutes
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
        translate(origin.x, origin.y);
        if (origin.y > 0 && !notification) {
            origin.y--;
        }
        if (notification) {
            notify.render();
        }
        for (int i = 0; i < lines.size(); i++) // Render lines
            lines.get(i).render();
        popMatrix();
    }
}

void updateWeather() { // Pull new weather information (only run this rarely as this will pull from the API key)
    println(timeStampFormat.format(now) + " - Updating Weather...");
    owm = new OpenWeatherMap(this, API_KEY, location);
}

void keyPressed() {
    if (keyCode == ESC || key == 'q' || key == 'Q')
        exit();
    if (key == 's' || key == 'S') // Press S to re-initialize audio input in case the source changes
        in = minim.getLineIn();
    if (key == 'b' || key == 'B') {
        boot = true;
        origin.y = height;
        bootX = width;
    }
    if (key == 'n' || key == 'N') // Test notification trigger
        if (!notification) {
            notify = new Notification("Bomb diggity");
            notify.tWidth = int(textWidth(notify.text));
        }
}