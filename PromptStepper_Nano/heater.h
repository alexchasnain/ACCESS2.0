#ifndef _HEATER_H
#define _HEATER_H

#include "serial.h"

// Use TB9051FTG Single Brushed DC Motor Driver https://www.pololu.com/product/2997 to operate TEC
#define fanPin 4
#define OUT1Pin 5 // forward driving current (heating)
#define OUT2Pin 6 // reverse driving current (cooling)
#define BLEDPin 9
#define RLEDPin 10
#define R0Pin A0
#define RxPin A1

#define interval 25

// PID Parameters
extern float Kp;
extern float Kd;
extern float Ki;

// Cycle Parameters
extern int rt_temp; // Reverse Transcription
extern int rt_time;
extern int hs_temp; // Hot Start
extern int hs_time;
extern int an_temp; // Annealing
extern int an_time;
extern int de_temp; // Denature
extern int de_time;
extern int cycle_num;

extern boolean FAM_CHANNEL;
extern boolean CY5_CHANNEL;

// LED Parameters
extern int BLED_PWM;
extern int RLED_PWM;
extern int LED_STATE;

void setupHeater();

double readTemp();
void setTemp(float setPoint, float hold_time);
void setTemp(float setPoint, float hold_time, boolean detect);
void cycle();

#endif
