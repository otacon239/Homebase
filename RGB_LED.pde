import java.text.SimpleDateFormat;
import java.util.Date;

Date now = new Date();
SimpleDateFormat dateFormatter = new SimpleDateFormat("E MMM dd HH:MM");

static final int TS = 8; // Text size after scaling
static final float default_SS = 2; // Default scroll speed multiplier

ArrayList <Display> lines = new ArrayList<Display>();

int curr_subs = 20;

void setup() {
  size(64, 32); // Size of Adafruit display
  frameRate(60);
  background(0);
  colorMode(HSB, 360, 100, 100);
  noStroke();
  PFont font = loadFont("04b03-8.vlw");
  textFont(font, TS);
  noSmooth();
  //textSize(TS);
  
  for (int l = 0; l < height*TS; l++) {
    lines.add(new Display());
    lines.get(l).line = l;
  }
  
  lines.get(0).setText("Omnigon Network");
  lines.get(1).setText(dateFormatter.format(now));
  lines.get(1).scrollMode = 1;
  lines.get(2).setText("32C - Broken Clouds");
  lines.get(2).forward = false;
  lines.get(3).setText("Current Subs: " + curr_subs);
  lines.get(3).forward = false;
}

void draw() {
  background(0);
  for (int i = 0; i < lines.size(); i++)
    lines.get(i).render();
  
  if (curr_subs != int(millis()/5000)+20) {
    curr_subs = int(millis()/5000)+20;
    lines.get(3).setText("Current Subs: " + curr_subs);
    lines.get(3).scrollInit();
  }
}

void keyPressed() {
  if (keyCode == ESC || key == 'q') {
    exit();
  }
}