# Homebase

### ***A project for dashboard displays***

This is a Processing project that allows for simple interaction with an RGB LED large-pixel display. The default project was built for a 64x32 pixel display, but can scale as needed.

Each line is treated as its own object with its own effects. These lines include customization features such as:
- Color
- Scrolling
- Date/Time formatting
- Weather
- VU Meter

The project was less deisnged as a complete solution and more as a platform for extending this into more powerful line items to add functionality. These could include ideas such as:
- Subscriber counter
- Resource monitor
- Notification receiver
- Announcement display
- Now playing ticker

The advantage to using Processing for the sending side is that it is quite a bit simpler to manage objects, memory, etc outside of the hardware and allows for much more straightforward development, while leaving the hardware end to act as a "dumb" receiver. This also opens up the receiver to take in UDP frames from other scripts or even other programming languages.

I've also included an example Python script that was used on an Adafruit RGB Matrix Bonnet, however, the packet being sent is designed to be highly adaptable and should be able to be received by nearly anything with a UDP library and graphics output.

## Setup

1. Clone this repository to the host computer (the one that will be running Processing)
2. Download the required libraries:
    - For respository libraries (Minim, UDP), open Processing and go to `Sketch >> Import Library >> Manage Library`, then choose to download these libraries
    - For OpenWeatherMap, you'll need to download the most recent .zip (not source code) from here: https://github.com/jnsdbr/OpenWeatherMap/releases, then go to `Sketch >> Add File` and choose the .jar found in the library folder to add this to the project - Other methods falied for me - If there is a more correct way, I haven't found it.
    - Download the recommended font from here: https://www.dafont.com/04b-03.font and place the `.ttf` in the ../data/ directory.
        - You may need to manually rename the extracted file to `04b03-8.ttf`.
3. Update necessary variables in the `Homebase.pde` file:
    - `API_KEY` - OWM API Key can be acquired here: https://openweathermap.org/api
    - `ZIP,COUNTRY_CODE` - More information here: https://openweathermap.org/current#zip
    - `DEST_IP`,`DEST_PORT`,`SEND_PORT` - These are set to send to localhost by default, from port 8888 to port 9999. (9999 is the default receiving port for the Python receiver as well)
4. Copy or move `UDP_Receiver.py` to the receiving computer. If you have the display connected to this computer, this step isn't necessary.
5. Run the Python script with `sudo` or Administrator privilages on the receiving computer, then start the Processing script on the sending machine. (Order doesn't technically matter here, but this allows the boot animation to be displayed)

Congrats! You should now have enough to get started!