#include "serial.h"
#include "heater.h"

/*
 * Pin out:
 * 
 *  A0  R0Pin 
 *  A1  RxPin 
 *  A2
 *  A3
 *  A4    
 *  A5    
 *  
 *  0-  RX
 *  1-  TX
 *  2-   
 *  3~    
 *  4-  Fan switch
 *  5~  Heater OUT1Pin
 *  6~  Heater OUT2Pin
 *  7 
 *  8 
 *  9~  LED - Blue 
 *  10~ LED - Red
 *  11~ 
 *  12    
 *  13    
 * 
 */

void setup() {
  setupHeater();
  setupSerial();
}

void loop() {
  input(true); // reads input from Serial
  delay(1);
}
