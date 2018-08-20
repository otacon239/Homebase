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






OpenWeatherMap owm;
final String API_KEY = "5cc2ef80549e61df7e7e11b561810dca";

Amplitude amp;
AudioIn in;
float ampMod = 2;

Date now = new Date();
SimpleDateFormat dateFormatter = new SimpleDateFormat("E MMM dd HH:MM:ss");

static final int TS = 8; // Text size after scaling
static final float default_SS = 2; // Default scroll speed multiplier

ArrayList <Display> lines = new ArrayList<Display>();

int curr_subs = 0;

public void setup() {
     // Size of Adafruit display
    frameRate(60);
    background(0);
    colorMode(HSB, 360, 1.0f, 1.0f);
    noStroke();
    PFont font = loadFont("04b03-8.vlw");
    textFont(font, TS);
    

    amp = new Amplitude(this);
    in = new AudioIn(this, 0);
    in.start();
    amp.input(in);

    for (int l = 0; l < height*TS; l++) {
        lines.add(new Display());
        lines.get(l).line = l;
    }

    owm = new OpenWeatherMap(this, API_KEY, "85257");

    lines.get(0).setText("Now Playing: Mystery Skulls - Music"); // Placeholder for future music mode
    lines.get(1).setText(dateFormatter.format(now));
    lines.get(1).scrollMode = 1;
    lines.get(1).scrollDelayInit = 0;
    lines.get(1).tColor = color(0, 0, 1);
    lines.get(2).setText(Math.round(owm.getTemperature()) + "C - " + owm.getWeatherDescription()); // Placeholder for future weather mode
    lines.get(2).tColor = color(180);
    lines.get(3).vuMeter = true;
    lines.get(3).vuSmooth = 2;
    lines.get(3).hueCycles = .5f;
}

public void draw() {
    background(0);
    for (int i = 0; i < lines.size(); i++)
        lines.get(i).render();

    if (curr_subs != PApplet.parseInt(millis())) {
        curr_subs = PApplet.parseInt(millis()/5000);
        lines.get(3).setText("Subs: " + curr_subs);
    }
    
    now = new Date();
    lines.get(1).setText(dateFormatter.format(now));
    lines.get(0).tColor = color(millis()/60%360, 1, 1);
}

public void keyPressed() {
    if (keyCode == ESC || key == 'q') {
        exit();
    }
}
class Display {
    String text; // The text to be displayed
    int line; // What line for the text to be displayed
    boolean forward; // Direction of text
    float scrollSpeed; // Speed of text in pixels/frame
    int tColor;

    boolean vuMeter;
    int vuMode;
    float vuBoost;
    float vuSmooth;
    float sclSnd;
    float hueCycles;
    float hueSpeed;
    
    int scrollMode; // 0 = Auto, 1 = On, 2 = Off
    float scrollPos; // X position of text that is too wide for display
    int scrollDelay;
    int scrollDelayInit;
    
    int l; // Number of characters
    int sl; // Length of text in pixels
    int y; // Y position in pixels
    
    Display() {
        text = "";
        line = 0;
        forward = true;
        tColor = color(0, 0, 1);

        vuMeter = false;
        vuMode = 0;
        vuSmooth = 0;
        sclSnd = 0;
        hueCycles = 1;
        hueSpeed = 1;
        
        scrollSpeed = (PApplet.parseFloat(TS)/width)*default_SS;
        scrollMode = 0;
        scrollPos = 0;
        scrollDelay = 50;
        scrollDelayInit = scrollDelay;
        
        l = text.length();
        sl = PApplet.parseInt(textWidth(text));
        y = (line*TS)+TS - 2; 
    }
    
    public void render() {
        if(vuMeter) {
            switch(vuMode) {
                default:
                    sclSnd = (sclSnd*vuSmooth+amp.analyze()*ampMod*2)/(vuSmooth+1);
                    for (int p = 0; p < width*sclSnd; p++) {
                        stroke((((p*(360/width*hueCycles))+(millis()*1/60*hueSpeed)))%360, 1, 1);
                        line(p, line*TS, p, line*TS+TS);
                    }
                    break;
            }
        } else {
            fill(tColor);
            if ((sl <= width || scrollMode == 2) && scrollMode != 1) {
                text(text, (width-sl)/2, y);
            } else {
                text(text, scroll(), y);
            }
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
                scrollPos -= scrollSpeed;
                if (scrollPos < -PApplet.parseInt(textWidth(text)) - 1)
                    scrollReset();
                    
            } else {
                scrollPos += scrollSpeed;
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
