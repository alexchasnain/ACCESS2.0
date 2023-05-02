/********************************************
 *  Default Display -- present in all modes *
 ********************************************/

void displayDefault() {    
    // Display Text
    fill(txtColor);
    textFont(titleFont);
    textAlign(CENTER, CENTER);
    text(title, width/2, height/30);

    // Display Connected Status
    if (serialConnected) {
        fill(color(0, 255, 0));
        textFont(titleFont);
        textAlign(RIGHT, BOTTOM);
        text(serialConnectStr, width, height);
    } else {
        fill(color(255, 0, 0));
        textFont(titleFont);
        textAlign(RIGHT, BOTTOM);
        text(serialConnectStr, width, height);
    }

    // Display Buttons
    for (Button b : defaultButtons) {
        //buttonBuffer = buttonList[i]; 
        b.display();
    }
    if (readMessages.size() >0) {
        text("Log: \t" +readMessages.get(displayDevice), width/10, height - textAscent() * 1.1);
    }
}

/**********************************
 *  displayMode == -1  Text input *
 **********************************/
void displayInputField() {
    input_field.DRAW();    // draw input textfield

    fill(txtColor);
    textFont(titleFont);
    textAlign(LEFT, CENTER);
    text("Current setting:", width/7, height*1/6);


    fill(txtColor);
    textFont(titleFont);
    textAlign(LEFT, CENTER);
    text(input_ID.replace("\n", "\t"), width/7, height/4);


    for (Button b : inputButtons) {
        //buttonBuffer = buttonList[i]; 
        b.display();
    }
}

/**********************************
 *  displayMode == 0  HOME SCREEN *
 **********************************/
void displayHome() {
    fill(txtColor);
    textFont(titleFont);
    textAlign(LEFT, CENTER);
    text("Bisulfite Conversion", width/7, height/7);

    fill(txtColor);
    textFont(titleFont);
    textAlign(LEFT, CENTER);
    text("Magnet Processing", width/7, height/7+height/12);

    fill(txtColor);
    textFont(titleFont);
    textAlign(LEFT, CENTER);
    text("PCR Thermal Cycling", width/7, height/7+height*2/12);

    fill(txtColor);
    textFont(titleFont);
    textAlign(LEFT, CENTER);
    text("Fluorescence", width/7, height/7+height*3/12);

    //temp_plotter.display();
    fluo_plotter.display();

    /*
    fill(txtColor);
     textFont(labelFont);
     textAlign(LEFT, BOTTOM);
     //text("Filename:", width/5, height/2);
       */
     textFont(labelFont);
     textAlign(LEFT, CENTER);
     text(filename, width/3, height/2-height/40);
   
    textAlign(LEFT, TOP);
    textFont(labelFont);
    text("Time: " + String.format("%.02f", temp_pt[1][0]/60) + " min.", width/20, height*3/4+height/20);
    text("Temp.: " + temp_pt[0][0] + "C", width/20 + width/3, height*3/4+height/20);
    if (pcrSwitch.state) {
        text("Current Cycle: " + (fluo_plotter.n_pts), width/20+width/3+ width/4, height*3/4 + height/20);
    }

    // Display Buttons
    for (Button b : homeButtons) {
        //buttonBuffer = buttonList[i]; 
        b.display();
    }
}

/*****************************************
 *  displayMode == 1 Bisulfite Options *
 *****************************************/
void displayBis() {
    fill(txtColor);
    textFont(labelFont);
    textAlign(CENTER, CENTER);
    text("Enzymatic Digestion", width/2, height/6-height/12);

    fill(txtColor);
    textFont(labelFont);
    textAlign(CENTER, CENTER);
    text("DNA Denaturation", width/2, height/4);

    fill(txtColor);
    textFont(labelFont);
    textAlign(CENTER, CENTER);
    text("Sulfonation and Deamination", width/2, height/2-height/12);

    fill(txtColor);
    textFont(labelFont);
    textAlign(CENTER, CENTER);
    text("Particle Binding", width/2, height*4/6-height/12);

    // Display Buttons
    for (Button b : bisButtons) {
        b.display();
    }
}
/*****************************************
 *  displayMode == 2 PCR Options *
 *****************************************/
void displayPCR() {
    // Display Buttons
    for (Button b : pcrButtons) {
        b.display();
    }
}

/*****************************************
 *  displayMode == 3 Fluorescence Screen *
 *****************************************/
void displayFluo() {
    fill(txtColor);
    textFont(labelFont);
    textAlign(CENTER, CENTER);
    text("LED1\n" + LED1_nm + "nm", width/6, height/6+height/10);

    fill(txtColor);
    textFont(labelFont);
    textAlign(CENTER, CENTER);
    text("LED2\n"+LED2_nm + "nm", width/6+width/7, height/6+height/10);

    fill(txtColor);
    textFont(labelFont);
    textAlign(CENTER, CENTER);
    text("Detection Mode: " + detect_methods[method_type], width/2+width/7, height/6+height*1/10);

    fill(#808080);    // background for reported TEST value
    rectMode(CENTER);
    rect((width/6 + width*3/7+width/5), height/2+height/5, width/5, height/3);

    fill(txtColor);
    textFont(detectFont);
    textAlign(CENTER, CENTER);
    if (eselogConnected) {
        text(detect_val, (width/6 + width*3/7+width/5), height/2+height/5);
    } else {
        textFont(labelFont);
        text("Not Connected", (width/6 + width*3/7+width/5), height/2+height*1/10);
    }
    // Display Buttons
    for (Button b : fluoButtons) {
        //buttonBuffer = buttonList[i]; 
        b.display();
    }
}

/*****************************************
 *  displayMode == 4 Magnet Carriage Setup *
 *****************************************/
void displayMag() {
    // Display Buttons
    for (Button b : magXButtons) {
        b.display();
    } 
    for (Button b : magZButtons) {
        b.display();
    }
}

/*****************************************
 * ALERTS -- layered over other displays *
 *****************************************/
void displayAlert(int _alertID) {
    alert_flag = true;
    alertID = _alertID; 
    String alert = alerts[_alertID];
    int n_chars = alert.length();
    int lines = 1;
    for (int i =0; i< n_chars; i++) {
        if (alert.charAt(i) == '\n') lines++;
    }
    fill(txtColor);
    textFont(alertFont);
    //int fs = 600/(n_chars/lines);
    if (n_chars/lines > 30) textSize(28);
    textAlign(CENTER, CENTER);
    text(alert, width/2, height/3);
    //println(fs);

    fill(txtColor);
    textSize(18);
    textAlign(CENTER, CENTER);
    text("\n\n\nPress Screen to Continue", width/2, height/2);
}

String[] alerts = new String[]{
    "ESOPHACAP NAAT", // 0
    "Resetting magnet platter.", // 1
    "E1D2", // 2
    "E2D2", // 3
    "E1D1+E1D2", // 4
    "Could not connect to Bluetooth", // 5
    "File already exists. Note updated filename.", // 6
    "Please connect to device."
};
