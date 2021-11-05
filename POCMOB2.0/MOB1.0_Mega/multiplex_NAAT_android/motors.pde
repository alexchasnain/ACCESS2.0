
int xpos = 0;// 0 = as far towards the bisulfite well as possible, 212 at PCR well
int xFirst = 78;
int xWells = 32;
int xPCR = 42;


boolean motorsInit = false;
boolean mag_flag = false; // tracks if mag switch on for autorun and hasn't been processed yet
void setupMotors(){
 //ardSend("x"+Integer.toString(-10)); // move magnets to pcr well to open space for putting in cartridge
 motorsInit = true;
 ardSend("reset",0);
}

void moveXmotor(String cmd){
  if(!motorsInit) return;
  String well = "";
  //int tgtpos = 0;
  if(cmd.equals("resetMag")){
   setupMotors(); 
  }
  else if(cmd.equals("bisMag")){
    //tgtpos = 0; // distance from sample inlet to bisulfit well
    well = "w1";
  }
  else if(cmd.equals("w1Mag")){
    //tgtpos = xFirst; // distance from sample inlet to bisulfit well
    well = "w2";
  }
  else if(cmd.equals("w2Mag")){
    //tgtpos = xFirst + xWells; // distance from sample inlet to bisulfit well
    well = "w3";
  }
  else if(cmd.equals("w3Mag")){
    //tgtpos = xFirst + 2*xWells; // distance from sample inlet to bisulfit well
    well = "w4";
  }
  else if(cmd.equals("w4Mag")){
    //tgtpos = xFirst + 3*xWells; // distance from sample inlet to bisulfit well
    well = "w5";
  }
  else if(cmd.equals("pcrMag")){
    //tgtpos = xFirst + 3*xWells+xPCR; // distance from sample inlet to bisulfit well
    well = "w6";
  }
  
  //int movepos = tgtpos-xpos;
  //if(movepos<0) movepos -= 1; // go farther in reverse to account for overshoot when moving forward
  //ardSend("x" + Integer.toString(movepos));
  ardSend(well,0);
  //xpos = tgtpos;
    
}

void moveZmotor(String cmd){
  if(cmd.equals("tMag")){
    ardSend("top",0);
  }

  else if(cmd.equals("bMag")){
    ardSend("bottom",0);
  }
    
}
