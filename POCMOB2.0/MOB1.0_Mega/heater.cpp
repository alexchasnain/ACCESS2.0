#include "heater.h"
int temp_cal_flag = 0;
long outputPWM;
static int fluo_delay = 600;
static int max_temp = 110;     // max temperature allowed at TEC
static int overshoot = 0;      // temperature above/below target to accelerate heating/cooling
static int overshoot_time = 0; // time overshoot temp is held (seconds)
//float temp_coeff_BIS[2] = {1,0};
//float temp_coeff_PCR[2] = {1.1,-4.08}; // taken from mobiNAAT PCR box calibration

DualVNH5019MotorShield md;

void setupHeaters() {

  Serial.print("Initializing Dual VNH5019 Motor Shield...");
  md.init();
  Serial.println("Done.");

}

void stopIfFault()
{
  if (md.getM1Fault())
  {
    Serial.println("M1 fault");
    while (1);
  }
  if (md.getM2Fault())
  {
    Serial.println("M2 fault");
    while (1);
  }
}

//Temperature monitoring function
int VR0_raw;
int VRx_raw;
int VS_raw = 1023;
double Vout;
double R0 = 14000;  // known resistors = 14 kOhm
double Rx;

double thermistor(int heater) {
  // Measures temperature using Steinhart-Hart equation
  VR0_raw = analogRead(therm_R0pin);

  if (heater == 1) { // incubation block
    VRx_raw = analogRead(thermBC_RXpin);
  }
  else if ( heater == 2) {
    VRx_raw = analogRead(thermPCR_RXpin);
  }

  else {
    return -1;
  }

  Vout = VR0_raw - VRx_raw;

  Rx = (R0 * (0.5 - Vout / VS_raw)) / (0.5 + Vout / VS_raw);

  double temp = steinhart(Rx);
  return temp;
}

double steinhart(double resist) {
  resist = log(resist);
  double temp;
  
//  Steinhart constants 100 kOhm thermistor
  double vA = .8269925494 *.001; 
  double vB = 2.088185118 *.0001; 
  double vC = .8054469376 * .0000001; 
  
//  Steinhart constants 14 kOhm thermistor 
//  double vA = 0.1717716662 * 0.001;
//  double vB = 3.409385616 * 0.0001;
//  double vC = -2.321026751 * 0.0000001;

  temp = 1 / (vA + (vB + (vC * resist * resist )) * resist ) - 273.15;
  return temp;
}

void setTemp(int heater, float setPoint, float hold_time, boolean pFlag, boolean dFlag) {

  hold_time = hold_time * 1000; // convert sec to msec

  // Toggle Pins on/off
  if (heater == 1) {
    // Bisulfite conversion heater
    md.setM2Speed(0); // pcr = off
    fan_toggle(2,false);
  }
  else if (heater == 2) {
    // PCR heater
    md.setM1Speed(0); // bis = off
    fan_toggle(1,false);
  }
  else return;

  // Initialize flags for tracking state of temperature setting
  boolean detect_done = !dFlag;   // dFlag = true -- set detect_done to false
  boolean hold_done = false;
  boolean temp_set = false;
  long time_tracker = 0;
  long start_time;
  long print_time = millis();

  float currentTemp = 0;
  float previousError = 0;
  float integralError = 0;
  float derivative = 0;
  float error = 0;

  int wells_tracker = 0;
  int steps_tracker = 0;

  float fluos[4];
  boolean detecting = false;

  while (!hold_done || !detect_done) {
    // IMPLEMENT PID //
    currentTemp = thermistor(heater);
    error = setPoint - currentTemp;        //Error is positive when heating and negative while cooling
    derivative =  error - previousError;   //Derivative is negative while heating and positive while cooling
    integralError = constrain (integralError + error,-1e6,1e6); 
    previousError = error;

    outputPWM = constrain (Kp * error + Ki * integralError + Kd * derivative,-300,400);
    // Overheat protection and ramping power adjustments: outputPWM override //
    if (currentTemp>max_temp) outputPWM = 0;       // Overheat protection set at max temp static variable   
    if (error<-5 && derivative<0.1) outputPWM=0;   // Overheat protection while rapidly cooling by verifying derivative near inflection point. If cooling exceeds TEC capacity, use passive cooling
    if (setPoint>90 && error >1) outputPWM=400;    // Override output to full power when heating to high temperature
    if(heater == 1) md.setM1Speed(outputPWM); 
    else if(heater == 2) md.setM2Speed(outputPWM);
    
    // UPDATE TIME //
    if (abs(currentTemp - setPoint) < 1 && !temp_set) {
      temp_set = true;
      start_time = millis();
    }

    if (temp_set && !hold_done) {
      time_tracker = millis() - start_time;
      if (time_tracker > hold_time) {
        hold_done = true;
        start_time = millis(); // set start_time for detection
      }
    }

    // Turn off fan for heating and stabilization, turn on when ramping down
    if(error <-3){
      fan_toggle(heater,true);
    }else{
      fan_toggle(heater,false);
    }

    if (pFlag && millis() - print_time >= PRINT_INT) {
      print_time += PRINT_INT;
      Serial.println(""); // newline
      Serial.print(print_time / 1000.0);
      Serial.print(delim);
      Serial.print(currentTemp);
//      Serial.print(delim);
//      Serial.print(outputPWM);
//      Serial.print(delim);
//      Serial.print(error);
//      Serial.print(delim);
//      Serial.print(integralError);
      //Serial.print(md.getM1CurrentMilliamps());
      //      Serial.print(derivative*1000);
      
    }
    
    // Detection after hold -- assuming mirror starts at initialized position completely off the wells
    // Needs to run in while loop to maintain temperature throughout detection
    if (hold_done && dFlag) {

      if (wells_tracker == 4 && !detecting) { // detection done condition --> move carriage back and end function
        moveY(yWells[0],5,100);

        Serial.print('\n');
        Serial.print("Fluo");      
        Serial.print(delim);
        for ( int i = 0; i < 4; i++) {
          Serial.print(fluos[i]);
          Serial.print(delim);
        }
        detect_done = true; // DONE FULL ROUTINE
      }

      // MODE == 0 --  move mirror to next well
      else if (wells_tracker < 4 && !detecting) {
        moveY(yWells[wells_tracker + 1],5,100);
        detecting = true;
        start_time = -1; // initialize time tracker for waiting after detection measurement called
        wells_tracker++;
      }

      // MODE == 1 -- send detect signal to eselog -- hold for detect delay
      else if (detecting) {
        if (start_time < 0) { // Detection not called yet
          detect_snd();
          start_time = millis();
        }
        // read and record fluorescence
        else if (millis() - start_time > 1000) // detect_delay)
        {
          detect_rcv(0);
          fluos[wells_tracker - 1] = num_buffer;
          detecting = false;
        }
        // if all wells measured -- print out measurements -- detect_done
      }
    }


    delay(delayTime); // time interval for PID update
  }
  // Turn off current
  fan_toggle(heater,false);
  md.setM1Speed(0);
  md.setM2Speed(0);
  
}

void bisCon(int digTemp, float digTime, int denTemp, float denTime, int conTemp, float conTime, int bindTemp, float bindTime) {
  setTemp(1, digTemp, digTime * 60, 1, 0); // times are input in minutes --> convert to sec for setTemp(int heater, float setPoint, float hold_time, boolean pFlag, boolean dFlag)
  setTemp(1, denTemp, denTime * 60, 1, 0);
  setTemp(1, conTemp, conTime * 60, 1, 0);
  setTemp(1, bindTemp, bindTime * 60, 1, 0);
}


void cycle(int annealTemp, int annealTime, int denatureTemp, int denatureTime, int N, int hotsTime, boolean detect) {
  // First cycle is hotstart -- if not hotstart --> hotsTime == denatureTime
  setTemp(2, denatureTemp + overshoot, overshoot_time, 1, 0); // overshoot temp for 1 sec to compensate lag in PCR heating
  setTemp(2, denatureTemp, hotsTime, 1, 0); // hotstart


  for ( int i = 0; i < N; i++) {
    setTemp(2, denatureTemp + overshoot, overshoot_time, 1, 0);
    setTemp(2, denatureTemp, denatureTime, 1, 0);
    setTemp(2, annealTemp - overshoot, overshoot_time, 1, 0);
    setTemp(2, annealTemp, annealTime, 1, detect);
    Serial.print("Cycle"); //Print out
    Serial.print(delim);   
    Serial.print(i+1);
    
  }
  
}

void melt() {
  // melt
  Serial.println("Melt Start");
  setTemp(2,98,30,1,0);
  for(int annealTemp = 60; annealTemp <90; annealTemp++) {
    Serial.println(""); // newline  
    Serial.print (annealTemp);
    Serial.print(delim);
    setTemp(2, annealTemp, 1, 1, 1);
  }
  Serial.println("Melt done");
}
