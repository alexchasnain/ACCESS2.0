import java.util.Calendar; // allows for timestamp creation when saving text file

// Serial Connection
boolean serialConnected = false;
String serialConnectStr = "NOT CONNECTED";
Serial activeCom;
static int BAUD = 115200;
String serialBuffer = "";        // buffer for receiving bytes one at a time
String serialString = "";      // buffer for completed strings indicated by "\r\n"
boolean serialRcv = false;     // true if serialString contains complete string
int serialMode = 0;

// ESELog Connection
boolean eselog_init = false;

// Logging Data
PrintWriter output;
boolean logging = false;
String output_file = "";//sketchPath("");
boolean dirSelected = false;

int OOB = -1; //out of bounds value used to denote no data

void handleSerial() {

    ardRead();
    if (serialRcv) {        // full string has been read into buffer
        serialRcv = false;  // reset flag for ardRead();
        println(serialString); 
        ardParse(serialString, serialMode);

        if (detect_flag) serialCmd("fluoTest");
    }
}

// Send command to arduino
void ardSend(String msg) {
    if (serialConnected) {        
        String bracketmsg = "<" + msg + ">";

        while (!serialString.equals(msg)) {
            activeCom.write(bracketmsg);
            println("ARDSEND: " + bracketmsg);
            delay(200);
            for (int i = 0; i < 100; i++) {
                ardRead(); 
                if (serialString.equals(msg)) {
                    break;
                }
            }
        }
    } else {
        println("Not Connected. " + msg + " not sent.");
    }
}

// Reads until \n character -- stores result in serialOutput
void ardRead() {
    if (activeCom.available()>0) {
        char c = activeCom.readChar();    // 10 = linefeed in AsCII
        serialBuffer += c;
        if (c == '\n') {
            if (serialBuffer.length()>=2) serialString = serialBuffer.substring(0, serialBuffer.length()-2); // remove \r\n
            else serialString = serialBuffer;
            serialBuffer = "";
            serialRcv = true;
        }
    }
}
void ardParse(String serialString, int serialMode) {
    /*
   *  Checks serial output from Arduino to verify status or log data
     *    Mode = 0 -- default setting (checks if ESELog is connected)
     *    Mode = 1 -- data logging
     *
     *
     */

    if (serialMode ==0) {  // default mode without any operations running
        if (serialString.equals("ESELog Connected")) {
            //println("Tested:" + serialString);
            eselogConnected = true;
        }
        if(serialString.equals("<Arduino is ready>")){
            serialConnectStr = "CONNECTED";
        }
    } else if (serialMode ==1) {  
        if (!logging) {
            if (serialString.equals("*")) {
                //println("Tested:" + serialString);
                logging = true;
            }
        } else {  // start logging data
            if (serialString.equals("*")) {  // asterisk marks end and beginning of function
                logging = false;
                serialMode = 0;  // return to default serialMode

                // Write to files if completed and call subsequent automated runs
                if (bisCon_flag && autorun) {
                    bisCon_flag = false;
                    export(output_file+"-bis");
                    if (!cycle_flag && !mag_flag) autorun = false;
                    else if (magSwitch.state) {
                        println("Starting Magnetofluidic Processing.");
                        mag_flag = true;
                        ardSend("mag");
                        serialMode = 1;
                    } else if (pcrSwitch.state) {
                        println("Starting PCR.");
                        cycle();
                    }
                } else if (mag_flag && autorun) {
                    mag_flag = false;
                    if (cycle_flag && autorun) {
                        println("Starting PCR.");
                        cycle();
                    } else {
                        autorun = false;
                    }
                } else if (cycle_flag && autorun) {
                    cycle_flag = false;
                    autorun = false;
                    export(output_file + "-pcr");
                }
                return;
            }
            String[] data = split(serialString, ',');
            if (data.length == 2) {  // Time, Temp
                for (int i = 0; i<2; i++) {
                    temp_pt[i][0] = parseFloat(data[i]);
                }
                /*
        for (int i = 2; i<n_plots+1; i++) {
                 
                 //if (plotter.n_pts == 0) pt[i][0] = 0;
                 // else pt[i][0] = plotter.data[i][plotter.n_pts-1];
                 
                 pt[i][0] = OOB;
                 }
                 */
                temp_plotter.loadData(temp_pt);
            } else if (data.length > 2) {  // Detection Points (F1, F2, F3 ...)
                //fluo_pt[0][0] = temp_plotter.data[0][temp_plotter.n_pts-1];  // Use last time pt
                fluo_pt[0][0] = fluo_plotter.n_pts +1;

                for (int i = 1; i < 5; i++) {
                    fluo_pt[i][0] = parseFloat(data[i-1]);
                }
                fluo_plotter.loadData(fluo_pt);
            }
        }
    }
}

void connectSerial() {
    if (serialConnected) {
        activeCom.stop();    // stop connections if already connected
        serialConnected = false;
    }    
    //serialConnectStr = "CONNECTING...";
    eselogConnected = false;
    eselogInit = false;
    motorsInit = false;
    serialMode =0;
    // scans through all comports -- checks for arduino  
    String[] comports = Serial.list();
    println("Comports available: " + comports.length);
    for (int i = 0; i < comports.length; i++) {
        if (!serialConnected) {  
            try {
                activeCom = new Serial(this, comports[i], BAUD);
                delay(2000);    // wait for connection
                while (activeCom.available() >0) {
                    ardRead();
                    if (serialRcv) {
                        serialRcv = false;
                        println(comports[i] + " output: " + serialString);
                        if (serialString.contains("<Arduino Connected>")) {
                            println("Serial Connected.");
                            serialConnectStr = "Establishing Connection...";
                            serialConnected = true;
                            break;
                        }
                    }
                }
            }
            catch(Exception e) {
                System.err.println("Failed to connect to " + comports[i]);
                serialConnectStr = "NOT CONNECTED";
                continue;
            }
        }
    }
}

void saveData() {
    // calls assign_filename function to pass selected filename to output_file_input
    selectOutput("Select a file to write to:", "export");
}

void selectDir() {
    selectOutput("Select a file to write to:", "openFile");
}

void openFile(File selection) {
    if (selection == null) {
        println("Window was closed or the user hit cancel.");
        output_file = "";
        //return;
    } else {
        output_file = selection.getAbsolutePath();
    }
    dirSelected = true;
}

void export(String filename) {
    println("Exporting file: "+ filename);
    output_file = filename;

    String output_file_temp = output_file + "-temp.csv";
    String output_file_fluo = output_file + "-fluo.csv";

    println("User selected " + output_file);

    output = createWriter(output_file_temp);
    output.println("% " + output_file + " Created: " + timestamp());
    output.println("Time (sec),Temperature (°C)");    // header
    String strbuff = "";

    for (int i = 0; i < temp_plotter.n_pts; i++) {
        strbuff = "";
        for (int p = 0; p < 2; p++) {
            strbuff += temp_plotter.data[p][i];
            if (p<1) strbuff += ",";
        }
        output.println(strbuff);
    }
    output.flush();
    output.close();

    if (fluo_plotter.n_pts<=1) { 
        return;
    }

    output = createWriter(output_file_fluo);
    output.println("% " + output_file + " Created: " + timestamp());
    output.println("Time (sec),CH1,CH2,CH3,CH4");    // header
    strbuff = "";

    for (int i = 0; i < fluo_plotter.n_pts; i++) {
        strbuff = "";
        for (int p = 0; p < 5; p++) {
            strbuff += fluo_plotter.data[p][i];
            if (p<4) strbuff += ",";
        }
        output.println(strbuff);
    }
    output.flush();
    output.close();
}

void export(File selection) {
    if (selection == null) {
        println("Window was closed or the user hit cancel.");
        return;
    } else {
        output_file = selection.getAbsolutePath();
        //filename.setText(output_file_input);
        println("User selected " + output_file);
        String output_file_temp = output_file + "-temp.csv";
        String output_file_fluo = output_file + "-fluo.csv";
        output = createWriter(output_file_temp);
        output.println("% " + output_file_temp + " Created: " + timestamp());
        output.println("Time (sec),Temperature (°C)"); // header


        String strbuff = "";
        for (int i = 0; i < temp_plotter.n_pts; i++) {
            strbuff = "";
            for (int p = 0; p < 2; p++) {
                strbuff += temp_plotter.data[p][i];
                if (p<1) strbuff += ",";
            }
            output.println(strbuff);
        }
        output.flush();
        output.close();

        if (fluo_plotter.n_pts<=1) { 
            return;
        }

        output = createWriter(output_file_fluo);
        output.println("% " + output_file + " Created: " + timestamp());
        output.println("Cycle,CH1,CH2,CH3,CH4");    // header
        strbuff = "";

        for (int i = 0; i < fluo_plotter.n_pts; i++) {
            strbuff = "";
            for (int p = 0; p < 5; p++) {
                strbuff += fluo_plotter.data[p][i];
                if (p<4) strbuff += ",";
            }
            output.println(strbuff);
        }
        output.flush();
        output.close();
    }
}


String timestamp() {
    Calendar now = Calendar.getInstance();
    return String.format("%1$ty%1$tm%1$td_%1$tH%1$tM%1$tS", now);
}
