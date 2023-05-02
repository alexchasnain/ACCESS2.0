#ifndef _SERIAL_H
#define _SERIAL_H

#include <Arduino.h>
#include "motors.h"
#include "heaters.h"


#define BAUD 115200

extern char delim;
extern int delayPrint; // delay interval between print statements
extern long init_time;

extern boolean fluo_connected;

void setupSerial();

void read_serial();
void parse_input();
void parse_split(int cmd_num);
/*
 * SERIAL COMMAND LIST
 * 
 *    temp1                 -- read incubation heater thermistor
 *    temp2                 -- read PCR heater thermistor
 *    t1(*temp*,*hold*)     -- sets temperature of incubation heat block to *temp* for *hold* seconds, turns off heaters after hold
 *    t2(*temp*,*hold*)     --  *                     *PCR heat block *             *               *           *
 *    fan(*heater*,*1/0*)   -- switch fan 1 (BIS)
 *    
 *    x*pos*                -- moves actuator carriage stepper motor
 *    y*pos*                -- moves mirror detector stepper motor
 *    z*pos*                -- moves Z servo
 *    
 *    stats                 -- 
 *    top                   -- 
 *    mid                   -- 
 *    bottom                -- 
 *    w
 *    
 *    mag                   -- moves magnetic beads through all wells using magTransfer()
 *    
 *    *** d = Detector ***
 *    d               -- calls detect function in eselog.cpp to take and report a measurement
 *    scan          -- calls scanY() in motors.cpp to detect fluorescence in all wells
 *    calibrate     -- scans fluorescence in in small Y increments and returns values
 *    reset

 *    pcr(float annealTemp, int annealTime, float denatureTemp, int denatureTime, int N, float hotsTime, boolean detect);
 *    
 */

#endif
