import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.text.SimpleDateFormat; 
import java.util.Date; 
import processing.sound.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class RGB_LED extends PApplet {





Amplitude amp;
AudioIn in;
float ampMod = 3;

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

    lines.get(0).setText("Welcome to Omnigon");
    lines.get(1).setText(dateFormatter.format(now));
    lines.get(1).scrollMode = 1;
    lines.get(1).scrollDelayInit = 0;
    lines.get(1).tColor = color(0, 0, 1);
    lines.get(2).setText("32C - Broken Clouds");
    lines.get(2).tColor = color(180);
    lines.get(3).vuMeter = true;
    lines.get(3).vuSmooth = 2;
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
    float vuBoost;
    float vuSmooth;
    float sclSnd;
    
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
        vuSmooth = 0;
        sclSnd = 0;
        
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
            sclSnd = (sclSnd*vuSmooth+amp.analyze()*ampMod*2)/(vuSmooth+1);
            for (int p = 0; p < width*sclSnd; p++) {
                fill((((p*PI)+(millis()*1/30)))%360, 1, 1);
                rect(p, line*TS, 1, TS);
            }
            //rect(0, line*TS, width*amp.analyze()*2, TS);
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
