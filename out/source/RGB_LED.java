import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.text.SimpleDateFormat; 
import java.util.Date; 
import de.jnsdbr.openweathermap.*; 
import ddf.minim.analysis.*; 
import ddf.minim.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class RGB_LED extends PApplet {

/*
TODO
- Create .conf file
- Subscriber counter
- Now playing ticker
- RSS Feed
*/

// Library imports






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
final String API_KEY = "389d6c663dc37361a7aee8f600063c67"; // TODO: place this in .conf file
final String location = "85257, us"; // More information here: https://openweathermap.org/current
int updateMinutes = 60; // Number of minutes in between weather updates - Minimum 5 minutes, Recommended 15-60 minutes

// Setup audio vizualizer variables
Minim minim;
AudioInput in;

static final int TS = 8; // Text size in pixels

ArrayList <Display> lines = new ArrayList<Display>(); // Setup array where each line is its own object

Notification notify = new Notification(".");
boolean notification = false;

public void setup() {
     // Size of display in pixels
    frameRate(targetFramerate);
    background(0);
    colorMode(HSB, 1.0f, 1.0f, 1.0f, 1.0f);

    PFont font = createFont("04b03-8.ttf", 8, false); // Must use "Create Font" option to use others - See: 
    textFont(font, TS);
     // As this is pixel perfect text, we want to disable smoothing

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
    lines.get(2).tColor = color(.5f); // Grey
    
    lines.get(3).lineMode = 1; // Visualizer
    lines.get(3).vMode = 1; // Spectrum analyzer
    lines.get(3).dbFloor = 75; // Set db floor
    lines.get(3).hueCycles = .5f;
}

public void draw() {
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

public void updateWeather() { // Pull new weather information (only run this rarely as this will pull from the API key)
    println(timeStampFormat.format(now) + " - Updating Weather...");
    owm = new OpenWeatherMap(this, API_KEY, location);
}

public void keyPressed() {
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
            notify = new Notification("This is a test");
            notify.tWidth = PApplet.parseInt(textWidth(notify.text));
        }
}
class Display {
    int lineMode;
    /*
    Mode switch:
    0 (default) - Plain text
    1 - Audio Visualizer - See vMode for all vizualizers
    2 - Clock
    3 - Weather
    */

    String text; // The text to be displayed
    int line; // What line for the text to be displayed
    boolean forward; // Direction of text
    float scrollSpeed; // Speed of text in pixels/frame
    int tColor; // Text Color
    boolean rainbow; // Enable/disable rainbow text
    float rainbowSpeed; // Speed of hue cycle on rainbow effect

    SimpleDateFormat dateFormat; // See https://docs.oracle.com/javase/7/docs/api/java/text/SimpleDateFormat.html for more info

    int vMode; // Selector for which visualizer you want to use:
    /*
    0 (default) - Basic VU meter
    1 - FFT (spectrum analyzer)
    */
    float ampMult; // Amplitude multiplier
    float hueOffset; // Offset of the base hue value
    float hueCycles; // Number of full hue rotations on the screen
    float hueSpeed; // Speed the hue rotation moves in full cycles/second

    FFT fft; // DO NOT CHANGE - This is what creates the frequency bands
    WindowFunction fftWindow; // (advanced) Specify a preferred FFT window - See http://code.compartmental.net/minim/windowfunction_class_windowfunction.html
    boolean capEnabled; // Show "cap" at the top of each band
    int capColor; // Color of the cap
    float dbFloor; // Scale the dB floor - Higher values = more sensitive to sound (typical range of 25 to 100 depending on use case)
    
    int scrollMode; // 0 = Auto (based on string width), 1 = Off, 2 = On, 3 = Once
    int scrollPos; // X position of text that is too wide for display
    int scrollDelay; // How long the text stops once it's reached the left edge
    int scrollDelayInit; // Initial scroll delay setting - This is typically the one you want to change when changing the option

    int c; // Number of characters - c = characters
    int sl; // Length of text in pixels - sl = string length
    int y; // Y position in pixels
    
    Display(int l) { // Initialize all variables
        lineMode = 0;

        text = "";
        line = l;
        forward = true;
        tColor = color(1);
        rainbow = false;
        rainbowSpeed = .1f;

        dateFormat = new SimpleDateFormat("E MMM dd HH:mm:ss");

        vMode = 0;
        ampMult = 1;
        hueCycles = 1;
        hueSpeed = .1f;

        fft = new FFT(in.bufferSize(), in.sampleRate());
        fftWindow = FFT.HAMMING;
        fft.logAverages(width, 9); // Adjust scale to be logarithmic (number of bands, number of octaves)
                                   // See http://code.compartmental.net/minim/fft_method_logaverages.html

        capEnabled = true;
        capColor = color(1);
        dbFloor = 35;

        scrollSpeed = 1;
        scrollMode = 0;
        scrollPos = 0;
        scrollDelay = 50;
        scrollDelayInit = scrollDelay;
        
        c = text.length();
        sl = PApplet.parseInt(textWidth(text));
        y = (line*TS)+TS - 2;
    }
    
    public void render() {
        switch(lineMode) {
            case 1: // Audio Visualizer
                switch(vMode) {
                    case 1: // FFT Spectrum Analyzer - thanks to https://forum.processing.org/two/discussion/19936/how-to-get-an-octave-based-frequency-spectrum-from-the-fft-in-minim
                        fft.forward(in.mix);
  
                        for (int i = 0; i < fft.avgSize(); i++) {
                            float amplitude = fft.getAvg(i);
                            
                            float bandDB = 8 * log(2 * amplitude / fft.timeSize());
                            
                            float bandHeight = min(map(bandDB, 0, -dbFloor, 0, TS), TS);
                            
                            if (bandHeight <= TS) { // Don't draw if value is zero
                                float strokeHue = (((millis()/1000.0f)*hueSpeed) + ((float)i/width)*hueCycles + hueOffset)%1.0f;
                                stroke(strokeHue, 1, 1);
                                line(i, line*TS+TS, i, line*TS+bandHeight);
                                if (capEnabled) {
                                    stroke(1);
                                    point(i, line*TS+bandHeight);
                                }
                            }
                        }
                        break;
                    default: // VU Meter
                        int numSamples = PApplet.parseInt(min(in.sampleRate()/frameRate,in.bufferSize()));
                        float amplitude = 0;
                        for (int i = 0; i < numSamples; i++) {
                            amplitude += abs(in.mix.get(i));
                        }
                        amplitude /= numSamples;
                        amplitude *= ampMult;

                        for (int p = 0; p < min(width*amplitude,width); p++) {
                            float strokeHue = (((millis()/1000.0f)*hueSpeed) + ((float)p/width)*hueCycles + hueOffset)%1.0f;
                            stroke(strokeHue, 1, 1);
                            line(p, line*TS, p, line*TS+TS);
                        }
                        break;
                }
                break;
            
            case 2: // Clock
                setText(dateFormat.format(now));
                drawText();
                break;

            case 3: // Weather
                setText(Math.round(owm.getTemperature()) + "C - " + owm.getWeatherDescription());
                drawText();
                break;
            
            default: // Text display
                drawText();
                break;
        }
    }

    public void drawText() {
        if (rainbow) {
            tColor = color(millis()/1000.0f*rainbowSpeed%1.0f, 1, 1);
        }
        fill(tColor);
        
        switch(scrollMode) {
            case 1: // Scrolling forced off
                text(text, (width-sl)/2, y);
                break;
            case 2: // Scrolling forced on
            case 3: // Scroll once - logic is determined in scroll() function
                text(text, scroll(), y);
                break;
            default: // Auto
                if (sl > width+1) { // Scroll text only if too wide (+1 for automatically added space)
                    text(text, scroll(), y);
                } else {
                    text(text, (width-sl)/2, y);
                }
                break;
        }
    }
    
    public float scroll() {
        if (scrollDelay > 0) {
            scrollDelay--;
        } else if (scrollDelay == 0) {
            scrollDelay = -1;
            if (forward) {
                scrollPos -= scrollSpeed;
            } else {
                scrollPos += scrollSpeed;
            }
        } else {
            if (forward) {
                scrollPos -= (PApplet.parseFloat(TS)/width)*scrollSpeed;
                if (scrollPos < -PApplet.parseInt(textWidth(text)) - 1 && scrollMode != 3)
                    scrollReset();
            } else {
                scrollPos += (PApplet.parseFloat(TS)/width)*scrollSpeed;
                if (scrollPos > width && scrollMode != 3)
                    scrollReset();
            }
            if (round(scrollPos) == 0 && scrollMode != 3)
                scrollDelay = scrollDelayInit;
        }
        return scrollPos;
    }
    
    public void scrollReset() {
        if (forward) {
            scrollPos = width;
        } else {
            scrollPos = -PApplet.parseInt(textWidth(text)) - 1;
        }
    }
    
    public void scrollInit() {
        scrollPos = 0;
    }
    
    public void setText(String input_text) {
        text = input_text;
        c = text.length();
        sl = PApplet.parseInt(textWidth(text));
        y = (line*TS)+TS - 2;
    }
}
class Notification {
    String text;
    int c;
    int scrollPos;
    int push; // This keeps track of the screen position when "pushing it up" and back down
    int tWidth;
    boolean displayed;

    Notification(String t) {
        println("Notification: \"" + t + "\"");
        text = t;
        c = color(1);
        scrollPos = width;
        tWidth = 0;
        displayed = false;
        notification = true; // Set the global flag that a notification should be displayed
    }

    public void render() {
        translate(0, -push);
        if (push < TS && !displayed) {
            push++;
        } else if (push > 0 && displayed) {
            push--;
        } else if (push >= TS && !displayed) {
            text(text, scrollPos, height+TS);
            scroll();
        } else {
            notification = false;
        }
    }

    public void scroll() {
        if (scrollPos > -tWidth) {
            scrollPos--;
        } else {
            displayed = true;
            println("Notification cleared");
        }
    }
}
  public void settings() {  size(64, 32);  noSmooth(); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "RGB_LED" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
