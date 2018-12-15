class Notification {
    String text;
    color c;
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

    void render() {
        translate(0, -push);
        if (push < TS && !displayed) {
            push++;
        } else if (push > 0 && displayed) {
            push--;
        } else if (push >= TS && !displayed) {
            text(text, scrollPos, height+TS-1);
            scroll();
        } else {
            notification = false;
        }
    }

    void scroll() {
        if (scrollPos > -tWidth) {
            scrollPos--;
        } else {
            displayed = true;
            println("Notification cleared");
        }
    }
}