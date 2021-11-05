#!/usr/bin/python3
import string, time, sys
import serial 
import RPi.GPIO as GPIO
import threading
from threading import Thread, Event
from queue import Queue
import os
import json
from pathlib import Path


GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)

# Serial communication
global ser, IO_queue, stop_signal, ard_data, SENDING


# Run at beginning of cmd_parse.py
class init_nano_thread(threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)
    def run(self):
        global ser, IO_queue, stop_signal, SENDING
    
        GPIO.setup(_pin_RESET,GPIO.OUT)
        
        #ser = serial.Serial('/dev/ttyUSB0',57600,timeout=0.5)  # used for USB connection      
        
        SENDING = False
        # Reset arduino with pin and setup properties
        resetArd()
        
        print("Arduino Connected!")

def init_nano():
    settings.init_status = "Setting up Arduino Nano..."
    nthread =  init_nano_thread()
    nthread.start()
    return nthread

def resetArd():
    global ser

    try: 
        #ser = serial.Serial('/dev/ttyS0',57600,timeout=0.5) # used for direct TX/RX pin connection
        ser = serial.Serial('/dev/ttyUSB1',57600,timeout=0.5)  # used for USB connection
    except serial.serialutil.SerialException:
        print('Serial already connected')
        pass
    
    time.sleep(0.5) 
    #flush serial
    ser.read(100)
        
    #reset Arduino
    ser.write("<reset>".encode('utf-8'))
    print("Initializing Arduino nano...")

    #Arduino nano prints "<NANO-MOTOR-READY>" until Pi echoes "<PI-READY>"
    echo = ser.readline().decode('utf-8',errors='replace')
    print("waiting for nano response...",echo)
    while echo != "<NANO-MOTOR-READY>\r\n":
        ser.write("<reset>".encode('utf-8'))
        time.sleep(1)
        echo = ser.readline().decode('utf-8',errors='replace')
        print("waiting for nano motor response...",echo)

    ser.write("<PI-READY>".encode('utf-8'))


def ardRead(msg):
    msg_in =  ser.readline().decode('utf-8',errors='replace')
    if msg_in != "":
        print('RECEIVED FROM NANO: ', msg_in[:-2])
        ardSend(msg_in[:-2])
   
    match = (msg_in == (msg + "\r\n"))
    
    return match
    
def ardSend(cmd, override = False):
    global ser, SENDING
    if SENDING: 
        print("WARNING: motor.py ardSend - Attempt to send ", cmd, "prevented due SENDING flag.")
        return False # Don't allow attempts at communication when already sending a message
    
    SENDING = True
    ser.read(100)
    strcmd = str(cmd)
    
    # add <> to either end + \r\n + encode to byte
    bcmd = ("<" + strcmd + ">\r\n").encode('utf-8')
    
    # while echo doesn't match sent command -- try resending 3 more times
    echo = ""
    count = 0
    while echo != strcmd and count < 3:
        # write to serial
        ser.write(bcmd)
        time.sleep(0.2)
        # read echo
        while echo == "":
            echo_raw = ser.readline()       
            echo = echo_raw.decode('utf-8')
        
        # remove \r\n
        echo = echo[:-2]
        
        count+=1
        if count >= 3:
            SENDING = False
            return False
    print(echo)
    SENDING = False
    return True

def ardFlush():
    global ser
    ser.read(100)
