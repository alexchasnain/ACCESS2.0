import java.util.Calendar;

File fileDir;
File logDir;
String storageFolder = "/MOB";
String logFolder = "/MOB/logs";

ArrayList<FileWriter> writers = new ArrayList<FileWriter>();
ArrayList<FileWriter> logwriters = new ArrayList<FileWriter>();
ArrayList<String> filenames = new ArrayList<String>();

boolean[] fileOpened =new boolean[MAX_DEVICES];

public void setupFileDir() {
    fileDir = new File(Environment.getExternalStorageDirectory() + storageFolder);
    if (!fileDir.isDirectory()) {  // make directory for file storage if it doesn't exist already
        fileDir.mkdir();
        println("Making new directory: " + fileDir.toString());
    }  
    logDir = new File(Environment.getExternalStorageDirectory() + logFolder);
    if (!logDir.isDirectory()) {  // make directory for file storage if it doesn't exist already
        logDir.mkdir();
        println("Making new directory: " + logDir.toString());
    }
}

public FileWriter openFile(String filename, File dir, boolean append, boolean overwrite) {

    // Check if filename has .txt at end
    if (filename.length() > 4) {
        if (filename.substring(filename.length()-4).equals(".txt")) {
            filename = filename.substring(0, filename.length()-4);
        }
    }

    try {
        File myFile = new File(dir, filename + ".txt");
        int i = 2;
        while (myFile.exists() && !overwrite) {
            myFile = new File(dir, filename + '-' + i + ".txt");
            i++;
        }
        if (filename.length() < 3 || (!filename.substring(0, 3).equals("log") && !filename.substring(0, 4).equals("temp"))) {
            filename = myFile.getName();
        }

        if (i>2) {
            println("File " + filename + " already exists. Opening new file: " + myFile.toString());      
            displayAlert(6);
        }

        FileWriter writer = new FileWriter(myFile, append);

        /*writer.append("First string is here to be written.");
         writer.flush();
         writer.close();
         */
        return writer;
    }
    catch( Exception e) {
        println(e);
        return null;
    }
}

public void writeFile(FileWriter writer, String str) {
    try {
        writer.append(str);
        writer.flush();
    }
    catch(Exception e) {
        println(e);
    }
}

public void closeFiles(int device) {
    try {
        writers.get(device).flush();
        writers.get(device).close();

        logwriters.get(device).flush();
        logwriters.get(device).close();

        fileOpened[device] = false;

        FileWriter logwriter = openFile("log.temp", logDir, false, true);
        logwriters.set(device, logwriter);
        FileWriter writer = openFile("temp", fileDir, false, true);
        writers.set(device, writer);

        filename = filenames.get(device);
    }
    catch(Exception e) {
        println(e);
    }
}
