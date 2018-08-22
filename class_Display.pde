class Display {
    int lineMode;
    /*
    Mode switch:
    0 - Plain text
    1 - vMeter - Basic VU Meter based on audio input
    2 - Clock
    3 - Weather
    */

    String text; // The text to be displayed
    int line; // What line for the text to be displayed
    boolean forward; // Direction of text
    float scrollSpeed; // Speed of text in pixels/frame
    color tColor; // Text Color
    boolean rainbow; // Enable/disable rainbow text
    float rainbowSpeed; // Speed of hue cycle on rainbow effect

    SimpleDateFormat dateFormat; // See https://docs.oracle.com/javase/7/docs/api/java/text/SimpleDateFormat.html for more info

    int vMode; // To be used later when more visualizers are added
    float vSmooth; // Sets level of averaging for amplitude
    float amp; // Resulting amplitude
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

        vMode = 0;
        vSmooth = 0;
        amp = 0;
        hueCycles = 1;
        hueSpeed = 1;
        
        scrollSpeed = 1;
        scrollMode = 0;
        scrollPos = 0;
        scrollDelay = 50;
        scrollDelayInit = scrollDelay;
        
        l = text.length();
        sl = int(textWidth(text));
        y = (line*TS)+TS - 2; 
    }
    
    void render() {
        switch(lineMode) {
            case 1: // vMeter
                switch(vMode) { // For adding more visualizers in the future
                    default:
                        amp = (amp*vSmooth+amp.analyze()*ampMod*2)/(vSmooth+1);
                        for (int p = 0; p < width*amp; p++) {
                            stroke(((p*(360/width*hueCycles))+(millis()*1/60*hueSpeed))%360, 1, 1);
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

    void drawText() {
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
    
    float scroll() {
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
                scrollPos -= (float(TS)/width)*scrollSpeed;
                if (scrollPos < -int(textWidth(text)) - 1)
                    scrollReset();
                    
            } else {
                scrollPos += (float(TS)/width)*scrollSpeed;
                if (scrollPos > width)
                    scrollReset();
            }
            
            if (round(scrollPos) == 0)
                scrollDelay = scrollDelayInit;
        }
        
        return scrollPos;
    }
    
    void scrollReset() {
        if (forward) {
            scrollPos = width;
        } else {
            scrollPos = -int(textWidth(text)) - 1;
        }
    }
    
    void scrollInit() {
        scrollPos = 0;
    }
    
    void setText(String input_text) {
        text = input_text;
        l = text.length();
        sl = int(textWidth(text));
        y = (line*TS)+TS - 2;
    }
}