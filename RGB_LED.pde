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
import processing.sound.*;
import de.jnsdbr.openweathermap.*;

// Setup OpenWeatherMap
OpenWeatherMap owm;
// OWM API Key can be acquired here: https://openweathermap.org/api
final String API_KEY = "[API Key]"; // TODO: place this in .conf file
final String location = "[location]"; // More information here: https://openweathermap.org/current

// Setup amplitude monitor variables
Amplitude amp;
AudioIn in;
float ampMod = 2; // Multiplier for base amplitude - Adjust this to scale the input


static final int TS = 8; // Text size

ArrayList <Display> lines = new ArrayList<Display>(); // Setup array where each line is its own object

void setup() {
    size(64, 32); // Size of Adafruit display in pixels
    frameRate(60);
    background(0);
    colorMode(HSB, 360, 1.0, 1.0);

    PFont font = loadFont("04b03-8.vlw"); // Must use "Create Font" option to use others
    textFont(font, TS);
    noSmooth(); // As this is pixel perfect text, we want to disable smoothing

    // Create initializers for audio vizualizers
    amp = new Amplitude(this);
    in = new AudioIn(this, 0);
    in.start();
    amp.input(in);

    // Create lines based on screen size and text size
    for (int l = 0; l < height*TS; l++) {
        lines.add(new Display());
        lines.get(l).line = l;
        lines.get(l).scrollSpeed = 2;
    }

    updateWeather();

    // TODO: Move the following lines to external config file
    lines.get(0).setText("omni_chat");
    lines.get(0).rainbow = true;

    lines.get(1).lineMode = 2;
    lines.get(1).scrollMode = 2;
    lines.get(1).scrollDelayInit = 0;
    lines.get(1).tColor = color(0, 0, 1);
    
    lines.get(2).lineMode = 3;
    lines.get(2).tColor = color(180);
    
    lines.get(3).lineMode = 1;
    lines.get(3).vuSmooth = 2;
    lines.get(3).hueCycles = .5;
}

void draw() {
    // TODO: Find a way to run updateWeather only once an hour
    background(0);

    for (int i = 0; i < lines.size(); i++)
        lines.get(i).render();
}

void updateWeather() { // Pull new weather information (only run this rarely as this will pull from the API key)
        owm = new OpenWeatherMap(this, API_KEY, location);
}

void keyPressed() {
    if (keyCode == ESC || key == 'q') { // Exit app
        exit();
    }
}