#!/usr/bin/python3

'''
  Example frame:

    <CMDFxy[1,2,3];2>!

    '<'           start of frame
    "CMD"         command
    'F'           flag
    "xy"          token
    "[1,2,3];2"   args
    '>'           end of frame
    '!'           checksum
'''

import queue
import time
from time import sleep
import tkinter as tk
import threading
import sys
import os

# PROMPT Libraries 
import cam
import motor
import temp

# Command queue
command_queue = queue.Queue()
status = "IDLE"

# Identify valid command
def parse(inputValue): 
    START_BYTE  = '<'
    END_BYTE    = '>'
    MSG_LEN     = len(inputValue)
    ARGS        = ""
    if (MSG_LEN < 2 ):
        print("Serial Message Length Error")
    elif (inputValue[0] != START_BYTE or inputValue[MSG_LEN-1] != END_BYTE):
        print("Serial Message Error, Lost Data", inputValue[0], inputValue[MSG_LEN-1], inputValue)
    else:
      ARGS = inputValue[1:MSG_LEN-1]
    return ARGS

# interpret argument and send command accordingly
def Arg_interpret(argValue):
    global ser
    args = []
    if argValue == "pic":
        cam.take_pic()
    elif argValue == "cam on":
        cam.show_preview(0,50,1648//3,1232//3)
    elif argValue == "cam off":
        cam.stop_preview()
    elif argValue == "fan on":
        temp.FANon()
    elif argValue == "fan off":
        temp.FANoff()
    elif argValue.find("temp(") == 0:  
        parseArgs(args, argValue)
        print("args0 = ",args[0])
        print("Heatblock ", args[0]," Temp: ",temp.steinhart(args[0]))
    elif argValue == "hb on":
        #nano.HBon()
        pass
    elif argValue == "hb off":
        #nano.HBoff()
        pass
    elif argValue.find("t1(") == 0:       
        parseArgs(args, argValue)
        print("args0 = ",args[0])
        print("args1 = ",args[1])
        #temp.setTempThread(1, args[0], args[1])

    elif argValue.find("t2(") == 0:       
        parseArgs(args, argValue)
        print("args0 = ",args[0])
        print("args1 = ",args[1])
        #temp.setTempThread(2, args[0], args[1])

    elif argValue.find("cycle")==0: 
        temp.cycle() 

    elif argValue.find("LEDon") ==0:
        # Use LEDon(1) for channel 1 led
        if len(argValue) <6:
            return
        parseArgs(args, argValue)
        if(temp.LEDon(args[0])):
            print("LED On - ", args[0])
        
    elif argValue.find("LEDoff") == 0: 
        temp.LEDoff()
        
    elif argValue.find("blp(") == 0: 
        parseArgs(args, argValue)
        temp.setBLED(args[0])
    elif argValue.find("rlp(") == 0: 
        parseArgs(args, argValue)
        temp.setRLED(args[0])
    elif argValue.find("quit") == 0:
        temp.resetArd()
        sys.exit()
    elif argValue.find("reset")==0:
        temp.resetArd()
        time.sleep(2)
    
# Parse command into arguments
def parseArgs(ARGS_LIST,inputValue,start_token = '(',end_token = ')', sep_token = ','):
    # Example for string input = melt(60,90,50)
    START_BYTE  = start_token  # ex: (
    END_BYTE    = end_token    #
    ARG_SEP     = sep_token
    MSG_LEN     = len(inputValue)
    ARGS_LEN     = MSG_LEN -2
    ARGS_START  = inputValue.find(START_BYTE)+1
    ARGS_END    = MSG_LEN
    #ARGS_LIST   = []
    CMD         = ""

    if (MSG_LEN < 2):
        print("Serial Message Length Error")
    elif (inputValue[ARGS_START-1] != START_BYTE or inputValue[MSG_LEN-1] != END_BYTE):
        print("Serial Message Error, Lost Data", inputValue[ARGS_START-1], inputValue[MSG_LEN-1], inputValue)
    else:
        CMD = inputValue[0:ARGS_START] 
        if ARGS_LEN > 0:
            ARGS_NUM = inputValue.count(ARG_SEP)
            ARG_FIN = ARGS_START
            for i in range(0, ARGS_NUM+1):
                  if i < ARGS_NUM:
                    ARG_base = inputValue[ARG_FIN:ARGS_END].find(ARG_SEP)
                    ARGS_LIST.append(inputValue[ARG_FIN : ARG_base + ARG_FIN])
                    ARG_FIN = ARG_base + ARG_FIN + 1
                  else:
                    ARG_base = inputValue[ARG_FIN:ARGS_END].find(END_BYTE)
                    ARGS_LIST.append(inputValue[ARG_FIN : ARG_base + ARG_FIN])
    return ARGS_LIST, CMD
   
def execute_cmd():
    global command_queue
    
    """ Running things at background. """
    while True:
        if command_queue.empty() is False:
            command = command_queue.get()
            print (command)
            Arg_interpret(parse(command))
            #time.sleep(0.5)
        else:
            if settings.status != "Setting up test...":
                settings.status = "IDLE"
            #settings.root.after(1000, self.update_data) 
        
#-----------------------------------------------------------------------

if __name__ == "__main__":
    # occurs only if module is run directly
    temp.init_temp()   
    #motor.init_motor()
    cam.init_cam()

    while True:
       userInput = input("Command:\n")
       Arg_interpret(userInput)