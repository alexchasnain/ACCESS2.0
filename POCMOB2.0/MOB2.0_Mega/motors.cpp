#include "motors.h"

Servo servo;  // scan mirror
Servo zAxis;  // swap magnets
Adafruit_MotorShield AFMS = Adafruit_MotorShield(); // Create the motor shield object with the default I2C address
Adafruit_StepperMotor *xAxis;
Adafruit_DCMotor *fanPCR;
Adafruit_DCMotor *fanBC;

int yWells_n = 4;
int ztop = 1210; 
int zbottom = 1760; 
int zmiddle = (ztop + zbottom) / 2;

int x_pos = 0; // 0 corresponds to magnet arm all the way back against limit switch
int z_pos = zmiddle;


// Well positions (add each preceeding well number to get to designated well from starting position)
int x_1a = 0; // sample
int x_1b = 50; // sulphonation and deamination
int x_2 = 60; // wash 1
int x_3 = 47; // desulphonation
int x_4 = 47; // wash 2
int x_5 = 47; // wash 3
int x_6 = 55; // PCR
int xWells[7] = {x_1a, x_1a+x_1b, x_1a+x_1b+x_2, x_1a+x_1b+x_2+x_3, x_1a+x_1b+x_2+x_3+x_4, x_1a+x_1b+x_2+x_3+x_4+x_5, x_1a+x_1b+x_2+x_3+x_4+x_5+x_6};


void setupMotors() {
  xWells[0] = x_1a;
  AFMS.begin();

  xAxis = AFMS.getStepper(stepsPerRev, xStepperPort);
  xAxis->setSpeed(xStepperRPM);

  fanPCR = AFMS.getMotor(fanPCR_port);
  fanBC = AFMS.getMotor(fanBC_port);
  fanPCR->setSpeed(255);
  fanBC->setSpeed(255);

  pinMode(zServoPin, OUTPUT);
//  pinMode(yServoPin, OUTPUT);
  pinMode(limitPin, INPUT_PULLUP);  // Reads High when switch not pressed

//  moveW(1); // moves to x_1b
  resetX();
}


void moveZ(int pos, int steps, int hold_time) {
  moveServo(1, z_pos, pos, steps, hold_time);
}

void moveY(int pos, int steps, int hold_time) {
  moveServo(2, y_pos, pos, steps, hold_time);
}

Servo s;
int pin;
void moveServo(int servo_n, int start, int finish, int steps, int hold_time){
  
  // check if values make sense - return if not
  if(servo_n >2 || servo_n<1 || start <700 || start > 2500 || finish <700 || finish > 2500 || hold_time <0 || steps <0 || steps >2000) return;

  // Attach appropriate servo

  if(servo_n == 1){       // mag servo
    pin = zServoPin;
    z_pos = finish;
  }
  else if(servo_n == 2){  // fluo servo
    pin = yServoPin;
//    y_pos = finish;
  }
  
  s.attach(pin);

  // set step size polarity
  int span = abs(finish - start);
  int dstep = steps;
  if(finish-start <0) dstep = -dstep;
  int currentPos = start;

  if (servo_n == 1){ // mag servo
    s.writeMicroseconds(finish);
    delay(1000);
  }
  else if (servo_n == 2){ // fluo servo
    for(int i = 0; i <= span; i+=steps){
      currentPos += dstep;
      if(abs(currentPos - start) > span) currentPos = finish;
      s.writeMicroseconds(currentPos);
      delay(20);
      //Serial.println(currentPos);
    }
  }
  
  delay(hold_time);
  s.detach();
}


void moveW(int well) {
  int steps = xWells[well] - x_pos;
  moveStepper( steps, 1);

}


void moveStepper(int steps, int mode) {
  if(steps+x_pos > 350 || steps+x_pos <0){ return;} // past length of chip
  if (mode == 1) {
    if (steps > 0) {
      xAxis->step(steps, FORWARD, MICROSTEP);
//      for (int i > 0; i <= steps; i = i+steps/3) {           
//        xAxis->step(steps, FORWARD, MICROSTEP);
//      } 
    }
    else {
      xAxis->step(-steps, BACKWARD, MICROSTEP);
    }
  }
  if (mode == 2) {
    if (steps > 0) {
      xAxis->step(steps, FORWARD, DOUBLE);
    }
    else {
      xAxis->step(-steps, BACKWARD, DOUBLE);
    }
  }
  x_pos += steps;
  xAxis->release();  // release all coils to allow stepper to spin freely
}

void resetX() {

  // Move mag arm to neutral condition
  moveZ(zmiddle,5,1000);

  // Move mag arm to limit switch
  int counter = 0;

  // Go back to limit switch -- Fast
  while (digitalRead(limitPin) == 1 && counter < xWells[6]) {
    counter++;
    xAxis->step(1, BACKWARD, DOUBLE);
    delay(10);
  }

  // Move to release limit switch
  while (digitalRead(limitPin) == 0) {
    counter++;
    xAxis->step(1, FORWARD, MICROSTEP);
    delay(100);
  }

  // Move back to limit switch slowly
  while (digitalRead(limitPin) == 1) {
    counter++;
    xAxis->step(1, BACKWARD, MICROSTEP);
    delay(100);
  }
  
  x_pos = 0;
  xAxis->release();

  Serial.println(F("Magnetic arm calibrated"));
}


void magTransfer(boolean delays) {
  //resetX();
  // collect from 1st well
  moveZ(zbottom,1,1000);
  moveStepper(x_1b, 1);
  moveZ(ztop,5,5000);

  //move to wash 1
  moveStepper(x_2,1);
  moveZ(zbottom,5,5000);

  //move to desulphonation
  moveZ(ztop,5,5000);
  moveStepper(x_3,1);
  moveZ(zbottom,5,5000);
  moveZ(zmiddle,5,1000);

  //wait for desulphonation
  if(delays){
    delay(60*10*1000); // ten minutes
  }

  // move to wash 2
  moveZ(ztop,5,5000);
  moveStepper(x_4,1);
  moveZ(zbottom,5,5000);

  //move to wash 3
  moveZ(ztop,5,5000);
  moveStepper(x_5,1);
  moveZ(zbottom,5,5000);

  //move to PCR
  moveZ(ztop,5,5000);
  moveStepper(x_6,1);
  moveZ(zbottom,5,5000);

  // elute DNA into PCR
  moveZ(zmiddle,5,1000);
  setTemp(2, 60, 3*60, 1, 0); // print output with no detection - 3 min 60C

  // Remove beads from PCR
  moveZ(ztop,5,5000);
  moveStepper(-x_6,1);

}


void fan_toggle(int fan, boolean state){
  if(fan == 1){
    if(state) fanBC->run(FORWARD);
    else fanBC->run(RELEASE);
  }
  else if(fan ==2){
    if(state) fanPCR->run(FORWARD);
    else fanPCR->run(RELEASE);
  }
}
