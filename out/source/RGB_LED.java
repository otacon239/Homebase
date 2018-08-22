import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.text.SimpleDateFormat; 
import java.util.Date; 
import processing.sound.*; 
import de.jnsdbr.openweathermap.*; 

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





// Setup OpenWeatherMap
OpenWeatherMap owm;
// OWM API Key can be acquired here: https://openweathermap.org/api
final String API_KEY = "389d6c663dc37361a7aee8f600063c67"; // TODO: place this in .conf file
final String location = "85257, us"; // More information here: https://openweathermap.org/current

// Setup amplitude monitor variables
Amplitude amp;
AudioIn in;
float ampMod = 2; // Multiplier for base amplitude - Adjust this to scale the input


static final int TS = 8; // Text size

ArrayList <Display> lines = new ArrayList<Display>(); // Setup array where each line is its own object

public void setup() {
     // Size of Adafruit display in pixels
    frameRate(60);
    background(0);
    colorMode(HSB, 360, 1.0f, 1.0f);

    PFont font = loadFont("04b03-8.vlw"); // Must use "Create Font" option to use others
    textFont(font, TS);
     // As this is pixel perfect text, we want to disable smoothing

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
    lines.get(3).hueCycles = .5f;
}

public void draw() {
    // TODO: Find a way to run updateWeather only once an hour
    background(0);

    for (int i = 0; i < lines.size(); i++)
        lines.get(i).render();
}

public void updateWeather() { // Pull new weather information (only run this rarely as this will pull from the API key)
        owm = new OpenWeatherMap(this, API_KEY, location);
}

public void keyPressed() {
    if (keyCode == ESC || key == 'q') { // Exit app
        exit();
    }
}
class Display {
    int lineMode; // Mode switch

    String text; // The text to be displayed
    int line; // What line for the text to be displayed
    boolean forward; // Direction of text
    float scrollSpeed; // Speed of text in pixels/frame
    int tColor; // Text Color
    boolean rainbow; // Enable/disable rainbow text
    float rainbowSpeed; // Speed of hue cycle on rainbow effect

    SimpleDateFormat dateFormat; // See https://docs.oracle.com/javase/7/docs/api/java/text/SimpleDateFormat.html for more info
    Date now; // Type for storing the current time

    int vuMode; // To be used later when more visualizers are added
    float vuSmooth; // Sets level of averaging for amplitude
    float sclSnd; // Designed for storing the sound level only once per frame
    float hueCycles; // Number of full hue rotations on the screen
    float hueSpeed; // Speed the hue rotation moves in degrees per frame
    
    int scrollMode; // 0 = Auto (based on string width), 1 = On, 2 = Off
    float scrollPos; // X position of text that is too wide for display
    int scrollDelay; // How long the text stops once it's reached the left edge
    int scrollDelayInit; // Initial scroll delay setting - This is typically the one you want to change when changing the option
    
    int l; // Number of characters
    int sl; // Length of text in pixels
    int y; // Y position in pixels
    
    Display() {
        lineMode = 0;

        text = "";
        line = 0;
        forward = true;
        tColor = color(0, 0, 1);
        rainbow = false;
        rainbowSpeed = 1;

        dateFormat = new SimpleDateFormat("E MMM dd HH:mm:ss");
        now = new Date();

        vuMode = 0;
        vuSmooth = 0;
        sclSnd = 0;
        hueCycles = 1;
        hueSpeed = 1;
        
        scrollSpeed = 1;
        scrollMode = 0;
        scrollPos = 0;
        scrollDelay = 50;
        scrollDelayInit = scrollDelay;
        
        l = text.length();
        sl = PApplet.parseInt(textWidth(text));
        y = (line*TS)+TS - 2; 
    }
    
    public void render() {
        switch(lineMode) {
            case 1: // vuMeter
                switch(vuMode) { // For adding more visualizers in the future
                    default:
                        sclSnd = (sclSnd*vuSmooth+amp.analyze()*ampMod*2)/(vuSmooth+1);
                        for (int p = 0; p < width*sclSnd; p++) {
                            stroke((((p*(360/width*hueCycles))+(millis()*1/60*hueSpeed)))%360, 1, 1);
                            line(p, line*TS, p, line*TS+TS);
                        }
                        break;
                }
                break;
            
            case 2: // Clock
                now = new Date();
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
            tColor = color(millis()/60*rainbowSpeed%360, 1, 1);
        }
        fill(tColor);
        
        switch(scrollMode) {
            case 1: // Scrolling forced off
                text(text, (width-sl)/2, y);
                break;
            case 2: // Scrolling forced on
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
                scrollPos--;
            } else {
                scrollPos++;
            }
            
        } else {
            if (forward) {
                scrollPos -= (PApplet.parseFloat(TS)/width)*scrollSpeed;
                if (scrollPos < -PApplet.parseInt(textWidth(text)) - 1)
                    scrollReset();
                    
            } else {
                scrollPos += (PApplet.parseFloat(TS)/width)*scrollSpeed;
                if (scrollPos > width)
                    scrollReset();
            }
            
            if (round(scrollPos) == 0)
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
        l = text.length();
        sl = PApplet.parseInt(textWidth(text));
        y = (line*TS)+TS - 2;
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
