import android.Manifest;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.app.Activity;
import android.app.ListActivity;
import android.widget.Toast;
import android.widget.ArrayAdapter;
import android.view.Gravity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;

import android.os.Handler;
import android.os.Message;
import android.util.Log;

import java.io.InputStream;
import java.io.OutputStream;
import java.util.UUID;
import java.util.Set;
import java.util.LinkedList;
import java.util.List;
import java.util.Queue;
import java.util.Calendar; // allows for timestamp creation when saving text file

String BTname = "MOB";
final int MAX_DEVICES = 1;

// Serial Connection
boolean serialConnected = false;
String serialConnectStr = "TAP HERE TO CONNECT";
boolean[] ardSent = new boolean[MAX_DEVICES];
ArrayList<String> ardSentStr = new ArrayList<String>();   // holds last sent String for each device
int serialMode = 0;
boolean[] mobinaatReady = new boolean[MAX_DEVICES];
boolean[] running = new boolean[MAX_DEVICES];

/*
Serial activeCom;
static int BAUD = 115200;
String serialBuffer = "";        // buffer for receiving bytes one at a time
String serialString = "";      // buffer for completed strings indicated by "\r\n"
boolean serialRcv = false;     // true if serialString contains complete string
*/

BluetoothAdapter bluetooth = BluetoothAdapter.getDefaultAdapter();
//BroadcastReceiver receiver = new myOwnBroadcastReceiver();
Set<BluetoothDevice> pairedDevices;  // devices bonded to device through bluetooth 
boolean[] BTConnected = new boolean[MAX_DEVICES];                                             // set max of 2 devices connected for now -- default values = false
ArrayList<ConnectToBluetooth> connectBTs = new ArrayList<ConnectToBluetooth>();
ArrayList<BluetoothSocket> scSockets = new ArrayList<BluetoothSocket>();
ArrayList<SendReceiveBytes> sendReceiveBTs = new ArrayList<SendReceiveBytes>();
ArrayList<String> connectedDevices = new ArrayList<String>();                      // devices currently communicating through bluetooth
ArrayList<deviceHandler> mHandlers = new ArrayList<deviceHandler>();

// Message types used by the Handler
public static final int MESSAGE_WRITE = 1;
public static final int MESSAGE_READ = 2;

ArrayList<String> readMessages= new ArrayList<String>();
ArrayList<Queue<String>> ardSendList = new ArrayList<Queue<String>>();    // holds queue for messages to be sent to arduino for each bluetooth connection


// ESELog Connection
boolean eselog_init = false;

// Logging Data
PrintWriter output;
boolean logging = false;
//String output_file = "";//sketchPath("");
//boolean dirSelected = false;

int OOB = -1; //out of bounds value used to denote no data

void setupBT() {

    act = this.getActivity();
    /*IF Bluetooth is NOT enabled, then ask user permission to enable it */
    if (!bluetooth.isEnabled()) {
        Intent requestBluetooth = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
        this.getActivity().startActivityForResult(requestBluetooth, BLUETOOTH_REQUEST_CODE);
    }

    //act.registerReceiver(receiver, new IntentFilter(BluetoothDevice.ACTION_ACL_DISCONNECTED));

    pairedDevices = bluetooth.getBondedDevices();    // Get all devices already bonded through bluetooth
}

static int BLUETOOTH_REQUEST_CODE = 0;

@Override public void onActivityResult(int requestCode, int resultCode, Intent data) {
    println("Activity result - requestCode = " + requestCode);

    if (requestCode==BLUETOOTH_REQUEST_CODE) {
        if (resultCode == Activity.RESULT_OK) {
            ToastMaster("Bluetooth has been switched ON");
            println("Bluetooth has been switched ON");
        } else {
            ToastMaster("You need to turn Bluetooth ON !!!");
            //println("You need to turn Bluetooth ON !!!");
        }
    }
}

void ToastMaster(String textToDisplay) {
    Toast myMessage = Toast.makeText(this.getActivity().getApplicationContext(), 
        textToDisplay, 
        Toast.LENGTH_LONG);
    myMessage.setGravity(Gravity.CENTER, 0, 0);
    myMessage.show();
}
/*
void handleSerial() {

    ardRead();
    if (serialRcv) {        // full string has been read into buffer
        serialRcv = false;  // reset flag for ardRead();
        println(serialString); 
        ardParse(serialString, serialMode);

        if (detect_flag) serialCmd("fluoTest");
    }
}
*/

void handleSerial(String msg, int device) {
    writeFile(logwriters.get(device), msg+"\n");
    // Check if a command has been sent to the arduino and correctly received
    if (ardSent[device]) {
        if (ardSentStr.get(device).equals(msg)) {
            if (ardSendList.get(device).size()>0) {
                if (ardSentStr.get(device).equals(ardSendList.get(device).peek())) {    // ardSentStr stores most recently sent string to android. ardSendList contains queues of strings needing to be sent
                    ardSendList.get(device).remove();
                }
            }
            ardSent[device] = false;
            return;
        } else {
            // Resend string if msg does not match sent string
            delay(500);
            ardSend(ardSentStr.get(device), device);
        }
    }
    else{
     ardParse(msg, serialMode);   
    }

}

// Reads until \n character -- stores result in serialOutput
/*
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
*/

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
                    //export(output_file+"-bis");
                    if (!cycle_flag && !mag_flag) autorun = false;
                    else if (magSwitch.state) {
                        println("Starting Magnetofluidic Processing.");
                        mag_flag = true;
                        ardSend("mag",0);
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
                    //export(output_file + "-pcr");
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
                
                for (int i = 1; i < 7; i++) {                 
                    fluo_pt[i][0] = parseFloat(data[i-1]);                    
                }
                writeFile(writers.get(displayDevice), fluo_pt[1][0] + "," + fluo_pt[2][0] + "," + fluo_pt[3][0] + "," + fluo_pt[4][0] + "," + fluo_pt[5][0] + "," + fluo_pt[6][0] + "\n");
                fluo_plotter.loadData(fluo_pt);
            }
        }
    }
}

void connectSerial(/*Set<BluetoothDevice> devices, String BTname*/) {
    eselogConnected = false;
    eselogInit = false;
    motorsInit = false;
    serialMode =0;
    
    for (BluetoothDevice bt : pairedDevices) {
        println("Checking connection with ... " + bt.getName());
        if (bt.getName().equals(BTname)) {
            println("Attempting to connect to "+ bt.getName());
            ConnectToBluetooth connectBT = new ConnectToBluetooth(bt);
            //Connect to the the device in a new thread
            new Thread(connectBT).start();     
            connectBTs.add(connectBT);
            long startTime = System.currentTimeMillis();

            FileWriter logwriter = openFile("log.temp", logDir, false, true);
            logwriters.add(logwriter);
            FileWriter writer = openFile("temp", fileDir, false, true);
            writers.add(writer);

            filenames.add("");

            while (scSockets.size() != connectBTs.size()) {         // socket added to scSockets in connectToBluetooth runnable
                if (System.currentTimeMillis() - startTime > 5000) {  // wait 3 seconds before cancelling connection attempt
                    connectBTs.remove(connectBTs.size()-1);
                    logwriters.remove(logwriters.size()-1);
                    filenames.remove(filenames.size()-1);
                    displayAlert(5);
                    return;
                }
            }

            int _device = connectBTs.size()-1;
            
            /*
            runmodes_init.add(new LinkedList<String>());
            runmodes.add(new LinkedList<String>());
            mode.add("");
            */
            readMessages.add("");
            Queue<String> ardSendMessages =  new LinkedList<String>();
            ardSendList.add(ardSendMessages);
            ardSentStr.add("");

            // Setup Handler for receiving/sending messages
            mHandlers.add(new deviceHandler(_device));

            SendReceiveBytes sendReceiveBT = new SendReceiveBytes(scSockets.get(_device), _device);
            new Thread(sendReceiveBT).start();
            sendReceiveBT.write("<reset>");
            sendReceiveBTs.add(sendReceiveBT);
            connectedDevices.add(BTname);
            BTConnected[_device] = true;

            //addDeviceButton(_device);

            // Initialize and add new plot objects
            //setupPlotDisplay();
            serialConnectStr = "CONNECTED";
            serialConnected = true;
            break;
        }
    }
    serialConnectStr = "TAP HERE TO CONNECT";
}

/*
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
                        if (serialString.contains("<Arduino is ready>")) {
                            println("Serial Connected.");
                            serialConnectStr = "CONNECTED";
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
}*/


public class ConnectToBluetooth implements Runnable {
    private BluetoothDevice btShield;
    private BluetoothSocket mySocket = null;
    private UUID uuid = UUID.fromString("63c6250b-0259-43b3-a01b-b02f0e31c882");

    public ConnectToBluetooth(BluetoothDevice bluetoothShield) {
        btShield = bluetoothShield;
        try {
            mySocket = btShield.createRfcommSocketToServiceRecord(uuid);
        }
        catch(IOException createSocketException) {
            //Problem with creating a socket
        }
    }

    /*@Override*/    public void run() {

        try {
            /*Connect to the bluetoothShield through the Socket. This will block
             until it succeeds or throws an IOException */
            mySocket.connect();
            scSockets.add(mySocket);
            println("Socket Connected: scSockets size = " + scSockets.size());
            return;
        } 
        catch (IOException connectException) {
            try {
                mySocket.close(); //try to close the socket
                println("Socket Closed: " + connectException);
                //BTConnected = false;
            }
            catch(IOException closeException) {
            }
            return;
        }
    }

    /* Will cancel an in-progress connection, and close the socket */
    public void cancel() {
        try {
            mySocket.close();
            //BTConnected = false;
        } 
        catch (IOException e) {
        }
    }
}

void onPause() { 
    super.onPause();
}


public class deviceHandler {
    private Handler mHandler;
    public int device;

    public deviceHandler(int _device) {
        device = _device;
        mHandler = new Handler(android.os.Looper.getMainLooper()) {
            private StringBuilder sb = new StringBuilder();
            @Override public void handleMessage(Message msg) {
                switch (msg.what) {
                case MESSAGE_WRITE:
                    //Do something when writing
                    break;
                case MESSAGE_READ:
                    //Get the bytes from the msg.obj
                    byte[] readBuf = (byte[]) msg.obj;
                    // construct a string from the valid bytes in the buffer
                    String strIncom = new String(readBuf, 0, msg.arg1);                 // create string from bytes array

                    sb.append(strIncom);                                                // append string
                    //println("sb: \t" + sb);

                    // Handle both NL and CR
                    while (sb.indexOf("\r\n") > 0 || (sb.lastIndexOf("\n")>0 && sb.indexOf("\r")!=0)) {
                        int rnidx = sb.indexOf("\r\n");
                        int nidx = sb.indexOf("\n") >0 ? sb.indexOf("\n") : sb.substring(1, sb.length()).indexOf("\n");
                        //println("rnidx:"+rnidx +"\tnidx:"+nidx);
                        int endOfLineIndex = rnidx;          // determine the end-of-line
                        if (rnidx<0 || (nidx < rnidx && nidx >0)) {
                            endOfLineIndex = nidx;
                            if (sb.indexOf("\n") == 0) {
                                endOfLineIndex = sb.substring(1, sb.length()).indexOf("\n")+1;
                                readMessages.set(device, sb.substring(1, endOfLineIndex));               // extract string
                            } else {
                                readMessages.set(device, sb.substring(0, endOfLineIndex));
                            }
                            sb.delete(0, endOfLineIndex);
                            println(connectedDevices.get(device) + "\treadMessage:\t" + readMessages.get(device));
                            handleSerial(readMessages.get(device), device);
                        } else {
                            if (sb.indexOf("\n") == 0) {
                                readMessages.set(device, sb.substring(1, endOfLineIndex));               // extract string
                            } else {
                                readMessages.set(device, sb.substring(0, endOfLineIndex));
                            }
                            sb.delete(0, endOfLineIndex+1);
                            println(connectedDevices.get(device) + "readMessage:\t" + readMessages.get(device));
                            handleSerial(readMessages.get(device), device);
                        }
                    }
                    break;
                }
            }
        };
    }

    public Handler get() {
        return mHandler;
    }
}

public class SendReceiveBytes implements Runnable {
    private BluetoothSocket btSocket;
    private InputStream btInputStream = null;
    private OutputStream btOutputStream = null;
    public int device;
    String TAG = "SendReceiveBytes";

    public SendReceiveBytes(BluetoothSocket socket, int _device) {
        btSocket = socket;
        device = _device;
        try {
            btInputStream = btSocket.getInputStream();
            btOutputStream = btSocket.getOutputStream();
            println("IO Streams established");
        } 
        catch (IOException streamError) { 
            println("STREAMERROR");
            Log.e(TAG, "Error when getting input or output Stream");
        }
    }

    public void run() {
        byte[] buffer = new byte[1024]; // buffer store for the stream
        int bytes; // bytes returned from read()
        println("Running SendReceiveBytes thread");
        // Keep listening to the InputStream until an exception occurs
        while (true) {
            try {
                // Read from the InputStream
                bytes = btInputStream.read(buffer);
                // Send the obtained bytes to the UI activity
                Handler mHandler = mHandlers.get(device).get();    // returns Handler from array of deviceHandlers
                mHandler.obtainMessage(MESSAGE_READ, bytes, -1, buffer).sendToTarget();
            } 
            catch (IOException e) {
                Log.e(TAG, "Error reading from btInputStream");
                break;
            }
            delay(50);
        }
    }

    /* Call this from the main activity to send data to the remote device */
    public void write(String msg) {
        try {
            btOutputStream = btSocket.getOutputStream();
            btOutputStream.write(stringToBytes(msg));
        } 
        catch (IOException e) { 
            Log.e(TAG, "Error when writing to btOutputStream");
        }
    }



    /* Call this from the main activity to shutdown the connection */
    public void cancel() {
        try {
            btSocket.close();
        } 
        catch (IOException e) { 
            Log.e(TAG, "Error when closing the btSocket");
        }
    }
}


// Send command to arduino
/*
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
*/
public void ardSend(String str, int device) {
    if (ardSent[device] && !str.equals(ardSentStr.get(device))) {
        // Add message to queue if currently sending another message and not trying to resend the same message
        ardSendList.get(device).add(str);
        println("Added to ardSendMessages Queue: " + str);
    } else if (sendReceiveBTs.get(device) !=null) {
        SendReceiveBytes sendReceiveBT = sendReceiveBTs.get(device);
        println("Sending: \t" + str);
        //byte[] byteStr = stringToBytesUTFCustom(str);
        //byte[] byteStr = str.getBytes();

        //Send string in packets of 10 characters
        sendReceiveBT.write("<");
        if (str.length() < 16) sendReceiveBT.write(str);
        else {
            for (int i = 0; i<str.length(); i+=16) {
                sendReceiveBT.write(str.substring(i, i+10>str.length() ? str.length() : i+10));
                println("Sent: " + str.substring(i, i+10>str.length() ? str.length() : i+10));
            }
        }
        sendReceiveBT.write(">");

        ardSent[device] = true;
        ardSentStr.set(device, str);
        delay(100);
    }
}


public byte[] stringToBytes(String str) {
    char[] buffer = str.toCharArray();
    byte[] b = new byte[buffer.length << 1];
    for (int i = 0; i < buffer.length; i++) {
        int bpos = i << 1;
        b[bpos] = (byte) ((buffer[i]&0xFF00)>>8);
        b[bpos + 1] = (byte) (buffer[i]&0x00FF);
    }
    return b;
}

/*
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
    output.println("Time (sec),CH1,CH2,CH3,CH4,CH5,CH6");    // header
    strbuff = "";

    for (int i = 0; i < fluo_plotter.n_pts; i++) {
        strbuff = "";
        for (int p = 0; p < 7; p++) {
            strbuff += fluo_plotter.data[p][i];
            if (p<6) strbuff += ",";
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
        output.println("Cycle,CH1,CH2,CH3,CH4,CH5,CH6");    // header
        strbuff = "";

        for (int i = 0; i < fluo_plotter.n_pts; i++) {
            strbuff = "";
            for (int p = 0; p < 7; p++) {
                strbuff += fluo_plotter.data[p][i];
                if (p<6) strbuff += ",";
            }
            output.println(strbuff);
        }
        output.flush();
        output.close();
    }
}
*/


String timestamp() {
    Calendar now = Calendar.getInstance();
    return String.format("%1$ty%1$tm%1$td_%1$tH%1$tM%1$tS", now);
}
