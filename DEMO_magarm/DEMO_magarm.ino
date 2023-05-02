#include "motors.h"

/*
 * Pin out:
 * 
 *  A0   
 *  A1   
 *  A2
 *  A3
 *  A4    
 *  A5    
 *  
 *  0-  RX
 *  1-  TX
 *  2-   
 *  3~  Servo  
 *  4-  LIMIT_X
 *  5~  LIMIT_Z
 *  6~  DIR_X
 *  7   STEP_X
 *  8   DIR_Z
 *  9~  STEP_Z
 *  10~  
 *  11~ 
 *  12  SLEEP_X  
 *  13  SLEEP_Z  
 * 
 */


void setup() {
     setupMotors();
}

void loop() {
    // int start = 1700; 
    // int end = 1800; 

    // moveServo(1, start, end, 20, 10); // PCR 1
    // delay(1000);
    // moveServo(1, end, start, 20, 10); // PCR 1
    // delay(1000);

    /*
    SERVO: 
         10 = 1 degree
         upper limit: 2300
         lower limit: 500
         
    TEST RIG LIMITS(wrt top magnet)
        back of platform: 2300
        front of platform: 1450

    Top magnet:
        SAMPLE: 1650
        WASH: 1940
        PCR1: 2190
        PCR2: 2250

    Bottom magnet:
        SAMPLE:
        WASH: 1710
        PCR1: 1910
        PCR2: 1990
    */

    int mag_pos = 2300; 
    int target = 2250; 

    moveServo(1, 1750, 1940, 1, 30); // SAMPLE -> WASH 
    delay(3000);
    for(int i=0; i<3; i++){
        moveServo(1, 1940, 1710, 50, 10);
        delay(4000);
        moveServo(1, 1710, 1940, 50, 10);
        delay(1000);
    } // 3x wash
    delay(1000);

    moveServo(1, 1940, 2190, 1, 30); // PCR 1
    delay(1000);
    moveServo(1, 2190, 1910, 50, 10); 
    delay(3000);
    moveServo(1, 1940, 2190, 50, 30); 
    delay(1000);

    moveServo(1, 2190, 2250, 1, 30); // PCR 2
    delay(1000);
    moveServo(1, 2250, 1990, 50, 10); 
    delay(3000);
    moveServo(1, 1990, 2250, 50, 30); 
    delay(3000);

    moveServo(1, 2250, 1940, 1, 30);
    delay(1000);
    moveServo(1, 1940, 1710, 50, 10);


    delay(100000000);
}
