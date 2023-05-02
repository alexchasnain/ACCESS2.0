import processing.serial.*;

/********************
 *  Display Settings
 ********************/
//int _W = 540; // initial width and height
//int _H = 960;

int _W = 600; // initial width and height
int _H = 600;

int mXscaled;  // scale mouse value for resized frame
int mYscaled; 

int displayMode = 0; 
int last_displayMode = 0;
boolean alert_flag = true;
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

/******************
 *  BUTTON LIST
 ******************/
String curr_cmd = "";
String input_cmd = "";
ArrayList<Button> defaultButtons = new ArrayList<Button>();
PImage home_icon;
Button hButton;
Button serialButton;

ArrayList<Button> homeButtons = new ArrayList<Button>();
Button bisSwitch;
Button bisOptions;
Button magSwitch;
Button magOptions;
Button pcrSwitch;
Button pcrOptions;
Button fluoSwitch;
Button fluoOptions;
Button fluoTest;
Button startButton;
Button saveButton;
//String filename = "No File Opened";

ArrayList<Button> bisButtons = new ArrayList<Button>();
Button bisDigTempButton;  // digestion temperature  - 55C
Button bisDigTimeButton;  // digestion time (minutes)  - 30 minutes
Button bisDenTempButton;  // denaturation temperature  - 95C
Button bisDenTimeButton;  // denaturation time (minutes)  - 8 minutes
Button bisConTempButton;  // temperature for deamination of unmethylated cytosine and sulfonation - 54C
Button bisConTimeButton;  // time for conversion into uracil-sulfonate - 60 min
Button bisBindTempButton; // Cooling temp to bind nucleic acids to beads 
Button bisBindTimeButton; // minutes
Button bisTestButton; // Test temperature control
Button bisTestTempButton; // Test temperature control
Button bisTestTimeButton; // Test temperature control

ArrayList<Button> magXButtons = new ArrayList<Button>();
ArrayList<Button> magZButtons = new ArrayList<Button>();
RectButton bisMagButton;      // Bisulfite magnet
Button w1MagButton;       // well 1
Button w2MagButton;       // well 2
Button w3MagButton;       // well 3
Button w4MagButton;       // well 4
Button pcrMagButton;      // pcr well
Button tMagButton;
Button mMagButton;
Button bMagButton;

ArrayList<Button> pcrButtons = new ArrayList<Button>();
Button pcrHotSwitch;      // flag for hotstart
Button pcrHotsTimeButton;  // time to do hotstart at denature temp
Button pcrDenTempButton;  // denaturation temperature  - 95C
Button pcrDenTimeButton;  // denaturation time (minutes)  - 5 sec
Button pcrAnnTempButton;  // annealing temperature - 60C
Button pcrAnnTimeButton;  // annealing time - 60 min
Button pcrCycleNButton;   // number of cycles
Button pcrTestButton;     // Test temperature control
Button pcrTestTimeButton;   
Button pcrTestTempButton;   

ArrayList<Button> fluoButtons = new ArrayList<Button>();
PImage LED;
Button LED1;
Button LED2;
Button Det1;
Button Det2;

Button LED1Current;
Button LED2Current;

Button LED1OnDelay;
Button LED1OffDelay;
Button LED2OnDelay;
Button LED2OffDelay;

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
void setup() {
  size(600, 600);  // Corresponds to _W and _H
  surface.setResizable(true);
  setupFonts();
  setupColors();

  setupButtons();
  setupTextbox();

  setupPlot();

  //setupESELog();    // called in draw() if serialConnected 
  //connectSerial();
  //ardSend("stats");
  //test_setup();
  
  background(backgroundColor);
}

void draw() {
  // Draw background and check if display has been resized
    background(backgroundColor);
  checkDisplaySize(); 

  // Scale mouse position value for any resizeing
  mXscaled = mouseX * _W/width;
  mYscaled = mouseY * _H/height;

  scale((float)width/_W, (float)height/_H);

  // Draw Title version number and Home button

  //test_cycle_plot();

  if (alert_flag) {

    displayAlert(alertID);
  } else  {
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
      //if (!eselogInit) setupESELog();
      //if (!motorsInit) setupMotors();
      eselogInit = true;
      motorsInit = true;
    }
    handleSerial();
  }
}

void checkDisplaySize() {
  if (abs((float(width)/height - float(_W)/_H))>0.01) {
    surface.setSize(width, height = (int)(width*_H/_W));
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
    mXscaled = mouseX * _W/width;
    mYscaled = mouseY * _H/height;
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
