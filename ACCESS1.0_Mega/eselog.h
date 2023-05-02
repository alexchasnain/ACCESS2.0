#ifndef _ESELOG_H
#define _ESELOG_H

#include "serialcomm.h" // use for determining delimiter in print statements

// libraries used with USB comm -- USB Host Shield 2.0 (using USB Host Shield for Android ADK) 
//    UsbCore.h with modified SS and INT pin assignments to allow simultaneous use
//    of usb host shield and motorshield
#include <cdcftdi.h>
#include <usbhub.h>

#include <stdlib.h>

// Satisfy the IDE, which needs to see the include statment in the ino too.
#ifdef dobogusinclude
#include <spi4teensy3.h>
#include <SPI.h>
#endif

extern double num_buffer;
extern int method_type;

extern int detect_delay;

extern int led1_current;
extern int led1_on_delay;
extern int led1_off_delay;
extern int led2_current;
extern int led2_on_delay;
extern int led2_off_delay;

extern uint8_t rcode;

class FTDIAsync : public FTDIAsyncOper
{
  public:
    uint8_t OnInit(FTDI *pftdi);
};

void setupEselog();

void detect();
void detect_silent();
void detect_snd(); // uses current method_type to trigger and read a fluorescence reading
void detect_rcv(boolean pFlag);

void check_rcode(uint8_t rcode); // reads rcode -- receives output from ESELog and sends to read_interpret()

void write_eselog(String message);  // used in serialcomm.cpp to send modbus commands

uint8_t modbus(String message);     // prepares modbus message to send to ESELog -- calls check_rcode

void parseMsg(String args[], String message);   // takes in message as (read,addr) or (write,addr,data)

double read_interpret(String message);          // interprets data returned from ESELog 

String lrc_calc(char message[]);
String decToHex(int value, int write_size);
long hexToDec(String hexString);
String hexToStr(String hexString);

void cmd_register(int command[], String cmd);

#endif
