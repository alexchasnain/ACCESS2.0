#ifndef _HEATER_H
#define _HEATER_H

#include <Arduino.h>  // needed for compiling with digitalWrite() function
#include "motors.h"
#include "serialcomm.h"
#include "DualVNH5019MotorShield.h"
#include <Adafruit_MotorShield.h> // Adafruit_motorshield V2 https://learn.adafruit.com/adafruit-motor-shield-v2-for-arduino

// Pin out
#define thermistorR0Pin A8 // thermistors' reference
#define thermistorBSCRxPin A9 // sample thermistor
#define thermistorPCRRxPin A10 // PCR thermistor
#define blueLEDPin 9 // blue LED
#define redLEDPin 10 // red LED

// Delay interval
#define delayPID 50 // delay interval for PID update 

// Temperature control (PID) Parameters
extern float Kp;
extern float Kd;
extern float Ki;

// MOB Parameters (degC, s)
extern int sdTemp; // Sample Digestion (30 degC, 45 min)
extern int sdTime;
extern int idTemp; // Initial Denaturation (98 degC, 8 min)
extern int idTime;
extern int sadTemp; // Sulphonation and Deamination (58 degC, 1 hr)
extern int sadTime;
extern int bbTemp; // Bead Binding (25 degC, 10 min)
extern int bbTime;
extern int desTemp; // Desulphonation (25 degC, 15 min)
extern int desTime;
extern int eluTemp; // Elution (70 degC, 10 min)
extern int eluTime;
extern int phsTemp; // PCR Hot Start (103 degC, 20 s)
extern int phsTime;
extern int paTemp; // PCR Annealing (60 degC, 15 s)
extern int paTime;
extern int pdTemp; // PCR Denaturation (103 degC, 5 s)
extern int pdTime;
extern int cycleNum; // Cycle Number

// LED Parameters
extern boolean FAMChannel;
extern boolean CY5Channel;
extern int blueLEDPWM;
extern int redLEDPWM;
extern int LEDState;


void setupHeaters();

void stopIfFault();

double readTemp(int heater); // returns thermistors' temperatures (heater = 1 for sample; heater = 2 for PCR)

void setTemp(int heater, float setPoint, float hold_time, boolean detect_flag);

void bisCon();

void cycle(); 

void melt(); 

#endif
