import android.content.Intent;
import android.app.Activity;
import android.os.Environment; // for finding directories
import android.os.Vibrator;
import android.os.VibrationEffect;
import android.view.KeyEvent; // for handling backspaces
import android.view.WindowManager;
import android.net.Uri;
import android.os.ParcelFileDescriptor;
import java.util.Arrays;
import java.util.Calendar;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileWriter;

/********************
 *  Display Settings
 ********************/ 
int displayMode = 0; 
int displayDevice = 0; // used if multiple instruments connected -- default value for 1 instrument =0
int last_displayMode = 0;
boolean alert_flag = false;
int alertID = 0;
/*
 *    0 = home screen
 *    1 = bisulfite conversion options
 *    2 = PCR options
 *    3 = fluorescence detection options
 */
String title = "Esophacap NAAT";


/***************
 *  USER INPUT *
 ***************/
String input_ID;
boolean input_flag = false;
TEXTBOX input_field;
ArrayList<Button> inputButtons = new ArrayList<Button>();
Button OKButton;
Button CancelButton;
boolean OK = true; // tracks if cancelled button pressed

String curr_cmd = "";
String input_cmd = "";

/******************************
 *  Definitions and Properties
 ******************************/
// Default properties for methods
int bisDigTemp = 55;   // incubation for digestion/lysis
float bisDigTime = 30;   // minutes
int bisDenTemp = 95;   // heating to denature DNA (°C)
float bisDenTime = 8;    // minutes at denature temp
int bisConTemp = 54;   // temperature for deamination (°C)
int bisConTime = 60;   // minutes incubation for deamination
int bisBindTemp = 4;   // temperature for binding to particles (°C)
float bisBindTime = 10;  // minutes 
int bisTestTemp = 60;  // Target temp for testing
int bisTestTime = 10;  // seconds to hold at bisTestTemp

int pcrHotsTime = 120;
int pcrDenTemp = 95;   // target temp for PCR denaturation
int pcrDenTime = 5;    // seconds hold at denaturation
int pcrAnnTemp = 60;     // target temp for PCR annealing
int pcrAnnTime = 20;     // seconds hold at anneal
int pcrTestTemp = 60;  // Target temp for testing
int pcrTestTime = 10;  // seconds to hold at bisTestTemp
int cycleN = 40;

/******************************
 *  Data Logging and Plotting *
 ******************************/
plot2D temp_plotter;
plot2D fluo_plotter;
int n_plots = 1;

/***********
 *  SETUP  *
 ***********/
Activity act;  // assigned in Bluetooth setup
Context mc;
void setup() {
    orientation(PORTRAIT);    
    size(displayWidth, displayHeight);
    smooth(2); // anti-alisased edges

    background(backgroundColor);
    //mySerial = new Serial( this, Serial.list()[0], 115200);

    act = this.getActivity();

    // Keep screen on while app is running
    act.runOnUiThread(new Runnable()
    {
        public void run() {
            act.getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        }
    }
    );
    setupFonts();
    setupColors();
    setupBT();
    setupButtons();
    setupTextbox();

    setupPlot();

    //setupESELog();    // called in draw() if serialConnected 
    //connectSerial();
    //ardSend("stats");
    //test_setup();
}

void draw() {
    // Draw background and check if display has been resized
    background(backgroundColor);

    // Draw Title version number and Home button

    //test_cycle_plot();

    if (alert_flag) {

        displayAlert(alertID);
    } else {
        displayDefault();

        // Display home screen  
        if (displayMode == 0) {
            displayHome();
        } else if (displayMode == 1) {
            displayBis();
        } else if (displayMode == 2) {
            displayPCR();
        }
        // Display fluorescence options
        else if (displayMode == 3) {
            displayFluo();
        } else if (displayMode == 4) {
            displayMag();
        } else if (displayMode == -1) {
            displayInputField();
        }
    }
    update();
    if (serialConnected) {
        if (eselogConnected) {
            if (!eselogInit) setupESELog();
            if (!motorsInit) setupMotors();
        }
        //handleSerial();
    }
}

// Update display settings of buttons based on mouse position (x,y)
// Check if text input has been completed
void update() {
    for (Button b : defaultButtons) {
        b.update();
    }
    if (displayMode == 0) {
        for (Button b : homeButtons) {
            //buttonBuffer = buttonList[i]; 
            b.update();
        }
    } else if (displayMode == 1) {

        for (Button b : bisButtons) {
            //buttonBuffer = buttonList[i]; 
            b.update();
        }
    } else if (displayMode == 2) {
        for (Button b : pcrButtons) {
            //buttonBuffer = buttonList[i]; 
            b.update();
        }
    } else if (displayMode == 3) {
        for (Button b : fluoButtons) {
            //buttonBuffer = buttonList[i]; 
            b.update();
        }
    } else if (displayMode == 4) {
        for (Button b : magXButtons) {
            //buttonBuffer = buttonList[i]; 
            b.update();
        }
        for (Button b : magZButtons) {
            //buttonBuffer = buttonList[i]; 
            b.update();
        }
    } else if (displayMode == -1) {
        for (Button b : inputButtons) {
            //buttonBuffer = buttonList[i]; 
            b.update();
            if (input_flag) {
                displayMode = last_displayMode;  
                serialCmd(input_cmd);
            }
        }
    }
}


void mousePressed() {
    if (alert_flag) {
        alert_flag = false;
        return;
    }
    for (Button b : defaultButtons) {
        if (b.over()) {
            b.pressed();    // switches state setting
            curr_cmd = b.func;
            serialCmd(curr_cmd);    // re-call initial cmd for input
        }
    } 
    if (displayMode == 0) {
        for (Button b : homeButtons) {
            //buttonBuffer = buttonList[i]; 
            if (b.over()) {
                b.pressed();    // switches state setting
                curr_cmd = b.func;
                serialCmd(curr_cmd);    // re-call initial cmd for input
            }
        }
    } else if (displayMode == 1) {
        for (Button b : bisButtons) {
            //buttonBuffer = buttonList[i]; 
            if (b.over()) {
                b.pressed();    // switches state setting
                curr_cmd = b.func;
                serialCmd(curr_cmd);    // re-call initial cmd for input
            }
        }
    } else if (displayMode == 2) {
        for (Button b : pcrButtons) {
            //buttonBuffer = buttonList[i]; 
            if (b.over()) {
                b.pressed();    // switches state setting
                curr_cmd = b.func;
                serialCmd(curr_cmd);
            }
        }
    } else if (displayMode == 3) {
        for (Button b : fluoButtons) {
            //buttonBuffer = buttonList[i]; 
            if (b.over()) {
                b.pressed();    // switches state setting
                curr_cmd = b.func;
                serialCmd(curr_cmd);
            }
        }
    } else if (displayMode == 4) {
        for (Button b : magXButtons) {
            //buttonBuffer = buttonList[i]; 
            if (b.over()) {
                b.pressed();    // switches state setting
                curr_cmd = b.func;
                serialCmd(curr_cmd);
            }
        }
        for (Button b : magZButtons) {
            //buttonBuffer = buttonList[i]; 
            if (b.over()) {
                b.pressed();    // switches state setting
                curr_cmd = b.func;
                serialCmd(curr_cmd);
            }
        }
    } else if (displayMode == -1) {
        input_field.PRESSED();
        for (Button b : inputButtons) {
            //buttonBuffer = buttonList[i]; 
            if (b.over()) {
                b.pressed();    // switches state setting
                curr_cmd = b.func;
                serialCmd(curr_cmd);
            }
        }
    }
}

void keyPressed() {
    if (displayMode == -1) {
        input_field.KEYPRESSED(key, keyCode);
        println(key);
    }
    if (alert_flag) {
        if (key == 10) {  // PRESSED ENTER
            alert_flag = false;
        }
    }
}
