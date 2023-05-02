#ifndef _MOTORS_H
#define _MOTORS_H

#include <Servo.h>
#include <Arduino.h>
#include <Adafruit_MotorShield.h> // Adafruit_motorshield V2 https://learn.adafruit.com/adafruit-motor-shield-v2-for-arduino
#include "utility/Adafruit_MS_PWMServoDriver.h"

#include "eselog.h"
#include "heater.h"

#define zServoPin 44  // magnets
#define yServoPin 45 // fluo servo
#define limitPin 43  // limit switch -- contact = detect HIGH

// Port definitions for Adafruit motorshield
#define xStepperPort 1    // X = actuator carriage  --> move magnets between wells
#define xStepperRPM 100
#define stepsPerRev 200
#define fanBC_port 3
#define fanPCR_port 4

extern int zbottom;
extern int ztop;
extern int zmiddle;

extern int x_step;          // X step size between wells
extern int x_inletstep;     // X step from sample inlet to 1st well
extern int x_PCRstep;       // X step from last well to PCR well
extern int x_totalstep;     // X step from end to end

extern Adafruit_MotorShield AFMS; // Create the motor shield object with the default I2C address
extern Adafruit_StepperMotor *xAxis;  // wells axis
extern Adafruit_DCMotor *fanPCR;
extern Adafruit_DCMotor *fanBC;
extern int yWells[];
extern int yWells_n;

void setupMotors();

void moveW(int well);

void moveZ(int pos, int steps, int hold_time);

void moveY(int pos, int steps, int hold_time);

void moveServo(int servo_n,int start, int finish, int steps, int hold_time);

void resetX();

void magTransfer(boolean delays);

void moveStepper(int steps, int mode);  
// positive steps = FORWARD, negative steps = BACKWARD
// uses DOUBLE (2 coils activated at once for higher torque)
// other options:   INTERLEAVE = alternate single and double coils for twice resolution (1/2 speed)
//                  MICROSTEP = coils are PWM'd to create smooth motion between steps

void scanY();   
void calibrate(); 

void fan_toggle(int fan, boolean state);

#endif
