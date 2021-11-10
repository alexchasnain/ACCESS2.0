#ifndef _MOTORS_H
#define _MOTORS_H

#include <Servo.h>
#include "BasicStepperDriver.h"
#include "A4988.h"

// Servo Motor for magnet arm
#define servoPin 3

// Motor steps per revolution. Most steppers are 200 steps or 1.8 degrees/step
#define MOTOR_STEPS 200

// Stepper 1 
#define DIR_1 6
#define STEP_1 7
#define ENABLE_1 12 

//
#define DIR_2 8
#define STEP_2 9
#define ENABLE_2 13 

// Acceleration and deceleration values are always in FULL steps / s^2
#define MOTOR_ACCEL 1000
#define MOTOR_DECEL 1000

// Limit switches
/*
 *    switch is opens when pressed --> using pull-up resistor (INPUT_PULLUP) this changes digitalRead value to HIGH 
 */
#define LIMIT_1 4
#define LIMIT_2 5
     
extern A4988 stepper_1;
extern A4988 stepper_2;
extern int RPM;
void setupMotors();
void moveStepper(A4988 stepper, long rev);
void moveStepper(A4988 stepper, long rev, int microsteps);
void moveServo(int servo_n,int start, int finish, int steps, int hold_time);
void init1();
void init2();

#endif
