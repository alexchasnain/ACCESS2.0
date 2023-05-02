#include "heaters.h"

// Temperature PID controller parameters
float Kp = 200;   //Original 200, outputPWM max 11700, min -8000
float Kd = 1;  // Original 1   
float Ki = 0.02; //Original 0.02

// MOB parameters (degC, s)
int sdTemp = 30; // Sample Digestion (30 degC, 45 min)
int sdTime = 2700;
int idTemp = 98; // Initial Denaturation (98 degC, 8 min)
int idTime = 480;
int sadTemp = 58; // Sulphonation and Deamination (58 degC, 1 hr)
int sadTime = 3600;
int wmTemp = 98; // Wax Melting (X degC, X min)
int wmTime = 60;
int bbTemp = 25; // Bead Binding (25 degC, 10 min)
int bbTime = 600;
int desTemp = 25; // Desulphonation (25 degC, 15 min)
int desTime = 15;
int eluTemp = 70; // Elution (70 degC, 10 min)
int eluTime = 10;
int phsTemp = 103; // PCR Hot Start (103 degC, 20 s)
int phsTime = 20;
int paTemp = 60; // PCR Annealing (60 degC, 15 s) 
int paTime = 15;
int pdTemp = 103; // PCR Denaturation (103 degC, 5 s)
int pdTime = 5;
int cycleNum = 40; // Cycle Number

// LED parameters
int blueLEDPWM = 0;
int redLEDPWM = 0;
int LEDState = 0;
boolean FAMChannel = true;
boolean CY5Channel = true;

// PWM parameters
int maxPWM = 400;
int minPWM = -300;
long outputPWM = 0;

String temp;

int temp_cal_flag = 0;
//long outputPWM;
static int fluo_delay = 600;
static int max_temp = 110;     // max temperature allowed for TECs
static int overshoot = 0;      // temperature above/below target to accelerate heating/cooling
static int overshoot_time = 0; // time overshoot temp is held (seconds)

DualVNH5019MotorShield md;


void setupHeaters() {
  Serial.print("Initializing Dual VNH5019 Motor Shield and LEDs...");
  md.init();
  
  pinMode(blueLEDPin, OUTPUT);
  pinMode(redLEDPin, OUTPUT);
  analogWrite(blueLEDPin, 255);
  analogWrite(redLEDPin, 255);
  
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


// Temperature monitoring function 
double readTemp(int heater) { 
  double VR0_raw = analogRead(thermistorR0Pin);
  double VRx_raw;
  double VS_raw = 1023;
  double R0 = 14000;  // known resistors = 14 kOhm

  // Choosing thermistor to read pin voltage
  if (heater == 1) { // BSC heater
    VRx_raw = analogRead(thermistorBSCRxPin);
  }
  else if ( heater == 2) { // PCR heater
    VRx_raw = analogRead(thermistorPCRRxPin);
  }
  else if ( heater == 3) { // WM heater (Channels 1-2, "right side")
    VRx_raw = analogRead(thermistorWMRRxPin);
  }
  else if ( heater == 4) { // WM heater (Channels 3-4, "left side")
    VRx_raw = analogRead(thermistorWMLRxPin);
  }
  else {
    return -1;
  }

  double Vout = VR0_raw - VRx_raw;
  double Rx = (R0 * (0.5 - Vout / VS_raw)) / (0.5 + Vout / VS_raw);
  logRx = log(Rx);
  
  // Steinhart-Hart coefficients 100 kOhm thermistor
  double vA = .8269925494 *.001; 
  double vB = 2.088185118 *.0001; 
  double vC = .8054469376 * .0000001;   
//  // Steinhart-Hart coefficients 14 kOhm thermistor 
//  double vA = 0.1717716662 * 0.001;
//  double vB = 3.409385616 * 0.0001;
//  double vC = -2.321026751 * 0.0000001;

  double temp = 1 / (vA + (vB + (vC * logRx * logRx )) * logRx ) - 273.15;
  return temp;
}


// Temperature setting function
void setTemp(int heater, float setPoint, float holdTime, boolean detectFlag) {
  // Choosing sample/PCR heater by toggling pins on/off
  if (heater == 1) { // sample heater
    md.setM2Speed(0); // pcr = off
    fan_toggle(2,false);
  }
  else if (heater == 2) { // PCR heater
    md.setM1Speed(0); // bis = off
    fan_toggle(1,false);
  }
  else return;

  // Initialize flags for monitoring temperature, LED state, picture-taking, and time
  boolean setTempDone = false;
  boolean tempReached = false;
  boolean FAMPic = detectFlag && FAMChannel;
  boolean CY5Pic = detectFlag && CY5Channel;
  boolean takingPic = false;
  float startTime;
  float print_time = millis();
  holdTime *= 1000; // convert s to ms

  // Initialize PID variables
  float currentTemp = 0;
  float previousError = 0;
  float integralError = 0;
  float derivative = 0;
  float error = 0;

  while (!setTempDone) {
    // Calculate PID for output PWM
    currentTemp = readTemp(heater);
    error = setPoint - currentTemp;        //Error is positive when heating and negative while cooling
    derivative =  error - previousError;   //Derivative is negative while heating and positive while cooling
    integralError = constrain (integralError + error,-1e6,1e6); 
    previousError = error;
    outputPWM = constrain (Kp * error + Ki * integralError + Kd * derivative,minPWM,maxPWM);
    
    // Overheat protection and ramping power adjustments: PID override and further PWM modifiers
    if (currentTemp>max_temp) outputPWM = 0;       // Overheat protection set at max temp static variable   
    if (error<-5 && derivative<0.1) outputPWM=0;   // Overheat protection while rapidly cooling by verifying if derivative is near inflection point. If cooling exceeds TEC capacity, use passive cooling
    if (setPoint>90 && error>1) outputPWM=maxPWM;    // Override output to full power when heating to high temperature
    
    // Set heater to output PWM
    if(heater == 1) md.setM1Speed(outputPWM); 
    else if(heater == 2) md.setM2Speed(outputPWM);
    
    // Update time (timer starts counting down)
    if (!tempReached && abs(error) < 1) { // if target temp hasn't been reached yet, check if it's within threshold
      startTime = millis();  // set timer
      tempReached = true;        // target temp reached 
      //Serial.print(F("\t Target temp reached."));
    }

    // Turn off fan for heating and incubation and turn on for cooling
    if(error <-3){
      fan_toggle(heater,true);
    }else{
      fan_toggle(heater,false);
    }
    
    // Print/log time and temperature values in realtime 
    if (millis() - print_time >= delayPrint) {
      print_time += delayPrint;
      Serial.print("T,"); // indicates time/temp measurement for Pi logging
      Serial.print((print_time - init_time) / 1000.0);
      Serial.print(",");
      Serial.println(currentTemp);
//      Serial.print(",");
//      Serial.print(outputPWM);
//      Serial.print(",");
//      Serial.print(error);
//      Serial.print(",");
//      Serial.print(integralError);
    }
    
    // End temperature hold when timer runs out and pictures have been taken
    if (tempReached == true && (millis() - startTime) > holdTime) {
      //Serial.println(F("\t Hold temp complete."));
      if(takingPic){
        input(false);
        // Pi will send a "P" when the picture *has been taken*
        if(message == "P"){
          takingPic = false;
          //Turn off LEDs
          analogWrite(redLEDPin, 255);
          analogWrite(blueLEDPin, 255);
          LEDState = 0;
          message = "";
        }  
      }
      else if(FAMPic){
        takingPic = true;
        analogWrite(redLEDPin, 255);
        analogWrite(blueLEDPin, blueLEDPWM);
        LEDState = 1;
        Serial.println("PB"); 
        FAMPic = false;     
      }
      else if(CY5Pic){
        takingPic = true;
        analogWrite(blueLEDPin, 255);
        analogWrite(redLEDPin, redLEDPWM);
        LEDState = 2;
        Serial.println("PR"); 
        CY5Pic = false;  
      }
      else{
        setTempDone = true;  // Temperature reached, held long enough time, pictures taken
        digitalWrite(fanPin,LOW);
        analogWrite(OUT1Pin, 0);
        analogWrite(OUT2Pin, 0);
      }      
    }
    delay(delayPID); // delay interval for PID update
  }
  
  // Turn off current
  fan_toggle(heater,false);
  md.setM1Speed(0);
  md.setM2Speed(0);
}


void bsc() {
  init_time = millis();  
  // Sample Digestion
  if(sdTime > 0.01){
    Serial.println("L,Sample Digestion,START");
    setTemp(1,sdTemp, sdTime, false);
    Serial.println("L,Sample Digestion, END");
  }
  // Initial Denaturation
  if(idTime > 0.01){
    Serial.println("L,Initial Denaturation,START");
    setTemp(1,idTemp, idTime, false);
    Serial.println("L,Initial Denaturation, END");
  }
  // Sulphonation and Deamination
  if(sadTime > 0.01){
    Serial.println("L,Sulphonation and Deamination,START");
    setTemp(1,sadTemp, sadTime, false);
    Serial.println("L,Sulphonation and Deamination, END");
  }
  // Bead Binding
  if(bbTime > 0.01){
    Serial.println("L,Bead Binding,START");
    setTemp(1,bbTemp, bbTime, false);
    Serial.println("L,Bead Binding, END");
  }
}


void wm(){
  init_time = millis();  
  // Sample Digestion
  if(wmTime > 0.01){
    Serial.println("L,Wax Melting,START");
    setTemp(3,wmTemp, wmTime, false);
    setTemp(4,wmTemp, wmTime, false);
    Serial.println("L,Wax Melting, END");
  }
}


void pcr(){
  init_time = millis();  
  // Elution
  if(eluTime > 0.01){
    Serial.println("L,Elution,START");
    setTemp(2,eluTemp, eluTime, false);
    Serial.println("L,Elution, END");
  }
  // PCR Hot Start
  if(phsTime > 0.01){
    Serial.println("L,Hot Start,START");
    setTemp(2,phsTemp, phsTime, false);
    Serial.println("L,Hot Start, END");
  }
  // PCR Thermocycling
  // Print "C" at the beginning of each cycle followed by # of cycle - example: C,1 = cycle 1
  if(cycleNum > 0){
    Serial.println("L,Cycling,START");
    for(int i = 0; i<cycleNum; i++){
       Serial.print("C,");
       Serial.println(i+1);
       
       Serial.print("L,Denature,"); // PCR Denaturation
       Serial.println(i+1);
       setTemp(2,pdTemp, pdTime, false);

       Serial.print("L,Anneal,"); // PCR Annealing
       Serial.println(i+1);
       setTemp(2,paTemp, paTime, FAMChannel || CY5Channel);
    }  
    Serial.println("L,Cycling,END");
  }
  Serial.println("E"); 
}
