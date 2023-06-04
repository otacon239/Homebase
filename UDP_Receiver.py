# Import necessary libraries
import os
import socket
import struct
import psutil
from PIL import Image
from rgbmatrix import RGBMatrix, RGBMatrixOptions

# Define a function to set process affinity to a single core
def set_process_affinity(core_id):
    # Get the current process ID
    pid = os.getpid()
    # Get the process object
    process = psutil.Process(pid)
    # Set the CPU affinity of the process to the specified core
    process.cpu_affinity([core_id])

# Reserve a specific core, in this case, core number 3
reserved_core = 3
set_process_affinity(reserved_core)

# Define the IP address and port for the UDP server
UDP_IP = "0.0.0.0"
UDP_PORT = 8888

# Create and bind the UDP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind((UDP_IP, UDP_PORT))

# Define a function to receive an image via the UDP socket
def receive_image():
    img_data = bytearray()  # Initialize an empty bytearray for the image data
    bytes_received = 0  # Initialize a counter for the total bytes received
    width = 64  # Define the width of the image
    height = 32  # Define the height of the image
    expected_size = width * height * 4  # Calculate the expected size of the image data in bytes

    # Keep receiving data until we've received the expected amount of data
    while bytes_received < expected_size:
        # Receive a packet of data
        packet_data, addr = sock.recvfrom(65536)
        # Append the packet data to the image data
        img_data.extend(packet_data)
        # Increase the counter by the size of the packet data
        bytes_received += len(packet_data)
        # Print the current total bytes received
        print(f"Received data length: {bytes_received}")

    # If the total bytes received does not match the expected size, print an error message and return None
    if bytes_received != expected_size:
        print(f"Received data length does not match the expected size: {expected_size}")
        return None

    # Convert the image data to an Image object and return it
    img = Image.frombytes('RGBA', (width, height), bytes(img_data))
    return img

# Define the options for the RGB matrix
options = RGBMatrixOptions()
options.rows = 32
options.cols = 64
options.chain_length = 1
options.parallel = 1
options.hardware_mapping = 'adafruit-hat-pwm'

# Create the RGB matrix with the specified options
matrix = RGBMatrix(options=options)

# Enter an infinite loop to continuously receive and display images
while True:
    try:
        # Receive an image
        image = receive_image()
        # Create a new black background image
        background = Image.new('RGBA', image.size, (0, 0, 0, 255))
        # Composite the received image onto the background image
        combined = Image.alpha_composite(background, image.convert('RGBA'))
        # Convert the composite image to RGB format and set it as the current image on the RGB matrix
        matrix.SetImage(combined.convert('RGB'))
    # Exit the loop if a KeyboardInterrupt is detected
    except KeyboardInterrupt:
        break

# Clear the RGB matrix
matrix.Clear()
