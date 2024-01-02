// Import Toxiclibs library and Processing serial library
import processing.serial.*;
import processing.opengl.*;
import toxi.geom.*;
import toxi.processing.*;

// Create a ToxiclibsSupport object for 3D graphics
ToxiclibsSupport gfx;

// Serial port for communication with ESP32
Serial port;

// Teapot packet received from ESP32
char[] teapotPacket = new char[18];

// Variables to keep track of current packet byte position, synchronization, and interval
int serialCount = 0;
int synced = 0;
int interval = 0;

// Quaternion variables for orientation tracking
float[] q = new float[4];
float temp;
Quaternion quat = new Quaternion(1, 0, 0, 0);

// Gravity, Euler angles, and Yaw/Pitch/Roll angles variables
float[] gravity = new float[3];
float[] euler = new float[3];
float[] ypr = new float[3];

// Current X and Y position variables
float xPosition = 0;
float yPosition = 0;

// Adjust the size of the sphere
float sphereSize = 15;  

// Previous X and Y position variables for path drawing
float prevX = 0;
float prevY = 0;

// List to store positions for drawing the path
ArrayList<PVector> path = new ArrayList<PVector>();

void setup() {
    // Set up the canvas size with OpenGL rendering
    size(600, 600, OPENGL);

    // Initialize ToxiclibsSupport for 3D graphics
    gfx = new ToxiclibsSupport(this);

    // Enable lights and smooth rendering
    lights();
    smooth();

    // Set the serial port name
    String portName = "COM4";

    // Initialize the serial port
    port = new Serial(this, portName, 115200);

    // Trigger DMP initialization in ESP32
    port.write('r');
}

void draw() {
    // Check if it's time to resend the initialization trigger
    if (millis() - interval > 1000) {
        port.write('r');
        interval = millis();
    }

    // Set the background color
    background(40);

    // Translate everything to the middle of the viewport
    pushMatrix();
    translate(10 , height-10);

    // Get axis and angle from quaternion and apply rotation
    float[] axis = quat.toAxisAngle();
    rotate(axis[0], -axis[1], axis[3], axis[2]);

    // Set the length of the bars
    float barLength = 200;
    
    // Draw a red spherical object
    fill(255, 182, 193, 200);
    pushMatrix();
    //translate(xPosition, -yPosition, 0);  // Adjust the translation based on your needs
    translate(20 + xPosition, -20-yPosition, 0);  // Adjust the translation based on your needs
    box(15, 15, 15);
    popMatrix();
    
    // Draw X-axis bar in red
    fill(0, 255, 255, 200);
    pushMatrix();
    translate(100, 0, 0);
    box(barLength, 10, 10);
    popMatrix();

    // Draw Y-axis bar in green
    fill(255, 255, 0, 200);
    pushMatrix();
    rotateZ(HALF_PI);
    translate(-barLength / 2, 0, 0);
    box(barLength, 10, 10);
    popMatrix();

    // Display the distance text
    fill(255);
    textAlign(LEFT, TOP);
    textSize(20);
    text("Distance: " + temp, 300, -300);
    popMatrix();

    // Draw the path
    if (frameCount > 22) 
    {
        stroke(255);
        line(prevX, prevY, width/2 + xPosition, height/2 - yPosition);
    }
    // Draw the path
      drawPath();
    // Update previous position
    prevX = width/2 + xPosition;
    prevY = height/2 - yPosition;
}

void drawPath() 
{
    // Draw the path using lines connecting consecutive positions
    stroke(255);
    for (int i = 1; i < path.size(); i++) {
        float x1 = path.get(i-1).x;
        float y1 = path.get(i-1).y;
        float x2 = path.get(i).x;
        float y2 = path.get(i).y;
        line(x1, y1, x2, y2);
    }
}

void serialEvent(Serial port) {
    // Update the interval time
    interval = millis();

    // Check for available bytes in the serial port
    while (port.available() > 0) {
        // Read a byte from the serial port
        int ch = port.read();

        // Initial synchronization check
        if (synced == 0 && ch != '$') return;
        synced = 1;

        // Check for synchronization bytes and positions
        if ((serialCount == 1 && ch != 2)
            || (serialCount == 16 && ch != '\r')
            || (serialCount == 17 && ch != '\n'))  {
            serialCount = 0;
            synced = 0;
            return;
        }

        // Process teapot packet bytes
        if (serialCount > 0 || ch == '$') {
            teapotPacket[serialCount++] = (char)ch;
            
            // If a full packet is received
            if (serialCount == 18) {
                serialCount = 0;

                // Extract quaternion values from the teapot packet
                q[0] = ((teapotPacket[2] << 8) | teapotPacket[3]) / 16384.0f;
                q[1] = ((teapotPacket[4] << 8) | teapotPacket[5]) / 16384.0f;
                q[2] = ((teapotPacket[6] << 8) | teapotPacket[7]) / 16384.0f;
                q[3] = ((teapotPacket[8] << 8) | teapotPacket[9]) / 16384.0f;

                // Normalize quaternion values if necessary
                for (int i = 0; i < 4; i++) if (q[i] >= 2) q[i] = -4 + q[i];

                // Set the Toxiclibs quaternion to new data
                quat.set(q[0], q[1], q[2], q[3]);

                // Extract distance value from the teapot packet
                temp = Float.intBitsToFloat((teapotPacket[10]) | (teapotPacket[11] << 8) | (teapotPacket[12] << 16) |(teapotPacket[13] << 24));
                path.add(new PVector(15+ xPosition, height - yPosition-20));
                // Print distance value for debugging
                println(temp);
                // Update the current position based on the distance and orientation
                //xPosition += cos(radians(ypr[0])) * temp;
                //yPosition += sin(radians(ypr[0])) * temp;
                
                xPosition +=5;
                delay(1000);
                if (100 < xPosition && xPosition < 150) {
                    yPosition += 50;
                    delay(1000);
                }
            }
        }
    }
}
