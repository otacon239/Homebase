import java.text.SimpleDateFormat;
import java.util.Date;
import processing.sound.*;

Amplitude amp;
AudioIn in;
float ampMod = 3;

Date now = new Date();
SimpleDateFormat dateFormatter = new SimpleDateFormat("E MMM dd HH:MM:ss");

static final int TS = 8; // Text size after scaling
static final float default_SS = 2; // Default scroll speed multiplier

ArrayList <Display> lines = new ArrayList<Display>();

int curr_subs = 0;

void setup() {
    size(64, 32); // Size of Adafruit display
    frameRate(60);
    background(0);
    colorMode(HSB, 360, 1.0, 1.0);
    noStroke();
    PFont font = loadFont("04b03-8.vlw");
    textFont(font, TS);
    noSmooth();

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

void draw() {
    background(0);
    for (int i = 0; i < lines.size(); i++)
        lines.get(i).render();

    if (curr_subs != int(millis())) {
        curr_subs = int(millis()/5000);
        lines.get(3).setText("Subs: " + curr_subs);
    }
    
    now = new Date();
    lines.get(1).setText(dateFormatter.format(now));
    lines.get(0).tColor = color(millis()/60%360, 1, 1);
}

void keyPressed() {
    if (keyCode == ESC || key == 'q') {
        exit();
    }
}