/*
 * Pin out:
 * 
 *  A0    MD - current sensing 1
 *  A1    MD - current sensing 2
 *  A2
 *  A3
 *  A4    SDA motorshield - control stepper motor, fans   
 *  A5    SCL motorshield
 *  A6
 *  A7
 *  A8    thermistorR0Pin
 *  A9    thermistorBSCRxPin
 *  A10   thermistorPCRRxPin
 *  A11   thermistorWMRRxPin
 *  A12   thermistorWMLRxPin
 *  
 *  0     Serial RX
 *  1     Serial TX
 *  2~    MD - M1INA
 *  3~    
 *  4~    MD - M1INB
 *  5~    USB Shield - INT (cut default connection - added jumper to board)
 *  6~    MD - M1EN/DIAG
 *  7~    MD - M2INA
 *  8~    MD - M2INB
 *  9~    MD - M1PWM (USB Shield - default INT)
 *  10~   MD - M2PWM (USB Shield - default SS)
 *  11~   USB Shield - SS *cut default connection - added jumper to board*
 *  12~   M2EN/DIAG
 *  13~   
 *  
 *  17      HC-05 state pin (high if connected)
 *  18(TX1) Serial1 to bluetooth receiver HC-05 RX
 *  19(RX1) Serial1 to bluetooth receiver HC-05 TX
 *  20      HC-05 Enable pin
 *  
 *  43    Limit switch pin (Input-Pullup)
 *  44~   Mag (Z) Servo PWM
 *  45~   
 *  46~   
 * 
 *  50    USB Shield - MISO
 *  51    USB Shield - MOSI
 *  52    USB Shield - SCK
 *  53    USB Shield - SS
 * 
 *  See docs for motordriver here: https://www.pololu.com/docs/0J49/3.c
 */

#include <Adafruit_MotorShield.h> // Adafruit_motorshield V2
#include "utility/Adafruit_MS_PWMServoDriver.h"
#include "serial.h"
#include "heaters.h"
#include "motors.h"

void setup() {
  setupSerial();
  setupHeaters();
  delay(1000);
  setupMotors();
  Serial.println("<Arduino is ready>");
}

void loop() {
  read_serial();
  parse_input();
}
