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
    color tColor; // Text Color
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
    color capColor; // Color of the cap
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
        rainbowSpeed = .1;

        dateFormat = new SimpleDateFormat("E MMM dd HH:mm:ss");

        vMode = 0;
        ampMult = 1;
        hueCycles = 1;
        hueSpeed = .1;

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
        sl = int(textWidth(text));
        y = (line*TS)+TS - 2;
    }
    
    void render() {
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
                                float strokeHue = (((millis()/1000.0)*hueSpeed) + ((float)i/width)*hueCycles + hueOffset)%1.0f;
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
                        int numSamples = int(min(in.sampleRate()/frameRate,in.bufferSize()));
                        float amplitude = 0;
                        for (int i = 0; i < numSamples; i++) {
                            amplitude += abs(in.mix.get(i));
                        }
                        amplitude /= numSamples;
                        amplitude *= ampMult;

                        for (int p = 0; p < min(width*amplitude,width); p++) {
                            float strokeHue = (((millis()/1000.0)*hueSpeed) + ((float)p/width)*hueCycles + hueOffset)%1.0f;
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

    void drawText() {
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
    
    float scroll() {
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
                scrollPos -= (float(TS)/width)*scrollSpeed;
                if (scrollPos < -int(textWidth(text)) - 1 && scrollMode != 3)
                    scrollReset();
            } else {
                scrollPos += (float(TS)/width)*scrollSpeed;
                if (scrollPos > width && scrollMode != 3)
                    scrollReset();
            }
            if (round(scrollPos) == 0 && scrollMode != 3)
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
        c = text.length();
        sl = int(textWidth(text));
        y = (line*TS)+TS - 2;
    }
}
