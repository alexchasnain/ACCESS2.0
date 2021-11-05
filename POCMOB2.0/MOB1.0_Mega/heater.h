#ifndef _HEATER_H
#define _HEATER_H

#include <Arduino.h>  // needed for compiling with digitalWrite() function
#include "eselog.h"
#include "motors.h"
#include "serialcomm.h"
#include "DualVNH5019MotorShield.h"
#include <Adafruit_MotorShield.h> // Adafruit_motorshield V2 https://learn.adafruit.com/adafruit-motor-shield-v2-for-arduino

#define therm_R0pin A8 // incubation temperature probe
#define thermBC_RXpin A9
#define thermPCR_RXpin A10 // PCR temperature probe

#define PRINT_INT 500   // delay interval between print statements

// Set parameters for PID controller used in cycling
const float Kp = 200;   //Original 200, outputPWM max 11700, min -8000
const float Kd = 1;  // Original 1   
const float Ki = 0.02; //Original 0.02
const int delayTime = 50;

void setupHeaters();

void stopIfFault();

double thermistor(int heater); 
/* returns temperature of thermistor probe 
    Heater = 1 --> incubation block (therm1)
    Heater = 2 --> PCR block (therm2)
*/
double steinhart(double resist);

void setTemp(int heater, float setPoint, float hold_time, boolean pFlag, boolean dFlag);
// pFlag = true --> continuously print state
// dFlag = true --> hold and detect fluorescence at end

void bisCon(int digTemp, float digTime,int denTemp, float denTime, int conTemp, float conTime, int bindTemp, float bindTime);
/*
 *  dig = digestion of sample
 *  den = denaturation of DNA
 *  con = sulfonation and deamination
 *  bind = particle binding
 */

void cycle(int annealTemp, int annealTime, int denatureTemp, int denatureTime, int N, int hotsTime, boolean detect);
// Runs 'N' cycles with first cycle held at denatureTemp for hotsTime (seconds)
// All temperatures given in °C and all times in seconds
// Boolean 'detect' = true --> at end of each annealTime fluorescence of each well is measured

void melt();
//Melt scan


#endif
