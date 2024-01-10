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
float zPosition = 0;

// Current X and Y position variables
float xPositionInitial = 0;
float yPositionInitial = 0;
float zPositionInitial = 0;

//
float totalDistanceCovered = 0.0f;
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

float prevTemp = 0.0f;

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
    //translate(10 , height-10);
    translate(width/2 , height/2);
    

    // Set the length of the bars
    float barLength = 200;
    
    // Draw a red saquar object
    fill(255, 182, 193, 200);
    pushMatrix();
    //translate(xPosition, -yPosition, 0);  // Adjust the translation based on your needs
    translate(20 + xPosition, -20-yPosition, 0);  // Adjust the translation based on your needs
    // Get axis and angle from quaternion and apply rotation
    float[] axis = quat.toAxisAngle();
    rotate(axis[0], -axis[1], axis[3], axis[2]);
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
    textAlign(RIGHT, TOP);
    textSize(20);
    text("Distance: " + temp, 255, -280);
    popMatrix();
    drawPath();
  
    //Calculate 3D coordinates of the block
    PVector blockCoordinates = calculateBlockCoordinates(xPosition, yPosition);
    // Display the 3D coordinates
    fill(255);
    textAlign(LEFT, TOP);
    textSize(20);
    text("Block Coordinates: (" + nf(blockCoordinates.x, 0, 2) + ", " + nf(blockCoordinates.y, 0, 2) + ", " + nf(blockCoordinates.z, 0, 2) + ")", 20, 20);
    //totalDistanceCovered
    // Display the Total distance covered
    fill(255);
    textAlign(LEFT, TOP);
    textSize(20);
    text("Total Distance Covered: (" +totalDistanceCovered+ ")", 20, 40);
   
}
PVector calculateBlockCoordinates(float xPosition, float yPosition) {
    // Set the height of the block above the XY plane
    float zPosition = 0;

    // Use quaternion to calculate the rotation matrix
    float[][] rotationMatrix = calculateRotationMatrix(quat);

    // Apply the rotation to the block's local coordinates
    float localX = 15; // Adjust based on the size of the block
    float localY = 15; // Adjust based on the size of the block
    float localZ = 15; // Adjust based on the size of the block

    float globalX = rotationMatrix[0][0] * localX + rotationMatrix[1][0] * localY + rotationMatrix[2][0] * localZ;
    float globalY = rotationMatrix[0][1] * localX + rotationMatrix[1][1] * localY + rotationMatrix[2][1] * localZ;
    float globalZ = rotationMatrix[0][2] * localX + rotationMatrix[1][2] * localY + rotationMatrix[2][2] * localZ;

    // Translate to the block's position in the global coordinates
    float finalX = xPosition + globalX;
    float finalY = yPosition + globalY;
    float finalZ = zPosition + globalZ;

    return new PVector(finalX, finalY, finalZ);
}


void drawPath() {
    // Draw the path using lines connecting consecutive positions
    stroke(255);

    for (int i = 1; i < path.size(); i++) {
        float x1 = path.get(i - 1).x;
        float y1 = path.get(i - 1).y;
        float x2 = path.get(i).x +5;
        float y2 = path.get(i).y +5;
        
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
                //float preDis = 0.0f;
                // Extract distance value from the teapot packet
                    // Extract distance value from the teapot packet
                temp = Float.intBitsToFloat((teapotPacket[10]) | (teapotPacket[11] << 8) | (teapotPacket[12] << 16) | (teapotPacket[13] << 24));
                //temp = (int)(temp/10.0);
                //temp = temp/10.0;
                path.add(new PVector(width/2 + xPosition, height/2 - yPosition - 20));// line starting position 
                // Print distance value for debugging
                println(temp);
            
                // Calculate the rotation matrix from the quaternion
                float[][] rotationMatrix = calculateRotationMatrix(quat);

                //println("Rotation Matrix:");
                //for (int i = 0; i < 3; i++) {
                //    println(rotationMatrix[i][0] + "\t" + rotationMatrix[i][1] + "\t" + rotationMatrix[i][2]);
                //}
                // Extract the rotation angles
                float pitch = degrees(atan2(rotationMatrix[2][1], rotationMatrix[2][2]));
                float roll = degrees(atan2(-rotationMatrix[2][0], sqrt(rotationMatrix[2][1] * rotationMatrix[2][1] + rotationMatrix[2][2] * rotationMatrix[2][2])));
                float yaw = degrees(atan2(rotationMatrix[1][0], rotationMatrix[0][0]));
                
                //float xComponent = temp * cos(radians(yaw)) * cos(radians(pitch));
                //xPosition = xComponent;
                //println("pitch", (pitch));
                //println("roll", abs(roll));
                //println("yaw", abs(yaw));
                float tempDifference = temp - prevTemp;
                println("Difference %d\n",tempDifference);
                 //for greater step size at change of axis  
                if (tempDifference > 10 || tempDifference < -10) 
                {
                  // Update previous temperature
                  prevTemp = temp;
                  tempDifference = temp - prevTemp;
                }
                 // Calculate 3D coordinates of the block
                float[] axis = quat.toAxisAngle();
                //tempDifference =0.0;
                
                // Check the orientation of the block
              if (abs(roll) > abs(pitch) && abs(roll) > abs(yaw)) 
              {
                  println("Block is along Z-axis");
                  if (tempDifference == 0) 
                  {
                      // Stop
                  } else if (tempDifference < 0) 
                  {
                      // Move forward along the Z-axis
                      zPosition = zPosition + abs(tempDifference);
                  } 
                  else 
                  {
                      // Move backward along the Z-axis
                      zPosition = zPosition - abs(tempDifference);
                  }
              }
              else if (abs(yaw) > abs(roll) && abs(yaw) > abs(pitch)) 
              {
                  println("Block is along X-axis");
                  
                  if (tempDifference == 0) 
                  {
                      // Stop
                  } 
                  else if (tempDifference < 0) 
                  {
                      // Move forward along the X-axis
                      xPosition = xPosition + abs(tempDifference);
                      totalDistanceCovered += abs(tempDifference);
                  } 
                  else 
                  {
                      // Move backward along the X-axis
                      xPosition = xPosition - abs(tempDifference);
                      totalDistanceCovered -= abs(tempDifference);
                  }
                  
              }
              else if (abs(pitch) > abs(roll) && abs(pitch) > abs(yaw)) // for upward and downwards motions in the x y plane
              { 
                  
                float pitchInRadians = radians(pitch);
          
                //print("slop angle = ", pitchInRadians);
                if (tempDifference == 0) 
                {
                // Stop
                }
                else if (tempDifference < 0) 
                {
                // Move forward along the Y-axis
                  xPosition = xPosition + abs(tempDifference) * cos(pitchInRadians);
                  yPosition = yPosition + abs(tempDifference) * -sin(pitchInRadians);
                  
                  float distance = sqrt(pow((abs(tempDifference) * cos(pitchInRadians)) - xPositionInitial, 2) + pow((abs(tempDifference) * -sin(pitchInRadians)) - yPositionInitial, 2));
                  totalDistanceCovered += abs(tempDifference); 
                  xPositionInitial = abs(tempDifference) * cos(pitchInRadians);
                  yPositionInitial = abs(tempDifference) * -sin(pitchInRadians);
                  print("abs(tempDifference) :" , abs(tempDifference));
                  print(" cos(pitchInRadians :" , -sin(pitchInRadians));
                 
                }
                else 
                {
                 // Move backward along the slope
                  xPosition = xPosition - abs(tempDifference) * cos(pitchInRadians);
                  yPosition = yPosition - abs(tempDifference) * -sin(pitchInRadians);
                  
                  float distance = sqrt(pow((abs(tempDifference) * cos(pitchInRadians)) - xPositionInitial, 2) + pow((abs(tempDifference) * -sin(pitchInRadians)) - yPositionInitial, 2));
                  totalDistanceCovered -= abs(tempDifference); 
                  xPositionInitial = abs(tempDifference) * cos(pitchInRadians);
                  yPositionInitial = abs(tempDifference) * sin(pitchInRadians);
                }
                 
              } 
              
                prevTemp = temp;
                print("Total Distance covered :" , totalDistanceCovered);
                
                delay(50);
            }
        }
    }
}

float[][] calculateRotationMatrix(Quaternion quaternion) 
{
    float[][] rotationMatrix = new float[3][3];

    float sqw = quaternion.w * quaternion.w;
    float sqx = quaternion.x * quaternion.x;
    float sqy = quaternion.y * quaternion.y;
    float sqz = quaternion.z * quaternion.z;

    // Normalization factor
    float invs = 1 / (sqx + sqy + sqz + sqw);

    rotationMatrix[0][0] = (sqx - sqy - sqz + sqw) * invs;
    rotationMatrix[1][1] = (-sqx + sqy - sqz + sqw) * invs;
    rotationMatrix[2][2] = (-sqx - sqy + sqz + sqw) * invs;

    float tmp1 = quaternion.x * quaternion.y;
    float tmp2 = quaternion.z * quaternion.w;
    rotationMatrix[0][1] = 2.0f * (tmp1 + tmp2) * invs;
    rotationMatrix[1][0] = 2.0f * (tmp1 - tmp2) * invs;

    tmp1 = quaternion.x * quaternion.z;
    tmp2 = quaternion.y * quaternion.w;
    rotationMatrix[0][2] = 2.0f * (tmp1 - tmp2) * invs;
    rotationMatrix[2][0] = 2.0f * (tmp1 + tmp2) * invs;

    tmp1 = quaternion.y * quaternion.z;
    tmp2 = quaternion.x * quaternion.w;
    rotationMatrix[1][2] = 2.0f * (tmp1 + tmp2) * invs;
    rotationMatrix[2][1] = 2.0f * (tmp1 - tmp2) * invs;

    return rotationMatrix;
}
