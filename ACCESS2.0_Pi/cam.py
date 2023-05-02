from time import sleep
from datetime import datetime
try:
    from picamera import PiCamera
except ModuleNotFoundError:
    print('No picamera module - cam.py import failed')
from fractions import Fraction
from PIL import Image
#from pyzbar import pyzbar
import cv2
import os
import numpy as np
import threading
import json
from pathlib import Path

# LIBRARY NOTES
# current version of opencv doesn't work with RPi
# use "pip3 install opencv-python==3.4.6.27"

camera = None

FRAMERATE = 5
ISO = 1600
SHUTTER_SPEED = 200000 # microseconds

# 1640x1232 resolution 4:3 uses full sensor -- pixels binned 2x2
w = 1648 #changed to reflect rounding up from 1640
h = 1232


class picThread(threading.Thread):
    def __init__(self, name, n_pic = ""):
        threading.Thread.__init__(self)
        self.name = name
        self.n_pic = n_pic
    def run(self):
        image = np.empty((h*w*3,),dtype = np.uint8)
        camera.capture(image, 'rgb', use_video_port=True)
        image = image.reshape(h,w,3)
        image = Image.fromarray(image)
        image.save("{}.jpg".format(self.name))

class init_cam_thread(threading.Thread):
    def __init__(self,preview):
        threading.Thread.__init__(self)
        self.preview = preview
    
    def run(self):
        global camera, FRAMERATE, SHUTTER_SPEED, ISO
                
        # initialize camera
        print('FRAMERATE =' + str(FRAMERATE))
        print('ISO =' + str(ISO))
        print('SHUTTER_SPEED =' + str(SHUTTER_SPEED))
        
        camera = PiCamera(resolution = (w,h),framerate = FRAMERATE)
        camera.shutter_speed = SHUTTER_SPEED
        camera.iso = ISO                   
        #camera.rotation = 90
            
        if self.preview:
            camera.start_preview(fullscreen=False)
            camera.preview_window = (0,50,w//3,h//3) # x,y,w,h
            
        # wait for gains to settle
        #nano.LEDon(1)
        sleep(2)
        
        g = camera.awb_gains
        camera.awb_mode = 'off' # LOCKS IN WHITE BALANCE
        camera.awb_gains = g
        camera.exposure_mode='off' # LOCKS IN GAINS
        
        #camera.stop_preview()

def init_cam(preview = False):
    #settings.init_status = "Starting Camera..."
    cthread = init_cam_thread(preview)
    cthread.start()

    return cthread 

def take_pic(name = "pic", pause = 0):
    global n_pics
    if pause >0:
        sleep(pause)
    pthread = picThread(name="{}".format(name))    
    pthread.start()
    return pthread
    #file.write_file("Pic {}.jpg with temp: {} " .format(setting.n_pics,temp.steinhart()))

def show_preview(_x,_y,_w,_h):
    global camera, w, h
    # Camera w=720, h=1280
    if _w/w  > _h/h:
        _w = w * _h//h
    else: 
        _h = h * _w//w
    camera.start_preview(fullscreen=False)
    camera.preview_window = (_x,_y,_w,_h)

def stop_preview():
    global camera
    camera.stop_preview()

# def readQR():
#     reset_pic_count()
#     nano.LEDon(1)
#     sleep(0.5)
#     p = take_pic(channel = 1, name = "qr")
#     while p.is_alive():
#         pass # do nothing
#     nano.LEDoff()
#     cwd = os.getcwd()
#     image = cv2.imread(cwd +'/qr-1.jpg')
#     barcodes = pyzbar.decode(image)
#     for barcode in barcodes:
#         # extract bounding box location of barcode and draw on image
#         (x,y,w,h) = barcode.rect
#         cv2.rectangle(image,(x,y), (x + w, y+h), (0,0,255),2)
        
#         # convert barcode to string from bytes
#         barcodeData = barcode.data.decode("utf-8")
#         barcodeType = barcode.type
        
#         # draw barcode data and barcode type on the image
#         text ="{} ({})".format(barcodeData,barcodeType)
#         cv2.putText(image, text, (x, y-10), cv2.FONT_HERSHEY_SIMPLEX,
#                     0.5, (0,0,255), 2)
        
#         # print barcode type and data to the terminal
#         print("[INFO] Found {} barcode: {}".format(barcodeType, barcodeData))
    
#     cv2.imshow("Image", cv2.resize(image,(500,500)))
#     cv2.waitKey(0)
#     reset_pic_count()

if __name__ == "__main__":
    init_cam(True)
