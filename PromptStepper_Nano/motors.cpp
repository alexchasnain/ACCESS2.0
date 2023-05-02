#include "motors.h"
int motor_cal_flag = 0;

Servo magServo;  // magnetic arm
int mag_pos;
// Well positions for binding well, wash, PCR1, PCR 2
/*
 *  NEED TO CALIBRATE THESE POSITIONS ON INSTRUMENT
 */
int wells_top[] = {1200, 950, 675, 540};
int wells_bottom[] = {1200, 950, 675, 540};
int mag_reset = 1500;

A4988 stepper_1(MOTOR_STEPS, DIR_1, STEP_1, ENABLE_1);
A4988 stepper_2(MOTOR_STEPS, DIR_2, STEP_2, ENABLE_2);
int RPM = 100;

void setupMotors() {
  stepper_1.begin(RPM);
  stepper_2.begin(RPM);
  
  //stepper_X.setSpeedProfile(stepper_X.LINEAR_SPEED, MOTOR_ACCEL, MOTOR_DECEL);
  //stepper_Z.setSpeedProfile(stepper_Z.LINEAR_SPEED, MOTOR_ACCEL, MOTOR_DECEL);
  
  stepper_1.disable();
  stepper_2.disable();

  pinMode(LIMIT_1, INPUT_PULLUP); // HIGH when pressed
  pinMode(LIMIT_2, INPUT_PULLUP); // HIGH when pressed

  pinMode(servoPin, OUTPUT);
  mag_pos = mag_reset;
  /*Write to Servos before attaching to prevent start-up jitter*/
  magServo.writeMicroseconds(mag_pos); // move mag arm to neutral position
  magServo.attach(servoPin);
  delay(500);
  magServo.detach();
}

void moveStepper(A4988 stepper, long rev) {
  stepper.enable();
  Serial.print("Moving stepper ");
  Serial.println(rev);
  stepper.rotate(rev * 360);  // blocking command - use startRotate() for non-blocking
  stepper.disable();
}

void moveStepper(A4988 stepper, long rev, int rpm) {
  stepper.begin(rpm);
  stepper.enable();
  stepper.rotate(rev * 360);
  stepper.disable();
}

Servo s;
int pin;
void moveServo(int servo_n, int start, int finish, int steps, int hold_time) {

  /*
   *    servo_n == 1 --> magServo
   *      Other servo_n values left open for future integration of more servos if needed
   *    start   == assumed initial position of servo arm 
   *    finish  == targeted final position of servo arm
   *    steps   == increment/decrement magnitude for position -- controls speed of servo rotation
   *    hold_time == delay after servo has reached "finish" to hold at that position
   */
   
  //check if values make sense - return if not
  if (servo_n > 3 || servo_n < 1 || start < 500 || start > 2300 || finish < 500 || finish > 2300 || hold_time < 0 || steps < 0 || steps > 2000) return;

  // Attach appropriate servo
  if (servo_n == 1) {
    pin = servoPin;
    mag_pos = finish;
  }
  else if (servo_n == 2) {
//    pin = servoPin2;
//    mag_pos = finish;
  }
  else if (servo_n == 3) {
//    pin = servoPin3;
//    hb_pos = finish;
  }
  s.attach(pin);

  // set step size polarity
  int span = abs(finish - start);
  int dstep = steps;
  if (finish - start < 0) dstep = -dstep;
  int currentPos = start;

  for (int i = 0; i <= span; i += steps) {
    currentPos += dstep;
    if (abs(currentPos - start) > span) currentPos = finish;

    s.writeMicroseconds(currentPos);
    
    delay(40);
    //Serial.println(currentPos);
  }

  s.detach();
  delay(hold_time);
}

void init1(){
  Serial.print("Initializing stepper 1 (cartridge mount)...");
  long rev = 200;
  stepper_1.enable();
  stepper_1.startRotate(rev*360);
  while(digitalRead(LIMIT_1) != HIGH){
    // motor control loop - send pulse and return how long to wait until next pulse
    unsigned wait_time_micros = stepper_1.nextAction();
  }
  stepper_1.stop();
  stepper_1.disable();
  Serial.println("Done.");
}

void init2(){
  Serial.print("Initializing stepper 2...");
  long rev = -100;
  stepper_2.enable();
  stepper_2.startRotate(rev*360);
  while(digitalRead(LIMIT_2) != HIGH){
    // motor control loop - send pulse and return how long to wait until next pulse
    unsigned wait_time_micros = stepper_2.nextAction();
  }
  stepper_2.stop();
  stepper_2.disable();
  Serial.println("Done.");
}
