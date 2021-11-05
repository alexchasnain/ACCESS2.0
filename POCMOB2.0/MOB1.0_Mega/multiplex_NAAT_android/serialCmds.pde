// sends command to arduino through serial given string "cmd" stored by buttons
boolean autorun = false;
void serialCmd(String cmd) {

    /************************
     *  HOME SCREEN BUTTONS *
     ************************/

    if (cmd.equals("home")) {
        displayMode =0;
        println("Back to homescreen");
    } else if (cmd.equals("serial")) {
        serialMode = 0;  // return to default serialMode
        connectSerial();
    } else if (cmd.equals("bis_flag")) {
        println("bis_flag switched");
    } else if (cmd.equals("mag_flag")) {
        println("mag_flag switched");
    } else if (cmd.equals("pcr_flag")) {
        println("pcr_flag switched");
    } else if (cmd.equals("fluo_flag")) {
        println("fluo_flag switched");
    } else if (cmd.equals("bisOpt")) {
        displayMode = 1;  // change screen to bisulfite conversion options
    } else if (cmd.equals("pcrOpt")) {
        displayMode = 2;  // change screen to pcr options
    } else if (cmd.equals("fluoOpt")) {
        displayMode = 3;  // change screen to bisulfite conversion options
    } else if (cmd.equals("magOpt")) {
        if (!serialConnected) return;  
        setupMotors();
        displayMode = 4;  // magnet options
        alert_flag = true;
        alertID = 1;
        xpos = 0;  // initialize position of magnetic carriage
        for (Button b : magXButtons) {
            if ("bisMag".equals(b.func))
            {
                b.state = true;
            } else {
                b.state =false;
            }
        }
    } else if (cmd.equals("save")) {
        //saveData();
    } else if (cmd.equals("start")) {
        autorun = true;
        //selectDir();
        if (!fileOpened[displayDevice]) {
            println("No filename selected -- not starting methods");
            return;
        }
        //if (input_flag) {
        //input_flag = false; //reset input flag
        //if (input_field.Text.equals("") ) {
        //  if (!OK) return;        // Pressed Cancel
        //  else if (filename.equals("No File Opened")) return;
        //} else {
        //  filename = input_field.Text;
        //}

        //filename = output_file;

        /* if (!check_filename(output_file)) {
         return;   // call for data entry if wrong values entered
         } else {
         
         */
        println( "Starting run with filename: " + filename);
        bisCon_flag = bisSwitch.state;
        mag_flag = magSwitch.state;
        cycle_flag = pcrSwitch.state;
        if (bisSwitch.state) {
            println("Starting Bisulfite Conversion.");
            bisCon();
        } else if (magSwitch.state) {
            serialMode = 1;
            println("Starting Magnetofluidic Processing.");
            ardSend("mag", 0);
        } else if (pcrSwitch.state) {
            println("Starting PCR.");
            cycle();
        }
        //}
        /*  } else {
         //getInput("Filename: " + filename, "start");
         }
         */
    } else if (cmd.equals("filename")) {
        if(!serialConnected){
            displayAlert(7);
            return;
        }
        if (input_flag) {
            input_flag = false; //reset input flag
            if (input_field.Text.equals("")) return;        // Pressed Cancel or no input
            else {
                String input = input_field.Text;
                println( "Input text: " + input);
                if (check_filename(input)) {
                    writers.set(displayDevice, openFile(input_field.Text, fileDir, false, false));    // false = no append (new file)  , false = no overwrite
                    if (writers.get(displayDevice) == null) {
                        println("Failure to create file.");
                        fileOpened[displayDevice] = false;
                        return;
                    }
                    filename = input;
                    println("Filename set to: " +  filename);

                    try {
                        logwriters.get(displayDevice).close();
                        File tempFile = new File(logDir, "log.temp.txt");
                        File logwriterFile = new File(logDir, "log." + filename);

                        // Rename file (or directory)
                        tempFile.renameTo(logwriterFile);
                        //logwriter = new FileWriter(logwriterFile, true);
                        logwriters.set(displayDevice, openFile("log." + filename, logDir, true, true));  // logwriter opened with connection to bluetooth
                        writeFile(logwriters.get(displayDevice), filename + " - File Created: " + timestamp()+ "\n");

                        filenames.set(displayDevice, filename);
                    }
                    catch(Exception e) {
                        println("Failure to create log file.");
                    }
                    //logwriter = openFile("log." + input_field.Text, logDir, false);

                    fileOpened[displayDevice] = true;
                } else serialCmd(input_cmd);    // call for data entry if wrong values entered
            }
        } else {
            getInput(filenameButton.text, filenameButton.func);
        }
    }


    /*********************
     *  BISULFITE BUTTONS *
     **********************/
    else if (cmd.equals("bisDigTemp")) {
        if (input_flag) {
            input_flag = false; //reset input flag
            if (input_field.Text.equals("")) return;        // Pressed Cancel or no input
            else {
                int input_int = parseInt(input_field.Text);
                println( "Input text to num: " + input_int);
                if (input_int>=30 && input_int<=105) {
                    bisDigTemp = input_int; 
                    bisDigTempButton.text = "Digestion Temp:\n" + bisDigTemp + "°C" ;
                } else serialCmd(input_cmd);    // call for data entry if wrong values entered
            }
        } else {
            getInput(bisDigTempButton.text, bisDigTempButton.func);
        }
    } else if (cmd.equals("bisDigTime")) {
        if (input_flag) {
            input_flag = false; //reset input flag
            if (input_field.Text.equals("")) return;        // Pressed Cancel or no input
            else {
                float input_int = parseFloat(input_field.Text);
                println( "Input text to num: " + input_int);
                if (input_int>=0 && input_int<=100) {
                    bisDigTime = input_int; 
                    bisDigTimeButton.text = "Digestion Time:\n" + bisDigTime + " min" ;
                } else serialCmd(input_cmd);    // call for data entry if wrong values entered
            }
        } else {
            getInput(bisDigTimeButton.text, bisDigTimeButton.func);
        }
    } else if (cmd.equals("bisDenTemp")) {
        if (input_flag) {
            input_flag = false; //reset input flag
            if (input_field.Text.equals("")) return;        // Pressed Cancel or no input
            else {
                int input_int = parseInt(input_field.Text);
                println( "Input text to num: " + input_int);
                if (input_int>=30 && input_int<=105) {
                    bisDenTemp = input_int; 
                    bisDenTempButton.text = "Denaturation Temp:\n" + bisDenTemp + "°C" ;
                } else serialCmd(input_cmd);    // call for data entry if wrong values entered
            }
        } else {
            getInput(bisDenTempButton.text, bisDenTempButton.func);
        }
    } else if (cmd.equals("bisDenTime")) {
        if (input_flag) {
            input_flag = false; //reset input flag
            if (input_field.Text.equals("")) return;        // Pressed Cancel or no input
            else {
                float input_int = parseFloat(input_field.Text);
                println( "Input text to num: " + input_int);
                if (input_int>=0 && input_int<=100) {
                    bisDenTime = input_int; 
                    bisDenTimeButton.text = "Denaturation Time:\n" + bisDenTime + " min" ;
                } else serialCmd(input_cmd);    // call for data entry if wrong values entered
            }
        } else {
            getInput(bisDenTimeButton.text, bisDenTimeButton.func);
        }
    } else if (cmd.equals("bisConTemp")) {
        if (input_flag) {
            input_flag = false; //reset input flag
            if (input_field.Text.equals("")) return;        // Pressed Cancel or no input
            else {
                int input_int = parseInt(input_field.Text);
                println( "Input text to num: " + input_int);
                if (input_int>=30 && input_int<=100) {
                    bisConTemp = input_int; 
                    bisConTempButton.text = "Conversion Temp:\n" + bisConTemp + " °C" ;
                } else serialCmd(input_cmd);    // call for data entry if wrong values entered
            }
        } else {
            getInput(bisConTempButton.text, bisConTempButton.func);
        }
    } else if (cmd.equals("bisConTime")) {
        if (input_flag) {
            input_flag = false; //reset input flag
            if (input_field.Text.equals("")) return;        // Pressed Cancel or no input
            else {
                int input_int = parseInt(input_field.Text);
                println( "Input text to num: " + input_int);
                if (input_int>=0 && input_int<=100) {
                    bisConTime = input_int; 
                    bisConTimeButton.text = "Conversion Time:\n" + bisConTime + " min" ;
                } else serialCmd(input_cmd);    // call for data entry if wrong values entered
            }
        } else {
            getInput(bisConTimeButton.text, bisConTimeButton.func);
        }
    } else if (cmd.equals("bisBindTemp")) {
        if (input_flag) {
            input_flag = false; //reset input flag
            if (input_field.Text.equals("")) return;        // Pressed Cancel or no input
            else {
                int input_int = parseInt(input_field.Text);
                println( "Input text to num: " + input_int);
                if (input_int>=0 && input_int<=100) {
                    bisBindTemp = input_int; 
                    bisBindTempButton.text = "Binding Temp:\n" + bisBindTemp + " °C" ;
                } else serialCmd(input_cmd);    // call for data entry if wrong values entered
            }
        } else {
            getInput(bisBindTempButton.text, bisBindTempButton.func);
        }
    } else if (cmd.equals("bisBindTime")) {
        if (input_flag) {
            input_flag = false; //reset input flag
            if (input_field.Text.equals("")) return;        // Pressed Cancel or no input
            else {
                float input_int = parseFloat(input_field.Text);
                println( "Input text to num: " + input_int);
                if (input_int>=0 && input_int<=100) {
                    bisBindTime = input_int; 
                    bisBindTimeButton.text = "Binding Time:\n" + bisBindTime + " min" ;
                } else serialCmd(input_cmd);    // call for data entry if wrong values entered
            }
        } else {
            getInput(bisBindTimeButton.text, bisBindTimeButton.func);
        }
    } else if (cmd.equals("bisTestTime")) {
        if (input_flag) {
            input_flag = false; //reset input flag
            if (input_field.Text.equals("")) return;        // Pressed Cancel or no input
            else {
                int input_int = parseInt(input_field.Text);
                println( "Input text to num: " + input_int);
                if (input_int>=0 && input_int<=1000) {
                    bisTestTime = input_int; 
                    bisTestTimeButton.text =  "Test Hold Time:\n" + bisTestTime + " sec" ;
                } else serialCmd(input_cmd);    // call for data entry if wrong values entered
            }
        } else {
            getInput(bisTestTimeButton.text, bisTestTimeButton.func);
        }
    } else if (cmd.equals("bisTestTemp")) {
        if (input_flag) {
            input_flag = false; //reset input flag
            if (input_field.Text.equals("")) return;        // Pressed Cancel or no input
            else {
                int input_int = parseInt(input_field.Text);
                println( "Input text to num: " + input_int);
                if (input_int>=0 && input_int<=100) {
                    bisTestTemp = input_int; 
                    bisTestTempButton.text =  "Test Hold Temp:\n" + bisTestTemp + "°C" ;
                } else serialCmd(input_cmd);    // call for data entry if wrong values entered
            }
        } else {
            getInput(bisTestTempButton.text, bisTestTempButton.func);
        }
    } else if (cmd.equals("bisTest") && serialConnected) {
        test_heater(bisTestTemp, bisTestTime, 1);
    }

    /**********************
     *     PCR BUTTONS    *
     **********************/
    else if (cmd.equals("pcrHotsTime")) {
        if (input_flag) {
            input_flag = false; //reset input flag
            if (input_field.Text.equals("")) return;        // Pressed Cancel or no input
            else {
                int input_int = parseInt(input_field.Text);
                println( "Input text to num: " + input_int);
                if (input_int>=0 && input_int<=300) {
                    pcrHotsTime = input_int; 
                    pcrHotsTimeButton.text =  "Hotstart Time:\n" + pcrHotsTime + " sec" ;
                } else serialCmd(input_cmd);    // call for data entry if wrong values entered
            }
        } else {
            getInput(pcrHotsTimeButton.text, pcrHotsTimeButton.func);
        }
    } else if (cmd.equals("pcrDenTemp")) {
        if (input_flag) {
            input_flag = false; //reset input flag
            if (input_field.Text.equals("")) return;        // Pressed Cancel or no input
            else {
                int input_int = parseInt(input_field.Text);
                println( "Input text to num: " + input_int);
                if (input_int>=0 && input_int<=100) {
                    pcrDenTemp = input_int; 
                    pcrDenTempButton.text =  "Denaturation Temp:\n" + pcrDenTemp + "°C" ;
                } else serialCmd(input_cmd);    // call for data entry if wrong values entered
            }
        } else {
            getInput(pcrDenTempButton.text, pcrDenTempButton.func);
        }
    } else if (cmd.equals("pcrDenTime")) {
        if (input_flag) {
            input_flag = false; //reset input flag
            if (input_field.Text.equals("")) return;        // Pressed Cancel or no input
            else {
                int input_int = parseInt(input_field.Text);
                println( "Input text to num: " + input_int);
                if (input_int>=0 && input_int<=100) {
                    pcrDenTime = input_int; 
                    pcrDenTimeButton.text =  "Denaturation Time:\n" + pcrDenTime + " sec" ;
                } else serialCmd(input_cmd);    // call for data entry if wrong values entered
            }
        } else {
            getInput(pcrDenTimeButton.text, pcrDenTimeButton.func);
        }
    } else if (cmd.equals("pcrAnnTemp")) {
        if (input_flag) {
            input_flag = false; //reset input flag
            if (input_field.Text.equals("")) return;        // Pressed Cancel or no input
            else {
                int input_int = parseInt(input_field.Text);
                println( "Input text to num: " + input_int);
                if (input_int>=0 && input_int<=100) {
                    pcrAnnTemp = input_int; 
                    pcrAnnTempButton.text =  "Anneal Temp:\n" + pcrAnnTemp + "°C" ;
                } else serialCmd(input_cmd);    // call for data entry if wrong values entered
            }
        } else {
            getInput(pcrAnnTempButton.text, pcrAnnTempButton.func);
        }
    } else if (cmd.equals("pcrAnnTime")) {
        if (input_flag) {
            input_flag = false; //reset input flag
            if (input_field.Text.equals("")) return;        // Pressed Cancel or no input
            else {
                int input_int = parseInt(input_field.Text);
                println( "Input text to num: " + input_int);
                if (input_int>=0 && input_int<=100) {
                    pcrAnnTime = input_int; 
                    pcrAnnTimeButton.text =  "Anneal Time:\n" + pcrAnnTime + " sec" ;
                } else serialCmd(input_cmd);    // call for data entry if wrong values entered
            }
        } else {
            getInput(pcrAnnTimeButton.text, pcrAnnTimeButton.func);
        }
    } else if (cmd.equals("pcrTestTime")) {
        if (input_flag) {
            input_flag = false; //reset input flag
            if (input_field.Text.equals("")) return;        // Pressed Cancel or no input
            else {
                int input_int = parseInt(input_field.Text);
                println( "Input text to num: " + input_int);
                if (input_int>=0 && input_int<=1000) {
                    pcrTestTime = input_int; 
                    pcrTestTimeButton.text =  "Test Hold Time:\n" + pcrTestTime + " sec" ;
                } else serialCmd(input_cmd);    // call for data entry if wrong values entered
            }
        } else {
            getInput(pcrTestTimeButton.text, pcrTestTimeButton.func);
        }
    } else if (cmd.equals("pcrTestTemp")) {
        if (input_flag) {
            input_flag = false; //reset input flag
            if (input_field.Text.equals("")) return;        // Pressed Cancel or no input
            else {
                int input_int = parseInt(input_field.Text);
                println( "Input text to num: " + input_int);
                if (input_int>=0 && input_int<=100) {
                    pcrTestTemp = input_int; 
                    pcrTestTempButton.text =  "Test Hold Temp:\n" + pcrTestTemp + "°C" ;
                } else serialCmd(input_cmd);    // call for data entry if wrong values entered
            }
        } else {
            getInput(pcrTestTempButton.text, pcrTestTempButton.func);
        }
    } else if (cmd.equals("pcrCycleN")) {
        if (input_flag) {
            input_flag = false; //reset input flag
            if (input_field.Text.equals("")) return;        // Pressed Cancel or no input
            else {
                int input_int = parseInt(input_field.Text);
                println( "Input text to num: " + input_int);
                if (input_int>=0 && input_int<=100) {
                    cycleN = input_int; 
                    pcrCycleNButton.text =  "Cycle Number:\n" + cycleN ;
                } else serialCmd(input_cmd);    // call for data entry if wrong values entered
            }
        } else {
            getInput(pcrCycleNButton.text, pcrCycleNButton.func);
        }
    } else if (cmd.equals("pcrTest") && serialConnected) {
        test_heater(pcrTestTemp, pcrTestTime, 2);
    }

    /*************************
     *     MAGNET BUTTONS    *
     ************************/
    else if (cmd.equals("bisMag") || cmd.equals("w1Mag") || cmd.equals("w2Mag") || cmd.equals("w3Mag") || cmd.equals("w4Mag") || cmd.equals("pcrMag") || cmd.equals("resetMag")) {
        moveXmotor(cmd);

        for (Button b : magXButtons) {
            if (cmd.equals(b.func))
            {
                b.state = true;
            } else {
                b.state =false;
            }
        }
    } else if (cmd.equals("tMag") || cmd.equals("mMag") || cmd.equals("bMag") ) {
        moveZmotor(cmd);

        for (Button b : magZButtons) {
            if (cmd.equals(b.func))
            {
                b.state = true;
            } else {
                b.state =false;
            }
        }
    }

    /******************
     *  ESELog BUTTONS *
     *******************/
    else if (cmd.equals("LED1")) {
        if (LED1.state) {
        } // allow switching LED on
        else {
            // if turning LED1 off
            LED2.state = true;    // turn on LED2 
            Det2.state = true;    // turn on detector 2
            Det1.state = false;   // turn off detector 1
        }
        setMethodType();
    } else if (cmd.equals("LED2")) {
        if (LED2.state) { 
            Det2.state = true;
        } else {
            LED1.state = true;
        }
        setMethodType();
    } else if (cmd.equals("Det1")) {
        if (LED1.state == false) {
            Det1.state = false;     // don't allow det1 turn on if LED1 not on
        }
        if (Det1.state == false) Det2.state = true; // turn on det2 if det1 off
        if (LED1.state && LED2.state) Det1.state = true; // always on if both LEDs are on
        setMethodType();
    } else if (cmd.equals("Det2")) {
        if (Det2.state) {
        } else {
            if (LED2.state) Det2.state = true;          // keep on if LED2 is on
            //else if(!LED1.state) Det2.state = true;    // keep on if LED1 is off   
            else Det1.state = true;
        }
        setMethodType();
    } else if (cmd.equals("LED1Current")) {
        if (input_flag) {
            input_flag = false; //reset input flag
            if (input_field.Text.equals("")) return;        // Pressed Cancel or no input
            else {
                int input_int = parseInt(input_field.Text);
                println( "Input text to num: " + input_int);
                if (input_int>=0 && input_int<=200) {
                    led1_current = input_int; 
                    LED1Current.text = "LED1 Current:\n" + led1_current + "mA";
                    modbus_str = modbus("write,led1_current,"+led1_current);
                } else serialCmd(input_cmd);    // call for data entry if wrong values entered
            }
        } else {
            getInput(LED1Current.text, LED1Current.func);
        }
    } else if (cmd.equals("LED2Current")) {
        if (input_flag) {
            input_flag = false; //reset input flag
            if (input_field.Text.equals("")) return;        // Pressed Cancel or no input
            else {
                int input_int = parseInt(input_field.Text);
                println( "Input text to num: " + input_int);
                if (input_int>=0 && input_int<=200) {
                    led2_current = input_int; 
                    LED2Current.text = "LED1 Current:\n" + led2_current + "mA";
                    modbus_str = modbus("write,led2_current,"+led2_current);
                } else serialCmd(input_cmd);    // call for data entry if wrong values entered
            }
        } else {
            getInput(LED2Current.text, LED2Current.func);
        }
    } else if (cmd.equals("LED1OnDelay")) {
        if (input_flag) {
            input_flag = false; //reset input flag
            if (input_field.Text.equals("")) return;        // Pressed Cancel or no input
            else {
                int input_int = parseInt(input_field.Text);
                println( "Input text to num: " + input_int);
                if (input_int>=0 && input_int<=60000) {
                    led1_on_delay = input_int; 
                    LED1OnDelay.text = "LED1 On Delay:\n" + led1_on_delay + "ms";
                    modbus_str = modbus("write,led1_on_delay,"+led1_on_delay);
                } else serialCmd(input_cmd);    // call for data entry again if wrong values entered
            }
        } else {
            getInput(LED1OnDelay.text, LED1OnDelay.func);
        }
    } else if (cmd.equals("LED2OnDelay")) {
        if (input_flag) {
            input_flag = false; //reset input flag
            if (input_field.Text.equals("")) return;        // Pressed Cancel or no input
            else {
                int input_int = parseInt(input_field.Text);
                println( "Input text to num: " + input_int);
                if (input_int>=0 && input_int<=60000) {
                    led2_on_delay = input_int; 
                    LED2OnDelay.text = "LED2 On Delay:\n" + led2_on_delay + "mA";
                    modbus_str = modbus("write,led2_on_delay,"+led2_on_delay);
                } else serialCmd(input_cmd);    // call for data entry if wrong values entered
            }
        } else {
            getInput(LED2OnDelay.text, LED2OnDelay.func);
        }
    } else if (cmd.equals("LED1OffDelay")) {
        if (input_flag) {
            input_flag = false; //reset input flag
            if (input_field.Text.equals("")) return;        // Pressed Cancel or no input
            else {
                int input_int = parseInt(input_field.Text);
                println( "Input text to num: " + input_int);
                if (input_int>=0 && input_int<=60000) {
                    led1_off_delay = input_int; 
                    LED1OffDelay.text = "LED1 Off Delay:\n" + led1_off_delay + "ms";
                    modbus_str = modbus("write,led1_off_delay,"+led1_off_delay);
                } else serialCmd(input_cmd);    // call for data entry again if wrong values entered
            }
        } else {
            getInput(LED1OffDelay.text, LED1OffDelay.func);
        }
    } else if (cmd.equals("LED2OffDelay")) {
        if (input_flag) {
            input_flag = false; //reset input flag
            if (input_field.Text.equals("")) return;        // Pressed Cancel or no input
            else {
                int input_int = parseInt(input_field.Text);
                println( "Input text to num: " + input_int);
                if (input_int>=0 && input_int<=60000) {
                    led2_off_delay = input_int; 
                    LED2OffDelay.text = "LED2 Off Delay:\n" + led2_off_delay + "ms";
                    modbus_str = modbus("write,led2_off_delay,"+led2_off_delay);
                } else serialCmd(input_cmd);    // call for data entry if wrong values entered
            }
        } else {
            getInput(LED2OffDelay.text, LED2OffDelay.func);
        }
    } else if (cmd.equals("fluoTest")) {
        if (eselogConnected) {
            if (detect_flag && !readMessages.get(displayDevice).equals("scan")) {
                detect_flag = false;
                detect_val = readMessages.get(displayDevice).substring(0,readMessages.get(displayDevice).length()-1);
                detect_val = detect_val.replace(",", "\n");
            } else { 
                ardSend("scan", 0);
                detect_flag = true;
            }
        } else println("No ESELog connected");

        /************************
         *  DATA INPUT BUTTONS  *
         ************************/
    } else if (cmd.equals("OK")) {
        println("Pressed OK");      
        input_flag = true;
        OK = true;
    } else if (cmd.equals("Cancel")) {
        println("Pressed Cancel");            
        input_field.Text = "";
        input_flag = true;
        OK = false;
    }
}

boolean check_filename(String filename) {
    if (filename == "" || filename == null) return false;

    return (filename.indexOf(">") == -1 && filename.indexOf("<")  == -1 && filename.indexOf("\\") == -1 && filename.indexOf("\"") == -1 && filename.indexOf("\'") == -1 
        && filename.indexOf("|") == -1 && filename.indexOf(":") == -1 && filename.indexOf("*") == -1);
}
