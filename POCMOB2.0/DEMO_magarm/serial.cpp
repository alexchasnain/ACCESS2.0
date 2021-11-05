#include "serial.h"
String code_version = "heater-module.ino - 20210710";

boolean serialOpen = false;

String timestamp;
int time_int = 100; // number of milliseconds between print statements
double init_time = millis(); // holds time at start of assay
double args[16];

static boolean recvInProgress = false;
char rc;
String message = "";
static byte ndx = 0;
char startMarker = '<';
char endMarker = '>';
boolean serial_read = false;

const int numChars = 64;
char serialCmd[numChars];
char cmdBuffer[numChars]; // temp holder in parse_input()
char tempChars[numChars]; // temp holder in parse_split()

void setupSerial(){

  Serial.begin(BAUD); // for Arduino troubleshooting
  delay(500);
  // Tell Pi serial connection is successful
  Serial.println("<NANO-MOTOR-READY>");
  
}

// Read input from Serial, output in String
void input(boolean interpretFlag) {

  while (Serial.available() > 0 && !serial_read) {
    rc = Serial.read();
    //Serial.println(rc);
    if (recvInProgress == true && rc != NULL) {
      if (rc != endMarker) {
        //message += rc;
        serialCmd[ndx] = rc;
        ndx++;
        if (ndx >= numChars) {
          ndx = numChars - 1;
        }
      }
      else {
        serialCmd[ndx] = '\0'; // terminate the string
        ndx = 0;
        recvInProgress = false;
        serial_read = true;
      }
    }
    else if (rc == startMarker) {
      recvInProgress = true;
      message = "";
    }
  }

  if (serial_read) {
    message = serialCmd;
    if (message == "reset") {
      setup();
    }
    else if (interpretFlag) {
      cmd_interpret();
    }
    serial_read = false;
  }
}

// Command line interpreter: parses strings into commands
void cmd_interpret() {
  //message.toLowerCase();
  Serial.println(message);

  char msg_char[22];  // character array for PROGMEM comparisons to save dynamic memory
  if (message.length() < 22) {
    message.toCharArray(msg_char, 22);
  }
  else {
    String msg = "null";
    msg.toCharArray(msg_char, 22);
  }
  // Version check
  if (message == "version") {
    Serial.println(code_version);
  }

  // RESET command
  else if (message == "reset") {
    Serial.end();
    delay(100);
    setup();
  }
  // MOTOR commands
  else if (message == "init1") {
    init1();
  }
  else if (message == "init2") {
    init2();
  }
  else if (message.substring(0, 3) == "s1(") {
    parseArgs(args, message);
    moveStepper(stepper_1, args[0],RPM);
  }
  else if (message.substring(0, 3) == "s2(") {
    parseArgs(args, message);
    moveStepper(stepper_2, args[0],RPM);
  }
  else if (message.substring(0, 4) == "rpm(") {
    parseArgs(args, message);
    RPM = args[0];
  }
}

// Argument parsing code: retrieves an int array containing arguments separated by commas
void parseArgs(double args[], String message) {
  String arg = "";
  char msg;
  int k = 0;
  for (int i = 0; i < message.length(); i++) {
    msg = message.charAt(i);
    arg += msg;
    if (msg == ')' || msg == ',' || msg == ';' || i == message.length() - 1) {
      args[k] = strToNum(arg); // convert argument into number and add to array
      arg = "";
      k++;
    }
  }
}

// String argument parsing code: retrieves a string array containing arguments separated by commas
void parseMsg(String args[], String message) {
  String arg = "";
  char msg;
  int k = 0;
  for (int i = 0; i < message.length(); i++) {
    msg = message.charAt(i);
    // if lowercase alphabet/underscore or number, add to argument
    if ((int(msg) <= 122 && int(msg) >= 95) || (int(msg) <= 57 && int(msg) >= 48)) {
      arg += msg;
    }
    if (msg == ')' || msg == ',' || msg == ';' || i == message.length() - 1) {
      args[k] = arg; // add argument to array
      k++;
      arg = "";
    }
  }
}

// converts string to number (handles below decimal points i.e. better than toInt())
double strToNum(String str) {
  double decValue = 0;
  int belowDec = 0;
  int nextInt;
  double mod = 1;
  int sign = 1;

  for (int i = 0; i < str.length(); i++) {
    if(str.charAt(i) == '-'){sign = -1; }
    nextInt = int(str.charAt(i));
    if (nextInt >= 48 && nextInt <= 57) {
      nextInt = map(nextInt, 48, 57, 0, 9);
      nextInt = constrain(nextInt, 0, 9);
      if (belowDec == 0) {
        decValue = (decValue * 10) + nextInt;
      }
      else {
        mod = mod * 0.1;
        decValue = decValue + nextInt * mod;
      }
    }

    if (nextInt == 46) {
      belowDec = 1;
    }

  }
  return decValue*sign;
}

// Hex to decimal converter
long hexToDec(String hexString) {
  long decValue = 0;
  int nextInt;

  for (int i = 0; i < hexString.length(); i++) {
    nextInt = int(hexString.charAt(i));
    if (nextInt >= 48 && nextInt <= 57) nextInt = map(nextInt, 48, 57, 0, 9);
    // Convert A-F to 10-15
    if (nextInt >= 65 && nextInt <= 70) nextInt = map(nextInt, 65, 70, 10, 15);
    if (nextInt >= 97 && nextInt <= 102) nextInt = map(nextInt, 97, 102, 10, 15);
    nextInt = constrain(nextInt, 0, 15);
    decValue = (decValue * 16) + nextInt;
  }
  return decValue;
}

// Hex to string converter (converts every two digits of HEX into one ASCII character)
String hexToStr(String hexString) {

  String strValue = "";
  long nextInt;

  for (int i = 0; i < hexString.length(); i = i + 2) {
    nextInt = hexToDec(hexString.substring(i, i + 2));
    strValue += char(nextInt);
  }
  return strValue;
}

// Decimal to hex converter (converts decimal values into hex of specified digit size (defualt: 4))
String decToHex(int value, int write_size) {
  String strValue = String(value, HEX);
  int zeros = write_size - strValue.length();
  for (int i = 0; i < zeros; i++) {
    strValue = "0" + strValue;
  }
  return strValue;
}
