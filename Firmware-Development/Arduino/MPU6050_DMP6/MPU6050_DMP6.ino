#include "I2Cdev.h"
#include "MPU6050_6Axis_MotionApps20.h"
#if I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE
    #include "Wire.h"
#endif

#define OUTPUT_TEAPOT
#define SOUND_SPEED 0.034   // Speed of Sound in Air in cm/us
#define CM_TO_INCH  0.393701 // 1 cm into inch
#define LED_PIN  2 // (Arduino is 13, Teensy is 11, Teensy++ is 6)
#define trigPin 17
#define echoPin 16

bool blinkState = false;
bool dmpReady = false;  // set true if DMP init was successful
uint8_t mpuIntStatus;   // holds actual interrupt status byte from MPU
uint8_t devStatus;      // return status after each device operation (0 = success, !0 = error)
uint16_t packetSize;    // expected DMP packet size (default is 42 bytes)
uint8_t fifoBuffer[64]; // FIFO storage buffer
long duration;
float distance = 52.0 ;

// packet structure for InvenSense teapot demo
uint8_t teapotPacket[18] = { '$', 0x02, 0,0, 0,0, 0,0, 0,0, 0,0,0,0, 0x00, 0x00, '\r', '\n' };

// Enum representing different states of the task
enum TaskState {
  Teapot,
  Ultrasonic,
};

MPU6050 mpu;
TaskState current_state = Teapot;

void setup() 
{
    #if I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE
        Wire.begin(21,22);
        Wire.setClock(400000);
    #elif I2CDEV_IMPLEMENTATION == I2CDEV_BUILTIN_FASTWIRE
        Fastwire::setup(400, true);
    #endif

    Serial.begin(115200);
    while (!Serial);
    mpu.initialize();
    Serial.println(F("\nSend any character to begin DMP programming and demo: "));
    while (!Serial.available());
    devStatus = mpu.dmpInitialize();
    mpu.setXGyroOffset(220);
    mpu.setYGyroOffset(76);
    mpu.setZGyroOffset(-85);
    mpu.setZAccelOffset(1788);

    if (devStatus == 0) 
    {
        mpu.CalibrateAccel(6);
        mpu.CalibrateGyro(6);
        mpu.setDMPEnabled(true);
        mpuIntStatus = mpu.getIntStatus();
        dmpReady = true;
        packetSize = mpu.dmpGetFIFOPacketSize();
    } 
    pinMode(LED_PIN, OUTPUT); 
    pinMode(trigPin, OUTPUT); 
    pinMode(echoPin, INPUT);
}

void loop() 
{
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  duration = pulseIn(echoPin, HIGH);
  // distance = (duration * SOUND_SPEED)/2.0;

  // Hardcoded values for distance in the sequence
  if (millis()<10000) 
  {
      distance--;
    
  }
  else if (millis() > 10000 && millis() < 15000) 
  {
      distance++;
  }
  else if (millis() > 20000 && millis() < 30000) 
  {
      distance--;
  }
  else if (millis() > 30000 && millis() < 40000) 
  {
      distance;
  }
  

  // End hardcoded


  Serial.print("\nDistance(cm): ");
  Serial.println(distance);
  if (!dmpReady) return;
  // read a packet from FIFO
  if (mpu.dmpGetCurrentFIFOPacket(fifoBuffer)) 
  {
    #ifdef OUTPUT_TEAPOT
    // display quaternion values in InvenSense Teapot demo format:
    teapotPacket[2]  = fifoBuffer[0];   // Quaternion W (W component)
    teapotPacket[3]  = fifoBuffer[1];   // Quaternion X (X component)
    teapotPacket[4]  = fifoBuffer[4];   // Quaternion Y (Y component)
    teapotPacket[5]  = fifoBuffer[5];   // Quaternion Z (Z component)
    teapotPacket[6]  = fifoBuffer[8];   // Gyro X
    teapotPacket[7]  = fifoBuffer[9];   // Gyro Y
    teapotPacket[8]  = fifoBuffer[12];  // Gyro Z
    teapotPacket[9]  = fifoBuffer[13];  // Accel X

    teapotPacket[10] = *((uint8_t*) (&distance));          // Distance byte 0
    teapotPacket[11] = *((uint8_t*) (&distance) + 1);      // Distance byte 1
    teapotPacket[12] = *((uint8_t*) (&distance) + 2);      // Distance byte 2
    teapotPacket[13] = *((uint8_t*) (&distance) + 3);      // Distance byte 3

    Serial.write(teapotPacket, 18);  // Send the entire packet via serial (18 bytes)

        teapotPacket[15]++; // packetCount, loops at 0xFF on purpose
    #endif
    // blink LED to indicate activity
    blinkState = !blinkState;
    digitalWrite(LED_PIN, blinkState);
  } 
  delay(80);
}