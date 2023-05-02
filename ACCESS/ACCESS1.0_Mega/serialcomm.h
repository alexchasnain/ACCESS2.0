#ifndef _SERIALCOMM_H
#define _SERIALCOMM_H

#include <Arduino.h>
#include "motors.h"
#include "eselog.h"
#include "heater.h"


#define BAUD 115200

extern char delim;
extern long init_time;

extern boolean fluo_connected;

void setupSerialcomm();

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

 *    cycle(float annealTemp, int annealTime, float denatureTemp, int denatureTime, int N, float hotsTime, boolean detect);
 *    
 */

#endif
