#include "eselog.h"
String strbuff; // buffer to temporarily hold strings
String rcvbuff; // buffer to hold received strings
uint8_t rcode = 0;
double num_buffer = 0;  // holds processed output from ESELog
uint8_t  buf[64];   // store received message from ESELog
uint16_t rcvd = 64; // number of bytes received into buf

double onval_buff;  // contains measurements for reading fluorescence with methods 1-7
double offval_buff;

int method_type = 8; // Stores method type setting for fluorescence detection
/*
    1 = E1D1
    2 = E1D2
    3 = E2D2
    4 = E1D1+E1D2
    5 = E1D1+E2D2
    6 = E1D2+E2D2
    7 = E1D1 + E1D2 + E2D2
    8 = S_E1D1 // default
    9 = S_E1D2
    10 = S_E2D2
*/
int led1_current = 200; // 165; // 
int led1_on_delay = 300;
int led1_off_delay = 300;
int led2_current = 200;
int led2_on_delay = 300;
int led2_off_delay = 300;

int detect_delay = led1_on_delay + led1_off_delay;

uint8_t FTDIAsync::OnInit(FTDI *pftdi)
{
  rcode = 0;

  rcode = pftdi->SetBaudRate(57600);

  if (rcode)
  {
    ErrorMessage<uint8_t>(PSTR("SetBaudRate"), rcode);
    return rcode;
  }
  rcode = pftdi->SetFlowControl(FTDI_SIO_DISABLE_FLOW_CTRL);

  if (rcode)
    ErrorMessage<uint8_t>(PSTR("SetFlowControl"), rcode);

  return rcode;
}

USB              Usb;
FTDIAsync        FtdiAsync;
FTDI             Ftdi(&Usb, &FtdiAsync);
void setupEselog() {
  if (Usb.Init() == -1){ 
    Serial.println("Could not initialize USB.");
  }
  else {
    int timeout = 5000;
    int wait_start = millis();
    while (Usb.getUsbTaskState() != USB_STATE_RUNNING && millis() - wait_start < timeout) {
      Usb.Task();
    }
    if (millis() - wait_start > timeout) Serial.println("ESELog Not Detected.");
    else {
      
      strbuff = F(":000600000001f9");    // write, cycles, 1
      rcode = modbus(strbuff);
      //check_rcode(rcode);
      
      if(!rcvbuff.substring(0,rcvbuff.length()-2).equals(strbuff)){   // remove "/n" from echo
          for(int i = 0; i<5; i++){
            strbuff = F(":000600000001f9");    // write, cycles, 1
            rcode = modbus(strbuff);
            
            if(rcvbuff.substring(0,rcvbuff.length()-2).equals(strbuff)) break;
          }
          
          Serial.println("ESELog Not Connected");
          return;
      }
 

      strbuff = F(":000600030800ef");    // write, method_type, 8
      rcode = modbus(strbuff);

      strbuff = F(":00060018c8001a");    // write, led1_current, 200 //  strbuff = F(":00060018a5003d"); //write new led1_current, 165 //
      rcode = modbus(strbuff);
      //check_rcode(rcode);

      strbuff = F(":00060019c80019");    // write, led2_current, 200
      rcode = modbus(strbuff);

      strbuff = F(":00060014012cb9");    // write, led1_on_delay, 300
      rcode = modbus(strbuff);

      strbuff = F(":00060016012cb7");    // write, led1_off_delay, 300
      rcode = modbus(strbuff);

      strbuff = F(":00060015012cb8");    // write, led2_on_delay, 300
      rcode = modbus(strbuff);

      strbuff = F(":00060017012cb6");    // write, led2_off_delay, 300
      rcode = modbus(strbuff);
      
      fluo_connected = true;
      Serial.println("ESELog Connected");
    }
  }

}

void detect () {
  if(!fluo_connected){
    delay(led1_on_delay + led1_off_delay + 100); 
    return;
  }
  detect_snd(); 
  delay(led1_on_delay + led1_off_delay + 100);  // delay time it takes to gather a measurement
  detect_rcv(true);
}

void detect_silent () {
  if(!fluo_connected){
    delay(led1_on_delay + led1_off_delay + 100); 
    return;
  }
  detect_snd(); 
  delay(led1_on_delay + led1_off_delay + 100);  // delay time it takes to gather a measurement
  detect_rcv(false);
}

void detect_snd() {
  // Measure fluorescence using current method_type -- follow with call to detect_rcv to read output
  //Usb.Task();
  //Serial.print("USB Running.");
  strbuff = F(":000602000001f7");  //"write,start_mode,1"
  rcode = modbus(strbuff);
  //check_rcode(rcode);
}

void detect_rcv(boolean pFlag) {
  // E1D1 -- read from onval1, offval1
  if (method_type == 1 || (method_type >= 4 && method_type <= 7 && method_type != 6)) {
    strbuff = F(":000301040002f6"); // "read,260" -- on value 1
    rcode = modbus(strbuff);
    //check_rcode(rcode);
    onval_buff = num_buffer;

    strbuff = F(":0003010a0002f0"); // "read,266" -- off value 1
    rcode  = modbus(strbuff);
    //check_rcode(rcode);
    offval_buff = num_buffer;

    num_buffer = onval_buff - offval_buff;
    // PRINT FLUORESCENCE MEASUREMENT
    if (pFlag) {
      Serial.print(num_buffer);
      Serial.print(delim);
    }
  }

  // E1D2 -- read from onval2, offval2
  if (method_type == 2 || (method_type >= 4 && method_type <= 7 && method_type != 5)) {
    strbuff = F(":000301060002f4");
    rcode = modbus(strbuff);  // "read, 262" -- on value 2
    //check_rcode(rcode);
    onval_buff = num_buffer;

    strbuff = F(":0003010c0002ee");
    rcode = modbus(strbuff); // "read,268" -- off value 2
    //check_rcode(rcode);
    offval_buff = num_buffer;

    num_buffer = onval_buff - offval_buff;
    if (pFlag) {
      Serial.print(num_buffer);
      Serial.print(delim);
    }
  }

  // E2D2 -- read from onval3, offval3
  if (method_type == 3 || (method_type >= 5 && method_type <= 7)) {
    strbuff = F(":000301080002f2"); // "read,264" -- off val 3
    rcode = modbus(strbuff);
    //check_rcode(rcode);
    onval_buff = num_buffer;

    strbuff = F(":0003010e0002ec"); // "read,270" -- off val 3
    rcode = modbus(strbuff);
    //check_rcode(rcode);
    offval_buff = num_buffer;

    num_buffer = onval_buff - offval_buff;
    if (pFlag) {
      Serial.print(num_buffer);
      Serial.print(delim);
    }
  }
  //S_E1D1 -- read from 513
  else if (method_type >= 8) {
    strbuff = F(":000302010002f8"); // "read,513" -- Datapoint 1
    rcode = modbus(strbuff);
    //check_rcode(rcode);
    if (pFlag) {
      Serial.print(num_buffer);
      Serial.print(delim);
    }
  }


}


void check_rcode(uint8_t rcode) {
  if (rcode)
    ErrorMessage<uint8_t>(PSTR("SndData"), rcode);

  delay(50);

  for (uint8_t i = 0; i < 64; i++)
    buf[i] = 0;

  rcode = Ftdi.RcvData(&rcvd, buf);

  if (rcode && rcode != hrNAK)
    ErrorMessage<uint8_t>(PSTR("Ret"), rcode);

  // The device reserves the first two bytes of data
  //   to contain the current values of the modem and line status registers.
  if (rcvd > 2)
  {
    rcvbuff = String((char*)(buf + 2));
    rcvbuff.toLowerCase();
    num_buffer = read_interpret(rcvbuff);
  }
}

int addr;

uint8_t modbus(String message) {

  char modbus_code[] = ":000TXXXXXXXXCC\n\r";
  // primer for modbus instruction: e.g. T = 3 (read) or 6 (write)
  //char modbus_code[] =  ":000TXXXXXXXXCC\n\r";  // contains 18 characters (1 for ':', 14 for command, 2 for '\n\r' and 1 for null termination)
  addr = hexToDec(message.substring(5, 9));
  if (addr == 3) {
    method_type = hexToDec(message.substring(9, 11));
  }
  /*Serial.print("Address: \t");
    Serial.println(addr);
    Serial.print("Message length: ");
    Serial.println(message.length());
  */
  // Parsing read commands
  if (message.charAt(0) == ':' && message.length() == 15) {
    for (int i = 0; i < 15; i++) {
      modbus_code[i] = message.charAt(i);
    }
    rcode = Ftdi.SndData(strlen(modbus_code), (uint8_t*)modbus_code);
    delay(100);
    check_rcode(rcode);
    return rcode;
  }
  return (uint8_t*)"";
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

// MODBUS Rx interpreter
// If a register is read, the interpreter does one of the two things:
// For strings, the interpreter prints the message to serial buffer.
// For numerical values, the interpreter generates a correctly normalized
// value based on the register address.
double read_interpret(String message) {

  if (message.substring(0, 5) == ":0006") {
    //Serial.println(F("Write operation performed."));
    return -1;
  }
  else {
    int msg_size = hexToDec(message.substring(5, 7));
    message = message.substring(7, 7 + msg_size * 2);
    //truncate trailing zeroes in 1-byte values based on instruction (register address)
    if ((addr >= 2 && addr <= 6) || (addr >= 24 && addr <= 31) || (addr >= 164 && addr <= 165)) {
      message = message.substring(0, 2);
    }
    //int value = hexToDec(message);
    num_buffer = hexToDec(message);
    if (message.length() <= 8) {
      // some method of storing/returning numerical information
      //num_buffer = strToNum(value);
      if (addr == 258) num_buffer = ((num_buffer * 2500 / 8388607) - 54.3) / 0.205;   // read temp of ESELog

      else if (addr == 3) {
        method_type = num_buffer; // read method_type
        //Serial.println(method_type);
      }

      else if ((addr >= 260 && addr <= 399) || (addr >= 512 && addr <= 3513)) num_buffer = num_buffer * 2500 / 8388607; // convert to mV fluo. reading
    }

    else {
      //Serial.print("Line 514: ");
      Serial.println(hexToStr(message));
      // prints string to serial buffer
      return -2;
    }
    return num_buffer;
  }
}
