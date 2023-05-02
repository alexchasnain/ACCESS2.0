#ifndef _SERIAL_H
#define _SERIAL_H

#include <Arduino.h>
#include <avr/wdt.h>
#include "motors.h"

/*
 * SERIAL COMMAND LIST
 *    
 */

#define BAUD 57600

extern HardwareSerial Serial;

extern double init_time;
extern char rc;
extern String message;
extern int time_int; 
extern boolean stopFlag;
extern boolean serial_read; 

void setupSerial();
void input(boolean interpretFlag);
void cmd_interpret(/*String message*/);
void parseArgs(double args[], String message);
void parseMsg(String args[], String message);

double strToNum(String str);
long hexToDec(String hexString);
String hexToStr(String hexString);
String decToHex(int value, int write_size);

#endif
