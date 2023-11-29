import processing.serial.*;
import processing.opengl.*;
import toxi.geom.*;
import toxi.processing.*;

// NOTE: requires ToxicLibs to be installed in order to run properly.
// 1. Download from http://toxiclibs.org/downloads
// 2. Extract into [userdir]/Processing/libraries
//    (location may be different on Mac/Linux)
// 3. Run and bask in awesomeness

ToxiclibsSupport gfx;

Serial port;                         // The serial port
char[] teapotPacket = new char[18];  // InvenSense Teapot packet
int serialCount = 0;                 // current packet byte position
int synced = 0;
int interval = 0;

float[] q = new float[4];
float temp;
Quaternion quat = new Quaternion(1, 0, 0, 0);

float[] gravity = new float[3];
float[] euler = new float[3];
float[] ypr = new float[3];

void setup() {
    // 300px square viewport using OpenGL rendering
    size(600, 600, OPENGL);
    gfx = new ToxiclibsSupport(this);

    // setup lights and antialiasing
    lights();
    smooth();
  
    // display serial port list for debugging/clarity
    //println(Serial.list());

    // get the first available port (use EITHER this OR the specific port code below)
    //String portName = Serial.list()[0];
    
    // get a specific serial port (use EITHER this OR the first-available code above)
    String portName = "COM4";
    
    // open the serial port
    port = new Serial(this, portName, 115200);
    
    // send single character to trigger DMP init/start
    // (expected by MPU6050_DMP6 example Arduino sketch)
    port.write('r');
}

void draw() {
    if (millis() - interval > 1000) {
        // resend single character to trigger DMP init/start
        // in case the MPU is halted/reset while applet is running
        port.write('r');
        interval = millis();
    }
    
    // black background
    background(40);
    
    // translate everything to the middle of the viewport
    pushMatrix();
    translate(width/2, height/2);

    // 3-step rotation from yaw/pitch/roll angles (gimbal lock!)
    // ...and other weirdness I haven't figured out yet
    //rotateY(-ypr[0]);
    //rotateZ(-ypr[1]);
    //rotateX(-ypr[2]);

    // toxiclibs direct angle/axis rotation from quaternion (NO gimbal lock!)
    // (axis order [1, 3, 2] and inversion [-1, +1, +1] is a consequence of
    // different coordinate system orientation assumptions between Processing
    // and InvenSense DMP)
    float[] axis = quat.toAxisAngle();
    rotate(axis[0], -axis[1], axis[3], axis[2]);
    float barLength = 200;
    // draw main body in red
    //fill(0, 255,255, 150);
    //box(15, -15, 200);
    
    //Draw X-axis bar starting from the origin
    fill(0, 255, 255, 200); // Red color
    pushMatrix();
    translate(-100, 0, 0); // Translate along X-axis by half the bar length
    box(barLength, 10, 10); // X-axis is 200 units long
    popMatrix();
    
    // Draw Y-axis bar starting from the origin
    fill(255, 255, 0, 200); // Green color
    pushMatrix();
    rotateZ(HALF_PI); // Rotate 90 degrees to align with Y-axis
    translate(barLength / 2, 0, 0); // Translate along Y-axis by half the bar length
    box(barLength, 10, 10); // Y-axis is 200 units long
    popMatrix();
    
    // Draw Z-axis bar starting from the origin
    fill(255, 255, 255, 200); // Blue color
    pushMatrix();
    rotateY(HALF_PI); // Rotate 90 degrees to align with Z-axis
    translate(barLength / 2, 0, 0); // Translate along Z-axis by half the bar length
    box(barLength, 10, 10); // Z-axis is 200 units long
    // Draw Z label at the end of the bar
    translate(barLength / 2 + 20, 0, 0); // Translate further along Z-axis
    fill(255);
    textAlign(LEFT, CENTER);
    textSize(24);
    text("Z", 0, 0); // Label for Z-axis
    popMatrix();

    // Draw labels for X and Y axes
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(24);
    text("X", -220, 0); // Label for X-axis
    text("Y", 0, barLength + 20); // Label for Y-axis
    //popMatrix();
/*
  //Draw X-axis bar starting from the origin
    fill(0, 255, 255, 200); // Red color
    pushMatrix();
    translate(-(temp*4/2), 0, 0); // Translate along X-axis by half the bar length
    box(temp*4, 10, 10); // X-axis is 200 units long
    popMatrix();
    
    // Draw Y-axis bar starting from the origin
    fill(255, 255, 0, 200); // Green color
    pushMatrix();
    rotateZ(HALF_PI); // Rotate 90 degrees to align with Y-axis
    translate(temp*4 / 2, 0, 0); // Translate along Y-axis by half the bar length
    box(temp*4, 10, 10); // Y-axis is 200 units long
    popMatrix();
    
    // Draw Z-axis bar starting from the origin
    fill(255, 255, 255, 200); // Blue color
    pushMatrix();
    rotateY(HALF_PI); // Rotate 90 degrees to align with Z-axis
    translate(temp*4 / 2, 0, 0); // Translate along Z-axis by half the bar length
    box(temp*4, 10, 10); // Z-axis is 200 units long
    // Draw Z label at the end of the bar
    translate(temp / 2 + 20, 0, 0); // Translate further along Z-axis
    fill(255);
    textAlign(LEFT, CENTER);
    textSize(24);
    text("Z", 0, 0); // Label for Z-axis
    popMatrix();

    // Draw labels for X and Y axes
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(24);
    text("X", -220, 0); // Label for X-axis
    text("Y", 0,temp + 20); // Label for Y-axis
    //popMatrix();*/
    //Value of distance
    //pushMatrix();
    fill(255);
    textAlign(LEFT, TOP);
    textSize(48);
    text(temp, -300, -300); // Label for Distance
    popMatrix();
    // draw front-facing tip in blue
    //fill(255, 255, 0, 200);
    //pushMatrix();
    //translate(0, 0, -120);
    //rotateX(PI/2);
    //drawCylinder(0, 20, 20, 8);
    //popMatrix();
    
    // draw wings and tail fin in green
    //fill(0, 255, 0, 200);
    //beginShape(TRIANGLES);
    //vertex(-100,  2, 30); vertex(0,  2, -80); vertex(100,  2, 30);  // wing top layer
    //vertex(-100, -2, 30); vertex(0, -2, -80); vertex(100, -2, 30);  // wing bottom layer
    //vertex(-2, 0, 98); vertex(-2, -30, 98); vertex(-2, 0, 70);  // tail left layer
    //vertex( 2, 0, 98); vertex( 2, -30, 98); vertex( 2, 0, 70);  // tail right layer
    //endShape();
    //beginShape(QUADS);
    //vertex(-100, 2, 30); vertex(-100, -2, 30); vertex(  0, -2, -80); vertex(  0, 2, -80);
    //vertex( 100, 2, 30); vertex( 100, -2, 30); vertex(  0, -2, -80); vertex(  0, 2, -80);
    //vertex(-100, 2, 30); vertex(-100, -2, 30); vertex(100, -2,  30); vertex(100, 2,  30);
    //vertex(-2,   0, 98); vertex(2,   0, 98); vertex(2, -30, 98); vertex(-2, -30, 98);
    //vertex(-2,   0, 98); vertex(2,   0, 98); vertex(2,   0, 70); vertex(-2,   0, 70);
    //vertex(-2, -30, 98); vertex(2, -30, 98); vertex(2,   0, 70); vertex(-2,   0, 70);
    //endShape();
    
    //popMatrix();
}

void serialEvent(Serial port) {
    interval = millis();
    while (port.available() > 0) {
        int ch = port.read();

        if (synced == 0 && ch != '$') return;   // initial synchronization - also used to resync/realign if needed
        synced = 1;
        //print ((char)ch);

        if ((serialCount == 1 && ch != 2)
            || (serialCount == 16 && ch != '\r')
            || (serialCount == 17 && ch != '\n'))  {
            serialCount = 0;
            synced = 0;
            return;
        }

        if (serialCount > 0 || ch == '$') {
            teapotPacket[serialCount++] = (char)ch;
            if (serialCount == 18) {
                serialCount = 0; // restart packet byte position
                
                // get quaternion from data packet
                q[0] = ((teapotPacket[2] << 8) | teapotPacket[3]) / 16384.0f;
                q[1] = ((teapotPacket[4] << 8) | teapotPacket[5]) / 16384.0f;
                q[2] = ((teapotPacket[6] << 8) | teapotPacket[7]) / 16384.0f;
                q[3] = ((teapotPacket[8] << 8) | teapotPacket[9]) / 16384.0f;
                for (int i = 0; i < 4; i++) if (q[i] >= 2) q[i] = -4 + q[i];
                
                // set our toxilibs quaternion to new data
                quat.set(q[0], q[1], q[2], q[3]);
                temp = Float.intBitsToFloat((teapotPacket[10]) | (teapotPacket[11] << 8) | (teapotPacket[12] << 16) |(teapotPacket[13] << 24));
                //float reconstructedFloatValue = Float.intBitsToFloat(temp);
                println(temp);
                //for(int i=10;i<14;i++)
                //{
                //  println((int)teapotPacket[i]);  
                //}
                /*
                // below calculations unnecessary for orientation only using toxilibs
                
                // calculate gravity vector
                gravity[0] = 2 * (q[1]*q[3] - q[0]*q[2]);
                gravity[1] = 2 * (q[0]*q[1] + q[2]*q[3]);
                gravity[2] = q[0]*q[0] - q[1]*q[1] - q[2]*q[2] + q[3]*q[3];
    
                // calculate Euler angles
                euler[0] = atan2(2*q[1]*q[2] - 2*q[0]*q[3], 2*q[0]*q[0] + 2*q[1]*q[1] - 1);
                euler[1] = -asin(2*q[1]*q[3] + 2*q[0]*q[2]);
                euler[2] = atan2(2*q[2]*q[3] - 2*q[0]*q[1], 2*q[0]*q[0] + 2*q[3]*q[3] - 1);
    
                // calculate yaw/pitch/roll angles
                ypr[0] = atan2(2*q[1]*q[2] - 2*q[0]*q[3], 2*q[0]*q[0] + 2*q[1]*q[1] - 1);
                ypr[1] = atan(gravity[0] / sqrt(gravity[1]*gravity[1] + gravity[2]*gravity[2]));
                ypr[2] = atan(gravity[1] / sqrt(gravity[0]*gravity[0] + gravity[2]*gravity[2]));
    
                // output various components for debugging
                //println("q:\t" + round(q[0]*100.0f)/100.0f + "\t" + round(q[1]*100.0f)/100.0f + "\t" + round(q[2]*100.0f)/100.0f + "\t" + round(q[3]*100.0f)/100.0f);
                //println("euler:\t" + euler[0]*180.0f/PI + "\t" + euler[1]*180.0f/PI + "\t" + euler[2]*180.0f/PI);
                //println("ypr:\t" + ypr[0]*180.0f/PI + "\t" + ypr[1]*180.0f/PI + "\t" + ypr[2]*180.0f/PI);
                */
            }
        }
    }
}
