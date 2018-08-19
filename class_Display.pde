class Display {
    String text; // The text to be displayed
    int line; // What line for the text to be displayed
    boolean forward; // Direction of text
    float scrollSpeed; // Speed of text in pixels/frame
    color tColor;

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
        
        scrollSpeed = (float(TS)/width)*default_SS;
        scrollMode = 0;
        scrollPos = 0;
        scrollDelay = 50;
        scrollDelayInit = scrollDelay;
        
        l = text.length();
        sl = int(textWidth(text));
        y = (line*TS)+TS - 2; 
    }
    
    void render() {
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
                scrollPos -= scrollSpeed;
                if (scrollPos < -int(textWidth(text)) - 1)
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