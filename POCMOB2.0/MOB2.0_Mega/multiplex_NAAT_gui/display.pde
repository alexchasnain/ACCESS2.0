/********************************************
 *  Default Display -- present in all modes *
 ********************************************/

void displayDefault() {    
    // Display Text
    fill(txtColor);
    textFont(titleFont);
    textAlign(CENTER, CENTER);
    text(title, _W/2, _H/30);

    // Display Connected Status
    if (serialConnected) {
        fill(color(0, 255, 0));
        textFont(labelFont);
        textAlign(RIGHT, BOTTOM);
        text(serialConnectStr, _W, _H);
    } else {
        fill(color(255, 0, 0));
        textFont(labelFont);
        textAlign(RIGHT, BOTTOM);
        text(serialConnectStr, _W, _H);
    }

    // Display Buttons
    for (Button b : defaultButtons) {
        //buttonBuffer = buttonList[i]; 
        b.display();
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
    text("Current setting:", _W/7, _H*1/6);


    fill(txtColor);
    textFont(titleFont);
    textAlign(LEFT, CENTER);
    text(input_ID.replace("\n","\t"), _W/7, _H/4);


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
    text("Bisulfite Conversion", _W/7, _H/7);

    fill(txtColor);
    textFont(titleFont);
    textAlign(LEFT, CENTER);
    text("Magnet Processing", _W/7, _H/7+_H/12);

    fill(txtColor);
    textFont(titleFont);
    textAlign(LEFT, CENTER);
    text("PCR Thermal Cycling", _W/7, _H/7+_H*2/12);

    fill(txtColor);
    textFont(titleFont);
    textAlign(LEFT, CENTER);
    text("Fluorescence Detection", _W/7, _H/7+_H*3/12);
    
    //temp_plotter.display();
    fluo_plotter.display();
    
    fill(txtColor);
    textFont(labelFont);
    textAlign(LEFT, BOTTOM);
    //text("Filename:", _W/5, _H/2);
    textFont(labelFont);
    textAlign(CENTER, BOTTOM);
    text(output_file, _W/2, _H/2);
    
    textAlign(LEFT, TOP);
    textFont(labelFont);
    text("Time: " + String.format("%.02f", temp_pt[0][0]/60) + " min.", _W/20, _H*3/4+_H/20);
    text("Temp.: " + temp_pt[1][0] + "C", _W/20 + _W/3, _H*3/4+_H/20);
    if (pcrSwitch.state) {
        text("Current Cycle: " + (fluo_plotter.n_pts), _W/20+_W/3+ _W/4, _H*3/4 + _H/20);
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
 void displayBis(){
    fill(txtColor);
    textFont(labelFont);
    textAlign(CENTER, CENTER);
    text("Enzymatic Digestion", _W/2, _H/6-_H/12);
     
     fill(txtColor);
    textFont(labelFont);
    textAlign(CENTER, CENTER);
    text("DNA Denaturation", _W/2, _H/4);
    
    fill(txtColor);
    textFont(labelFont);
    textAlign(CENTER, CENTER);
    text("Sulfonation and Deamination", _W/2, _H/2-_H/12);
    
    fill(txtColor);
    textFont(labelFont);
    textAlign(CENTER, CENTER);
    text("Particle Binding", _W/2, _H*4/6-_H/12);
    
   // Display Buttons
    for (Button b : bisButtons) {
        b.display(); 
    }
 }
 /*****************************************
 *  displayMode == 2 PCR Options *
 *****************************************/
void displayPCR(){
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
    text("LED1\n" + LED1_nm + "nm", _W/6, _H/6+_H/10);

    fill(txtColor);
    textFont(labelFont);
    textAlign(CENTER, CENTER);
    text("LED2\n"+LED2_nm + "nm", _W/6+_W/7, _H/6+_H/10);

    fill(txtColor);
    textFont(labelFont);
    textAlign(CENTER, CENTER);
    text("Detection Mode: " + detect_methods[method_type], _W/2+_W/7, _H/6+_H*1/10);

    fill(#808080);    // background for reported TEST value
    rectMode(CENTER);
    rect((_W/6 + _W*3/7+_H/5), _H/2+_H/5, _H/5, _H/3);


    fill(txtColor);
    textFont(detectFont);
    textAlign(CENTER, CENTER);
    if (eselogConnected) {
        text(detect_val, (_W/6 + _W*3/7+_H/5),  _H/2+_H/5);
    } else {
        textFont(labelFont);
        text("Not Connected", (_W/6 + _W*3/7+_H/5), _H/2+_H*1/10);
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
 void displayMag(){
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
 void displayAlert(int alertID){
   String alert = alerts[alertID];
   int n_chars = alert.length();
   int lines = 1;
   for(int i =0; i< n_chars; i++){
     if(alert.charAt(i) == '\n') lines++;
   }
   fill(txtColor);
   textFont(alertFont);
   //int fs = 600/(n_chars/lines);
   if(n_chars/lines > 30) textSize(28);
   textAlign(CENTER, CENTER);
   text(alert, _W/2, _H/3);
   //println(fs);
   
   fill(txtColor);
   textSize(18);
   textAlign(CENTER, CENTER);
   text("\n\n\nPress Enter to Continue", _W/2, _H/2);
 }
 
 String[] alerts = new String[]{
 "ESOPHACAP NAAT",
 "Resetting magnet platter.",
 "E1D2",
 "E2D2", 
 "E1D1+E1D2"
 };
