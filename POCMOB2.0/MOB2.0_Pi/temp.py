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
from datetime import datetime

# POCMOB2.0 Libraries
import cam


GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)

# Serial communication
global ser, IO_queue, stop_signal, ard_data, SENDING

# Time/temperature readings
global MEGA_TEMP, MEGA_TIME

# MOB parameters (degC, s)
global sdTemp, sdTime, idTemp, idTime, sadTemp, sadTime, wmTemp, wmTime, bbTemp, bbTime, desTemp, desTime,
    eluTemp, eluTime, phsTemp, phsTime, paTemp, paTime, pdTemp, pdTime, cycleNum
sd_temp = 30  # Sample Digestion (30 degC, 45 min)
sd_time = 2700
id_temp = 98  # Initial Denaturation (98 degC, 8 min)
id_time = 480 
sad_temp = 58  # Sulphonation and Deamination (58 degC, 1 hr)
sad_time = 3600 
wm_temp = 98  # Wax Melting (X degC, X min)
wm_time = 60 
bb_temp = 25  # Bead Binding (25 degC, 10 min)
bb_time = 600 
des_temp = 25  # Desulphonation (25 degC, 15 min)
des_time = 15 
elu_temp = 70  # Elution (70 degC, 10 min)
elu_time = 10 
phs_temp = 103  # PCR Hot Start (103 degC, 20 s)
phs_time = 20 
pa_temp = 60  # PCR Annealing (60 degC, 15 s) 
pa_time = 15 
pd_temp = 103  # PCR Denaturation (103 degC, 5 s)
pd_time = 5 
cycle_num = 40  # Cycle Number

BLED_PWM = 100
RLED_PWM = 100
LED_STATE = 0

FAM_CHANNEL = True
CY5_CHANNEL = True

# File management
user = 'Default'
active_dir = os.getcwd()

# Run at beginning of cmd_parse.py
class init_temp_thread(threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)
    def run(self):
        global ser, IO_queue, stop_signal, SENDING
        init_dir()
        #GPIO.setup(_pin_RESET,GPIO.OUT)
        
        #ser = serial.Serial('/dev/ttyUSB0',57600,timeout=0.5)  # used for USB connection      
        SENDING = False
        
        # Reset Arduino with new connection attempt to serial
        resetArd()

def init_temp():
    temp_thread =  init_temp_thread()
    temp_thread.start()
    return temp_thread

def init_dir():
    global user
    global active_dir

    home_dir = str(Path.home())
    pocmob_dir = home_dir + '/POCMOB2.0'
    users_dir = pocmob_dir + '/User'
    user_dir = users_dir + '/' + user

    # Make Directories if don't exist
    if not os.path.exists(user_dir):
        try:
            os.mkdir(pocmob_dir)
        except FileExistsError:
            pass
        try:
            os.mkdir(users_dir)
        except FileExistsError:
            pass
        try:
            os.mkdir(user_dir)
        except FileExistsError:
            pass

    active_dir = user_dir

def resetArd():
    global ser

    try: 
        #ser = serial.Serial('/dev/ttyS0',57600,timeout=0.5) # used for direct TX/RX pin connection
        ser = serial.Serial('/dev/ttyUSB0',57600,timeout=1)  # used for USB connection
    except serial.serialutil.SerialException:
        print('SerialException - attempting to close and reopen')
        ser.close()
        ser.open()
        pass
    
    print("Initializing Heater Arduino Mega...")
    time.sleep(0.5) 
    #flush serial
    #ser.read(100)
        
    #reset Arduino
    #ser.write("<reset>".encode('utf-8'))

    #Arduino Mega prints "<MEGA-MOTOR-READY>" on startup
    send_time = time.time()
    echo = ser.readline().decode('utf-8',errors='replace')
    print("waiting for Mega response...",echo)
    while echo != "<MEGA-TEMP-READY>\r\n":
        echo = ser.readline().decode('utf-8',errors='replace')
        
        # TIMEOUT in 3 seconds        
        if(time.time() - send_time > 3):

            print("WARNING: Connection to heater Mega timed out (3 seconds)")
            return

    print("Heater Arduino Connected!")

def cycle():
    global user, ser
    # Make folder in POCMOB2.0 directory
    now = datetime.now()
    dirname = str(Path.home()) + '/POCMOB2.0/User/' + user + '/' + now.strftime("%m-%d-%Y-%Hh%Mm%Ss")
    os.mkdir(dirname)
    os.chdir(dirname)

    # Open log files
    file_log = open("log.csv","a+")
    file_temp = open("temp.csv","a+")
    file_fluo = open("fluo.csv","a+")

    file_log.write('{}\n'.format(dirname))
    file_temp.write('{}\n'.format(dirname))
    file_fluo.write('{}\n'.format(dirname))

    # Send temperature settings to Arduino
    ardSend("rte(" + str(rt_temp)+")")
    ardSend("rti(" + str(rt_time)+")")
    ardSend("hte(" + str(hs_temp)+")")
    ardSend("hti(" + str(hs_time)+")")
    ardSend("ate(" + str(an_temp)+")")
    ardSend("ati(" + str(an_time)+")")
    ardSend("dte(" + str(de_temp)+")")
    ardSend("dti(" + str(de_time)+")")
    ardSend("cnu(" + str(cycle_num)+")")
    
    # Send start command to Arduino
    ardSend("cycle")

    # While loop - read Arduino, parse and log data
    cycling = True
    takingPic = False
    picThread = ""
    picChannel = ""
    data = ""
    cycle_count = 0 #
    while cycling:
        data = ser.readline().decode('utf-8',errors='replace')

        if takingPic:
            if picThread.is_alive() is False:
                takingPic = False
                # Let Arduino know picture is done
                bcmd = ("<P>\r\n").encode('utf-8')
                ser.write(bcmd)
                # Analyze last picture taken in thread called at end of picThread
        
        if data != "":
            data = data[:-2] # remove \r\n
            
            # break up data into arguments separated by commas
            ARGS = []
            ARG_SEP = ','
            ARGS_NUM = data.count(ARG_SEP)
            ARG_FIN = 0
            ARGS_END = len(data)
            for i in range(0, ARGS_NUM+1):
                  if i < ARGS_NUM:
                    ARG_base = data[ARG_FIN:ARGS_END].find(ARG_SEP)
                    ARGS.append(data[ARG_FIN : ARG_base + ARG_FIN])
                    ARG_FIN = ARG_base + ARG_FIN + 1
                  else:
                    ARGS.append(data[ARG_FIN : ARGS_END])

            if ARGS[0] == "C":
                cycle_count = ARGS[1]
                now = datetime.now()
                file_log.write(now.strftime("%m-%d-%Y-%Hh%Mm%Ss") + ",cycle,"+str(cycle_count) + "\n")

            # T prefix = time/temp data
            elif ARGS[0] == "T":
                file_temp.write(data[2:]) # write original data without "T,"
                file_temp.write('\n')
                MEGA_TIME = ARGS[1]
                MEGA_TEMP = ARGS[2]

            # PB/PR = take a picture
            elif ARGS[0] == "PB":
                print("Taking FAM picture.")
                now = datetime.now()
                file_log.write(now.strftime("%m-%d-%Y-%Hh%Mm%Ss") + ",pic,FAM,"+str(cycle_count) + "\n")
                picChannel = "FAM"
                picThread = cam.take_pic(name = "FAM-"+str(cycle_count), pause = 0.2) # include pause to allow time for LED to turn on
                takingPic = True

            elif ARGS[0] == "PR":
                print("Taking CY5 picture.")
                now = datetime.now()
                file_log.write(now.strftime("%m-%d-%Y-%Hh%Mm%Ss") + ",pic,CY5,"+str(cycle_count) + "\n")
                picChannel = "CY5"
                picThread = cam.take_pic(name = "CY5-"+str(cycle_count), pause = 0.2)
                takingPic = True

            # L prefix = other log data
            elif ARGS[0] == "L":
                now = datetime.now()
                file_log.write(now.strftime("%m-%d-%Y-%Hh%Mm%Ss") + "," + data[2:] + "\n") # write original data with RPi time and without "L,"
            # E = end
            elif ARGS[0] == "E":
                cycling = False

    return True

def LEDon(channel):
    LED_STATE = channel
    return ardSend("LEDon("+str(channel)+")")

def LEDoff():
    LED_STATE = 0
    return ardSend("LEDoff")

def setRLED(power):
    global RLED_PWM
    RLED_PWM = power
    print("Setting red LED PWM to ", RLED_PWM)
    return ardSend("rlp("+ str(RLED_PWM) +")")
    
def setBLED(power):
    global BLED_PWM
    BLED_PWM = power
    print("Setting blue LED PWM to ", BLED_PWM)
    return ardSend("blp("+ str(BLED_PWM) +")")

def FANon():
    
    if ardSend("fan on"):
        #settings.fan_state = True
        return True
    else:
        return False

def FANoff():
    #settings.fan_state = False
    return ardSend("fan off")

def ardRead(msg):
    msg_in =  ser.readline().decode('utf-8',errors='replace')
    if msg_in != "":
        print('RECEIVED FROM MEGA: ', msg_in[:-2])
        ardSend(msg_in[:-2])
   
    match = (msg_in == (msg + "\r\n"))
    
    return match
    
def ardSend(cmd):
    global ser, SENDING
    if SENDING: 
        print("WARNING: motor.py ardSend - Attempt to send ", cmd, "prevented due to SENDING flag.")
        return False # Don't allow attempts at communication when already sending a message
    
    SENDING = True
    ser.read(100) # flush buffer
    strcmd = str(cmd)
    
    # add <> to either end + \r\n + encode to byte
    bcmd = ("<" + strcmd + ">\r\n").encode('utf-8')
    
    # while echo doesn't match sent command -- try resending 3 more times
    echo = ""
    count = 0
    ser.write(bcmd)
    while count < 3:
        echo_raw = ser.readline()  # will timeout after 1 sec     
        echo = echo_raw.decode('utf-8')
        
        # remove \r\n
        echo = echo[:-2]
        print(echo)
        
        if echo != strcmd:
            count+=1
            if count > 2:
                SENDING = False
                return False
            ser.write(bcmd)
        else: 
            break

    SENDING = False
    return True