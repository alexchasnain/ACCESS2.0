#include "serialcomm.h"
/**********
    STATS
 **********/
String version_notes = "Version 1";

boolean fluo_connected = false;

boolean serial_read = false;
const byte numChars = 48;
char serialCmd[numChars];
char cmdBuffer[numChars]; // temp holder in parse_input()
char tempChars[numChars]; // temp holder in parse_split()

#define max_cmd_num 10
#define max_cmd_size 64
char *cmds[max_cmd_num];

int int_buffer;
float target_temp;

char delim = ','; // delimiter for output
int delayPrint = 100; // delay interval (ms) between print statements
long init_time;

void setupSerialcomm() {
  Serial.begin(BAUD);
  Serial.println("<Arduino Connected>");
  init_time = millis();
}

void read_serial() {
  // based on http://forum.arduino.cc/index.php?topic=396450.0
  // stores characters within serialCmd[numChars]
  // uses '<' and '>' as markers to start and end of cmds
  static boolean recvInProgress = false;
  static byte ndx = 0;
  char startMarker = '<';
  char endMarker = '>';
  char rc;

  while (Serial.available() > 0 && serial_read == false) {
    rc = Serial.read();
    //Serial.println(rc);
    if (recvInProgress == true) {
      if (rc != endMarker) {
        serialCmd[ndx] = rc;
        ndx++;
        if (ndx >= numChars) {
          ndx = numChars - 1;
        }
      }
      else {
        serialCmd[ndx] = '\0'; // terminate the string
        recvInProgress = false;
        ndx = 0;
        serial_read = true;
      }
    }
    else if (rc == startMarker) {
      recvInProgress = true;
    }
  }
}

void parse_input() {
  if (serial_read) {
    serial_read = false;
    //Serial.println("");

    Serial.println(serialCmd);  // Starts a new line and prints user input
    if ( strcmp(serialCmd, "stats") == 0) {
      // Print out current stats
      Serial.println(version_notes);
    }

    else if ( serialCmd[0] == 'y') {
      memcpy(&cmdBuffer[0], &serialCmd[1], 31); // cut off y
      int_buffer = atoi(cmdBuffer);
      moveY(int_buffer,5,500);
      Serial.print("Moving Y ");
      Serial.println(int_buffer);
    }

    else if ( serialCmd[0] == 'z') {
      memcpy(&cmdBuffer[0], &serialCmd[1], 31); // cut off x
      int_buffer = atoi(cmdBuffer);
      moveZ(int_buffer,5,500);
      Serial.print("Moving Z ");
      Serial.println(int_buffer);
    }

    else if ( strcmp(serialCmd, "top") == 0) {
      moveZ(ztop,5,500);
    }

    else if ( strcmp(serialCmd, "mid") == 0) {
      moveZ(zmiddle,5,500);
    }

    else if ( strcmp(serialCmd, "bottom") == 0) {
      moveZ(zbottom,5,500);
    }
    else if ( serialCmd[0] == 'x') {
      memcpy(&cmdBuffer[0], &serialCmd[1], 31); // cut off x
      int_buffer = atoi(cmdBuffer);
      moveStepper(int_buffer, 1);
      Serial.print("Moving X ");
      Serial.println(int_buffer);
    }
    else if ( serialCmd[0] == 'w') {
      memcpy(&cmdBuffer[0], &serialCmd[1], 31); // cut off x
      int_buffer = atoi(cmdBuffer);
      moveW(int_buffer);
      Serial.print("Moving to well: ");
      Serial.println(int_buffer);
    }
    else if ( strcmp(serialCmd, "scan") == 0) {
      scanY();
    }
    else if ( strcmp(serialCmd, "calibrate") == 0) {
      calibrate();
    }

    else if ( strcmp(serialCmd, "d") == 0) {
      detect();
      Serial.println("");
    }

    else if (strcmp(serialCmd, "temp1") == 0) {
      Serial.print("Inc. Heater Temp. =\t");
      Serial.println(readTemp(1));
    }
    else if (strcmp(serialCmd, "temp2") == 0) {
      Serial.print("PCR Heater Temp. =\t");
      Serial.println(readTemp(2));
    }

    // Call setTemp function with <t1(*temp*,*hold*)> or <t2(*temp*,*hold*)>
    else if ( serialCmd[0] == 't' && isDigit(serialCmd[1]) && serialCmd[2] == '(' && isDigit(serialCmd[3])) {
      int heater_num = serialCmd[1] - '0';
      memcpy(&cmdBuffer[0], &serialCmd[3], 29); // cut off first 't#_' -- memcpy(&dst[dstIdx],&src[srcIdx], numElementsToCopy)
      //Serial.println(cmdBuffer);
      parse_split(2); // reads cmdBuffer and splits into two integers for target temp and hold time

      target_temp = atof(cmds[0]); // convert char array to float
      int_buffer = atoi(cmds[1]); // convert char array to int

      target_temp = constrain(target_temp, 30, 120);
      Serial.print("Target Temp:\t");
      Serial.println(target_temp);
      Serial.print("Hold Time:\t");
      Serial.println(int_buffer);
      Serial.print("Heater num:\t");
      Serial.println(heater_num);
      Serial.println("*");  // use for start signal to Processing code for parsing data

      setTemp(heater_num, target_temp, int_buffer, 1, 0); // print output with no detection

      Serial.println("\n*");  // use for stop signal to Processing code for parsing data

    }

    else if (strcmp(serialCmd, "mag") == 0) {
      Serial.println('*');
      magTransfer(false);
      Serial.println("");
      Serial.println("\n*");
    }

    else if (strcmp(serialCmd, "reset") == 0) {
      resetX();
    }
    else if (strcmp(serialCmd, "limit") == 0) {
      Serial.println(digitalRead(limitPin));

    }
    else if (strcmp(serialCmd, "melt") == 0) {
      melt();
    }
    else if (serialCmd[0] == ':') {
      rcode = modbus(serialCmd);
      //Serial.println(num_buffer);
    }

    else if (serialCmd[0] == 'b' && serialCmd[6] == '(') { // bisCon(int digTemp, float digTime,int denTemp, float denTime, int conTemp, float conTime, int bindTemp, float bindTime);
      memcpy(&cmdBuffer[0], &serialCmd[7], 25);
      parse_split(8);
      Serial.println('*');
      bisCon(atoi(cmds[0]), atof(cmds[1]), atoi(cmds[2]), atof(cmds[3]), atoi(cmds[4]), atof(cmds[5]), atoi(cmds[6]), atof(cmds[7]));
      Serial.println("\n*");
    }

    else if (serialCmd[0] == 'c' && serialCmd[5] == '(') { // cycle(float annealTemp, int annealTime, float denatureTemp, int denatureTime, int N, float hotsTime, boolean detect);
      memcpy(&cmdBuffer[0], &serialCmd[6], 26);
      parse_split(7);
      Serial.println('*');
      cycle(atoi(cmds[0]), atoi(cmds[1]), atoi(cmds[2]), atoi(cmds[3]), atoi(cmds[4]), atoi(cmds[5]), atoi(cmds[6]));
      Serial.println("\n*");
    }

    else if (serialCmd[0] == 'f' && serialCmd[3] == '(') { 
      memcpy(&cmdBuffer[0], &serialCmd[4], 28);
      parse_split(2);
      Serial.print("Fan ");
      Serial.print(atoi(cmds[0]));
      Serial.print(":\t");
      if(atoi(cmds[1]) == 1){
        Serial.println("On");
      }else{
        Serial.println("Off"); 
      }
      fan_toggle(atoi(cmds[0]), atoi(cmds[1]));
    }

  }

}

// breaks up char array input into integers separated by commas -- updates into cmds[]
void parse_split(int cmd_num) {
  char *saveptr;  // pointer used by strtok_r as index
  strcpy(tempChars, cmdBuffer);
  cmds[0] = strtok_r(tempChars, ",)", &saveptr); // initiate parsing into tokens
  for (int i = 1; i < cmd_num; i++) {
    cmds[i] = strtok_r(NULL, ",)", &saveptr); // continues after initial call
    Serial.println(cmds[i]);
    //Serial.print("tempChars: ");
    //Serial.println(tempChars);
    delay(1); // added to allow proper parsing of all cmds -- drops last cmd without
  }

}
