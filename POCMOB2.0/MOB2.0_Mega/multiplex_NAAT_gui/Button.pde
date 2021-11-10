void setupButtons() {
    /********************
     *  default buttons *
     ********************/
    // Set up default buttons
    home_icon = loadImage("imgs/home_white.png");
    hButton = new ImageButton(home_icon, _W/20, _H/20, _W/20, _H/20, color(255), buttonOverColor, color(255)); 
    hButton.func = "home";
    hButton.locking = false;
    defaultButtons.add(hButton);

    serialButton = new RectButton(_W-_W/8, _H-_H/40, _W/4, _H/20, color(255, 0), color(255, 50), buttonOnColor);
    serialButton.locking = false;
    serialButton.func = "serial";
    defaultButtons.add(serialButton);

    /***********************
     *  Input buttons *
     ***********************/

    OKButton = new RectButton(_W/6+_W/10, _H/2, _W/5, _H/10, buttonOffColor, buttonOverColor, buttonOnColor);
    OKButton.locking = false;
    OKButton.text_color = color(255);
    OKButton.text_font = titleFont;
    OKButton.text = "OK";
    OKButton.func = "OK";
    inputButtons.add(OKButton);

    CancelButton = new RectButton(_W*5/6-_W/8, _H/2, _W/4, _H/10, buttonOffColor, buttonOverColor, buttonOnColor);
    CancelButton.text_color = color(255);
    CancelButton.text_font = titleFont;
    CancelButton.locking = false;
    CancelButton.text = "Cancel";
    CancelButton.func = "Cancel";
    inputButtons.add(CancelButton);

    /***********************
     *  HomeScreen buttons *
     ***********************/
    // Set up buttons on home screen
    bisSwitch = new CircleButton(_W*4/6, _H*1/7, _H/16, _H/16, buttonOffColor, buttonOverColor, buttonOnColor);
    bisSwitch.switcher = true;
    bisSwitch.state = true;
    bisSwitch.func = "bis_flag";
    homeButtons.add(bisSwitch);
    bisOptions = new RectButton(_W*4/6+_W/10, _H*1/7, _W/10, _H/22, buttonOffColor, buttonOverColor, buttonOnColor);
    bisOptions.locking = false;
    bisOptions.text = "OPTIONS";
    bisOptions.func = "bisOpt";
    homeButtons.add(bisOptions);

    magSwitch = new CircleButton(_W*4/6, _H*1/7+_H/12, _H/16, _H/16, buttonOffColor, buttonOverColor, buttonOnColor);
    magSwitch.switcher = true;
    magSwitch.state = true;
    magSwitch.func = "mag_flag";
    homeButtons.add(magSwitch);

    magOptions = new RectButton(_W*4/6+_W/10, _H*1/7+_H/12, _W/10, _H/22, buttonOffColor, buttonOverColor, buttonOnColor);
    magOptions.locking = false;
    magOptions.text = "OPTIONS";
    magOptions.func = "magOpt";
    homeButtons.add(magOptions);

    pcrSwitch = new CircleButton(_W*4/6, _H*1/7+_H*2/12, _H/16, _H/16, buttonOffColor, buttonOverColor, buttonOnColor);
    pcrSwitch.switcher = true;
    pcrSwitch.state = true;
    pcrSwitch.func = "pcr_flag";
    homeButtons.add(pcrSwitch);
    pcrOptions = new RectButton(_W*4/6+_W/10, _H*1/7+_H*2/12, _W/10, _H/22, buttonOffColor, buttonOverColor, buttonOnColor);
    pcrOptions.locking = false;
    pcrOptions.text = "OPTIONS";
    pcrOptions.func = "pcrOpt";
    homeButtons.add(pcrOptions);

    fluoSwitch = new CircleButton(_W*4/6, _H*1/7+_H*3/12, _H/16, _H/16, buttonOffColor, buttonOverColor, buttonOnColor);
    fluoSwitch.switcher = true;
    fluoSwitch.state = true;
    fluoSwitch.func = "fluo_flag";
    homeButtons.add(fluoSwitch);
    fluoOptions = new RectButton(_W*4/6+_W/10, _H*1/7+_H*3/12, _W/10, _H/22, buttonOffColor, buttonOverColor, buttonOnColor);
    fluoOptions.locking = false;
    fluoOptions.text = "OPTIONS";
    fluoOptions.func = "fluoOpt";
    homeButtons.add(fluoOptions);

    startButton = new RectButton( _W/3, _H*7/8, _H/5, _H/20, #228B22, #003366, color(255, 50, 0));
    startButton.func = "start";
    startButton.text_font = buttonFont;
    startButton.text_color = color(255);
    startButton.locking = false;
    startButton.text = "START";
    homeButtons.add(startButton);

    saveButton = new RectButton( _W*2/3, _H*7/8, _H/5, _H/20, #000080, #003366, color(255, 50, 0));
    saveButton.func = "save";
    saveButton.text_font = buttonFont;
    saveButton.text_color = color(255);
    saveButton.locking = false;
    saveButton.text = "EXPORT DATA";
    homeButtons.add(saveButton);

    /***********************
     *  Bisulfite buttons *
     ***********************/
    bisDigTempButton = new RectButton( _W/3, _H/6, _W/3, _H/10, buttonOffColor, buttonOverColor, color(0, 255, 0));
    bisDigTempButton.func = "bisDigTemp";
    bisDigTempButton.text = "Digestion Temp:\n" + bisDigTemp + "°C" ;
    bisDigTempButton.text_font = labelFont;
    bisDigTempButton.text_color = color(255);
    bisDigTempButton.locking = false;
    bisDigTempButton.state = false;
    bisButtons.add(bisDigTempButton);

    bisDigTimeButton = new RectButton( _W*2/3, _H/6, _W/3, _H/10, buttonOffColor, buttonOverColor, color(0, 255, 0));
    bisDigTimeButton.func = "bisDigTime";
    bisDigTimeButton.text = "Digestion Time:\n" + bisDigTime + " min" ;
    bisDigTimeButton.text_font = labelFont;
    bisDigTimeButton.text_color = color(255);
    bisDigTimeButton.locking = false;
    bisDigTimeButton.state = false;
    bisButtons.add(bisDigTimeButton);

    bisDenTempButton = new RectButton( _W/3, _H/3, _W/3, _H/10, buttonOffColor, buttonOverColor, color(0, 255, 0));
    bisDenTempButton.func = "bisDenTemp";
    bisDenTempButton.text = "Denaturation Temp:\n" + bisDenTemp + "°C" ;
    bisDenTempButton.text_font = labelFont;
    bisDenTempButton.text_color = color(255);
    bisDenTempButton.locking = false;
    bisDenTempButton.state = false;
    bisButtons.add(bisDenTempButton);

    bisDenTimeButton = new RectButton( _W*2/3, _H/3, _W/3, _H/10, buttonOffColor, buttonOverColor, color(0, 255, 0));
    bisDenTimeButton.func = "bisDenTime";
    bisDenTimeButton.text = "Denaturation Time:\n" + bisDenTime + " min" ;
    bisDenTimeButton.text_font = labelFont;
    bisDenTimeButton.text_color = color(255);
    bisDenTimeButton.locking = false;
    bisDenTimeButton.state = false;
    bisButtons.add(bisDenTimeButton);

    bisConTempButton = new RectButton( _W/3, _H/2, _W/3, _H/10, buttonOffColor, buttonOverColor, color(0, 255, 0));
    bisConTempButton.func = "bisConTemp";
    bisConTempButton.text = "Conversion Temp:\n" + bisConTemp + "°C" ;
    bisConTempButton.text_font = labelFont;
    bisConTempButton.text_color = color(255);
    bisConTempButton.locking = false;
    bisConTempButton.state = false;
    bisButtons.add(bisConTempButton);

    bisConTimeButton = new RectButton( _W*2/3, _H/2, _W/3, _H/10, buttonOffColor, buttonOverColor, color(0, 255, 0));
    bisConTimeButton.func = "bisConTime";
    bisConTimeButton.text = "Conversion Time:\n" + bisConTime + " min" ;
    bisConTimeButton.text_font = labelFont;
    bisConTimeButton.text_color = color(255);
    bisConTimeButton.locking = false;
    bisConTimeButton.state = false;
    bisButtons.add(bisConTimeButton);

    bisBindTempButton = new RectButton( _W/3, _H*4/6, _W/3, _H/10, buttonOffColor, buttonOverColor, color(0, 255, 0));
    bisBindTempButton.func = "bisBindTemp";
    bisBindTempButton.text = "Binding Temp:\n" + bisBindTemp + "°C" ;
    bisBindTempButton.text_font = labelFont;
    bisBindTempButton.text_color = color(255);
    bisBindTempButton.locking = false;
    bisBindTempButton.state = false;
    bisButtons.add(bisBindTempButton);

    bisBindTimeButton = new RectButton( _W*2/3, _H*4/6, _W/3, _H/10, buttonOffColor, buttonOverColor, color(0, 255, 0));
    bisBindTimeButton.func = "bisBindTime";
    bisBindTimeButton.text = "Binding Time:\n" + bisBindTime + " min" ;
    bisBindTimeButton.text_font = labelFont;
    bisBindTimeButton.text_color = color(255);
    bisBindTimeButton.locking = false;
    bisBindTimeButton.state = false;
    bisButtons.add(bisBindTimeButton);

    bisTestButton = new RectButton( _W*4/5, _H*5/6, _H/5, _H/10, #000080, #003366, color(255, 50, 0));
    bisTestButton.func = "bisTest";
    bisTestButton.text_font = titleFont;
    bisTestButton.text_color = color(255);
    bisTestButton.locking = false;
    bisTestButton.text = "TEST";
    bisButtons.add(bisTestButton);

    bisTestTempButton = new RectButton( _W*2/8, _H*5/6, _W/4, _H/10, buttonOffColor, buttonOverColor, color(0, 255, 0));
    bisTestTempButton.func = "bisTestTemp";
    bisTestTempButton.text = "Test Hold Temp:\n" + bisTestTemp + "°C" ;
    bisTestTempButton.text_font = labelFont;
    bisTestTempButton.text_color = color(255);
    bisTestTempButton.locking = false;
    bisTestTempButton.state = false;
    bisButtons.add(bisTestTempButton);

    bisTestTimeButton = new RectButton( _W*4/8, _H*5/6, _W/4, _H/10, buttonOffColor, buttonOverColor, color(0, 255, 0));
    bisTestTimeButton.func = "bisTestTime";
    bisTestTimeButton.text = "Test Hold Time:\n" + bisTestTime + " sec" ;
    bisTestTimeButton.text_font = labelFont;
    bisTestTimeButton.text_color = color(255);
    bisTestTimeButton.locking = false;
    bisTestTimeButton.state = false;
    bisButtons.add(bisTestTimeButton);

    /***********************
     *   Magnet Buttons    *
     ***********************/
    Button resetMagButton = new RectButton(_W/2, _H/5, _W/8, _H/8, buttonOffColor, buttonOverColor, color(240));      // Reset 
    resetMagButton.func = "resetMag";
    resetMagButton.text = "RESET" ;
    resetMagButton.text_font = labelFont;
    resetMagButton.text_color = color(0);
    resetMagButton.locking = false;
    resetMagButton.state = false;
    magXButtons.add(resetMagButton);
    
    bisMagButton = new RectButton(_W/7, _H/3, _W/8, _H/4, buttonOffColor, buttonOverColor, color(240));      // Bisulfite magnet
    bisMagButton.roundness = _H/10;
    bisMagButton.func = "bisMag";
    bisMagButton.text = "Bisulfite\nWell" ;
    bisMagButton.text_font = labelFont;
    bisMagButton.text_color = color(0);
    bisMagButton.locking = true;
    bisMagButton.state = false;
    magXButtons.add(bisMagButton);

    w1MagButton= new CircleButton(_W*2/7, _H/3, _W/8, _W/8, buttonOffColor, buttonOverColor, color(240));       // well 1
    w1MagButton.func = "w1Mag";
    w1MagButton.text = "1" ;
    w1MagButton.text_font = labelFont;
    w1MagButton.text_color = color(0);
    w1MagButton.locking = true;
    w1MagButton.state = false;
    magXButtons.add(w1MagButton);

    w2MagButton= new CircleButton(_W*3/7, _H/3, _W/8, _W/8, buttonOffColor, buttonOverColor, color(240));       // well 1
    w2MagButton.func = "w2Mag";
    w2MagButton.text = "2" ;
    w2MagButton.text_font = labelFont;
    w2MagButton.text_color = color(0);
    w2MagButton.locking = true;
    w2MagButton.state = false;
    magXButtons.add(w2MagButton);   

    w3MagButton= new CircleButton(_W*4/7, _H/3, _W/8, _W/8, buttonOffColor, buttonOverColor, color(240));       // well 3
    w3MagButton.func = "w3Mag";
    w3MagButton.text = "3" ;
    w3MagButton.text_font = labelFont;
    w3MagButton.text_color = color(0);
    w3MagButton.locking = true;
    w3MagButton.state = false;
    magXButtons.add(w3MagButton); 

    w4MagButton= new CircleButton(_W*5/7, _H/3, _W/8, _W/8, buttonOffColor, buttonOverColor, color(240));       // well 1
    w4MagButton.func = "w4Mag";
    w4MagButton.text = "4" ;
    w4MagButton.text_font = labelFont;
    w4MagButton.text_color = color(0);
    w4MagButton.locking = true;
    w4MagButton.state = false;
    magXButtons.add(w4MagButton); 

    pcrMagButton= new CircleButton(_W*6/7, _H/3, _W/7, _W/7, buttonOffColor, buttonOverColor, color(240));       // well 1
    pcrMagButton.func = "pcrMag";
    pcrMagButton.text = "PCR\nWell" ;
    pcrMagButton.text_font = labelFont;
    pcrMagButton.text_color = color(0);
    pcrMagButton.locking = true;
    pcrMagButton.state = false;
    magXButtons.add(pcrMagButton); 

    tMagButton= new RectButton(_W/2, _H*4/7, _W/4, _W/10, buttonOffColor, buttonOverColor, color(240));       // well 1
    tMagButton.func = "tMag";
    tMagButton.text = "Top Position" ;
    tMagButton.text_font = labelFont;
    tMagButton.text_color = color(0);
    tMagButton.locking = true;
    tMagButton.state = false;
    magZButtons.add(tMagButton); 

    mMagButton= new RectButton(_W/2, _H*5/7, _W/4, _W/10, buttonOffColor, buttonOverColor, color(240));       // well 1
    mMagButton.func = "mMag";
    mMagButton.text = "Middle Position" ;
    mMagButton.text_font = labelFont;
    mMagButton.text_color = color(0);
    mMagButton.locking = true;
    mMagButton.state = true;
    magZButtons.add(mMagButton); 

    bMagButton= new RectButton(_W/2, _H*6/7, _W/4, _W/10, buttonOffColor, buttonOverColor, color(240));       // well 1
    bMagButton.func = "bMag";
    bMagButton.text = "Bottom Position" ;
    bMagButton.text_font = labelFont;
    bMagButton.text_color = color(0);
    bMagButton.locking = true;
    bMagButton.state = false;
    magZButtons.add(bMagButton); 


    /***********************
     *     PCR buttons     *
     ***********************/
    pcrHotSwitch = new RectButton(_W*4/6, _H/6, _W/3, _H/10, buttonOffColor, buttonOverColor, buttonOnColor);
    pcrHotSwitch.switcher = true;
    pcrHotSwitch.text_font = labelFont;
    pcrHotSwitch.text_color = color(255);
    pcrHotSwitch.func = "hots_flag";
    pcrButtons.add(pcrHotSwitch);

    pcrHotsTimeButton = new RectButton( _W/3, _H/6, _W/3, _H/10, buttonOffColor, buttonOverColor, color(0, 255, 0));
    pcrHotsTimeButton.func = "pcrHotsTime";
    pcrHotsTimeButton.text = "Hotstart Time:\n" + pcrHotsTime + " sec" ;
    pcrHotsTimeButton.text_font = labelFont;
    pcrHotsTimeButton.text_color = color(255);
    pcrHotsTimeButton.locking = false;
    pcrHotsTimeButton.state = false;
    pcrButtons.add(pcrHotsTimeButton);

    pcrDenTempButton = new RectButton( _W/3, _H/3, _W/3, _H/10, buttonOffColor, buttonOverColor, color(0, 255, 0));
    pcrDenTempButton.func = "pcrDenTemp";
    pcrDenTempButton.text = "Denaturation Temp:\n" + pcrDenTemp + "°C" ;
    pcrDenTempButton.text_font = labelFont;
    pcrDenTempButton.text_color = color(255);
    pcrDenTempButton.locking = false;
    pcrDenTempButton.state = false;
    pcrButtons.add(pcrDenTempButton);

    pcrDenTimeButton = new RectButton( _W*2/3, _H/3, _W/3, _H/10, buttonOffColor, buttonOverColor, color(0, 255, 0));
    pcrDenTimeButton.func = "pcrDenTime";
    pcrDenTimeButton.text = "Denaturation Time:\n" + pcrDenTime + " sec" ;
    pcrDenTimeButton.text_font = labelFont;
    pcrDenTimeButton.text_color = color(255);
    pcrDenTimeButton.locking = false;
    pcrDenTimeButton.state = false;
    pcrButtons.add(pcrDenTimeButton);

    pcrAnnTempButton = new RectButton( _W/3, _H/2, _W/3, _H/10, buttonOffColor, buttonOverColor, color(0, 255, 0));
    pcrAnnTempButton.func = "pcrAnnTemp";
    pcrAnnTempButton.text = "Anneal Temp:\n" + pcrAnnTemp + "°C" ;
    pcrAnnTempButton.text_font = labelFont;
    pcrAnnTempButton.text_color = color(255);
    pcrAnnTempButton.locking = false;
    pcrAnnTempButton.state = false;
    pcrButtons.add(pcrAnnTempButton);

    pcrAnnTimeButton = new RectButton( _W*2/3, _H/2, _W/3, _H/10, buttonOffColor, buttonOverColor, color(0, 255, 0));
    pcrAnnTimeButton.func = "pcrAnnTime";
    pcrAnnTimeButton.text = "Anneal Time:\n" + pcrAnnTime + " sec" ;
    pcrAnnTimeButton.text_font = labelFont;
    pcrAnnTimeButton.text_color = color(255);
    pcrAnnTimeButton.locking = false;
    pcrAnnTimeButton.state = false;
    pcrButtons.add(pcrAnnTimeButton);
    
    pcrCycleNButton = new RectButton( _W/2, _H*2/3, _W/3, _H/10, buttonOffColor, buttonOverColor, color(0, 255, 0));
    pcrCycleNButton.func = "pcrCycleN";
    pcrCycleNButton.text = "Cycle Number:\n" + cycleN;
    pcrCycleNButton.text_font = labelFont;
    pcrCycleNButton.text_color = color(255);
    pcrCycleNButton.locking = false;
    pcrCycleNButton.state = false;
    pcrButtons.add(pcrCycleNButton);

    pcrTestButton = new RectButton( _W*4/5, _H*5/6, _H/5, _H/10, #000080, #003366, color(255, 50, 0));
    pcrTestButton.func = "pcrTest";
    pcrTestButton.text_font = titleFont;
    pcrTestButton.text_color = color(255);
    pcrTestButton.locking = false;
    pcrTestButton.text = "TEST";
    pcrButtons.add(pcrTestButton);

    pcrTestTempButton = new RectButton( _W*2/8, _H*5/6, _W/4, _H/10, buttonOffColor, buttonOverColor, color(0, 255, 0));
    pcrTestTempButton.func = "pcrTestTemp";
    pcrTestTempButton.text = "Test Hold Temp:\n" + pcrTestTemp + "°C" ;
    pcrTestTempButton.text_font = labelFont;
    pcrTestTempButton.text_color = color(255);
    pcrTestTempButton.locking = false;
    pcrTestTempButton.state = false;
    pcrButtons.add(pcrTestTempButton);

    pcrTestTimeButton = new RectButton( _W*4/8, _H*5/6, _W/4, _H/10, buttonOffColor, buttonOverColor, color(0, 255, 0));
    pcrTestTimeButton.func = "pcrTestTime";
    pcrTestTimeButton.text = "Test Hold Time:\n" + pcrTestTime + " sec" ;
    pcrTestTimeButton.text_font = labelFont;
    pcrTestTimeButton.text_color = color(255);
    pcrTestTimeButton.locking = false;
    pcrTestTimeButton.state = false;
    pcrButtons.add(pcrTestTimeButton);

    /***********************
     *  FluoScreen buttons *
     ***********************/
    LED = loadImage("imgs/lightbulb_white.png");
    LED1 = new ImageButton(LED, _W/6, _H/6, _H/10, _H/10, color(50), color(0, 0, 255, 100), color(0, 0, 255)); 
    LED1.func = "LED1";
    LED1.state = true;
    LED1.switcher = true;
    fluoButtons.add(LED1);

    LED2 = new ImageButton(LED, _W/6+_W/7, _H/6, _H/10, _H/10, color(50), color(255, 0, 0, 150), color(255, 0, 0)); 
    LED2.func = "LED2";
    LED1.switcher = true;
    fluoButtons.add(LED2);

    Det1 = new RectButton( _W/6 + _W*2/6, _H/5, _H/5, _H/10, buttonOffColor, buttonOverColor, color(0, 255, 0));
    Det1.func = "Det1";
    Det1.text = "Detector 1: " + Det1_nm + " nm\n" ;
    Det1.switcher = true;
    Det1.state = true;
    fluoButtons.add(Det1);

    Det2 = new RectButton( (_W/6 + _W*3/7+_H/5), _H/5, _H/5, _H/10, buttonOffColor, buttonOverColor, color(255, 50, 0));
    Det2.func = "Det2";
    Det2.text = "Detector 2: " + Det2_nm + " nm\n" ;
    Det2.switcher = true;
    Det2.state = false;
    fluoButtons.add(Det2);

    LED1Current = new RectButton( (_W/4), _H/2, _H/5, _H/10, buttonOffColor, buttonOverColor, color(255, 50, 0));
    LED1Current.func = "LED1Current";
    LED1Current.locking = false;
    LED1Current.text = "LED1 Current:\n" + led1_current + "mA";
    fluoButtons.add(LED1Current);

    LED2Current = new RectButton( (_W/2), _H/2, _H/5, _H/10, buttonOffColor, buttonOverColor, color(255, 50, 0));
    LED2Current.func = "LED2Current";
    LED2Current.locking = false;
    LED2Current.text = "LED2 Current:\n" + led2_current + "mA";
    fluoButtons.add(LED2Current);

    LED1OnDelay = new RectButton( (_W/4), _H/2 + _H/6, _H/5, _H/10, buttonOffColor, buttonOverColor, color(255, 50, 0));
    LED1OnDelay.func = "LED1OnDelay";
    LED1OnDelay.locking = false;
    LED1OnDelay.text = "LED1 On Delay:\n" + led1_on_delay + "ms";
    fluoButtons.add(LED1OnDelay);

    LED2OnDelay = new RectButton( (_W/2), _H/2 + _H/6, _H/5, _H/10, buttonOffColor, buttonOverColor, color(255, 50, 0));
    LED2OnDelay.func = "LED2OnDelay";
    LED2OnDelay.locking = false;
    LED2OnDelay.text = "LED2 On Delay:\n" + led2_on_delay + "ms";
    fluoButtons.add(LED2OnDelay);

    LED1OffDelay = new RectButton( (_W/4), _H/2 + _H*2/6, _H/5, _H/10, buttonOffColor, buttonOverColor, color(255, 50, 0));
    LED1OffDelay.func = "LED1OffDelay";
    LED1OffDelay.locking = false;
    LED1OffDelay.text = "LED1 Off Delay:\n" + led1_on_delay + "ms";
    fluoButtons.add(LED1OffDelay);

    LED2OffDelay = new RectButton( (_W/2), _H/2 + _H*2/6, _H/5, _H/10, buttonOffColor, buttonOverColor, color(255, 50, 0));
    LED2OffDelay.func = "LED2OffDelay";
    LED2OffDelay.locking = false;
    LED2OffDelay.text = "LED2 Off Delay:\n" + led2_on_delay + "ms";
    fluoButtons.add(LED2OffDelay);

    fluoTest = new RectButton( (_W/6 + _W*3/7+_H/5), _H/2, _H/5, _H/10, #000080, #003366, color(255, 50, 0));
    fluoTest.func = "fluoTest";
    fluoTest.text_font = titleFont;
    fluoTest.text_color = color(255);
    fluoTest.locking = false;
    fluoTest.text = "TEST";
    fluoButtons.add(fluoTest);
}


class Button {

    int x, y;
    int w, h;
    color basecolor, highlightcolor, oncolor;
    color currentcolor;

    String text = "";
    PFont text_font = buttonFont;
    color text_color = color(0);    // black default
    color stroke_color = color(0);  // black default

    boolean pressed = false;
    boolean state = false;   // on or off
    boolean locking = true;  // button stays on after pressed
    boolean stroke = false;  // no outline
    boolean switcher = false;

    String func = "";


    void update() 
    {
        if (over()) {
            if (!state) currentcolor = highlightcolor;
        } else {
            if (state) {
                currentcolor = oncolor;
            } else {
                currentcolor = basecolor;
            }
        }
    }

    void pressed() // called if mouse pressed and over button -- returns func string for parsing into serial cmd
    {  
        if (locking) {
            if (state) currentcolor = basecolor;
            if (!state) currentcolor = oncolor; 
            state = !state;
            //println("state switched");
        }
    }
    boolean over() 
    { 
        return true;
    } 

    boolean overRect(int x, int y, int w, int h, int mouseXscaled, int mouseYscaled) 

    { 
        if (mouseXscaled >= x-w/2 && mouseXscaled <= x+w/2 && mouseYscaled >= y-h/2 && mouseYscaled <= y+h/2) {
            return true;
        } else {
            return false;
        }
    }

    boolean overCircle(int x, int y, int diameter, int mouseXscaled, int mouseYscaled) 
    {
        float disX = x - mouseXscaled;
        float disY = y - mouseYscaled;
        if (sqrt(sq(disX) + sq(disY)) < diameter/2 ) {
            return true;
        } else {
            return false;
        }
    }
    void display() {
    }
}


class CircleButton extends Button
{ 
    CircleButton(int ix, int iy, int iw, int ih, color icolor, color ihighlight, color ioncolor) 
    {
        x = ix;
        y = iy;
        w = iw;
        h = ih;
        basecolor = icolor;
        highlightcolor = ihighlight;
        oncolor = ioncolor;
        currentcolor = basecolor;
    }

    boolean over() 
    {   
        mXscaled = mouseX * _W/width;
        mYscaled = mouseY * _H/height;
        if ( overCircle(x, y, w, mXscaled, mYscaled) ) {
            //over = true;
            return true;
        } else {
            //over = false;
            return false;
        }
    }

    void display() 
    {
        if (stroke) stroke(stroke_color);
        else noStroke();
        fill(currentcolor);
        ellipse(x, y, w, h);

        if (this.switcher) {
            if (state) this.text = "ON";
            else this.text = "OFF";
        }

        fill(this.text_color);
        textFont(this.text_font);
        textAlign(CENTER, CENTER);
        text(this.text, x, y);
    }
}

class RectButton extends Button
{   
    int roundness = 5;
    RectButton(int ix, int iy, int iw, int ih, color icolor, color ihighlight, color ioncolor) 
    {
        x = ix;
        y = iy;
        w = iw;
        h = ih;
        basecolor = icolor;
        highlightcolor = ihighlight;
        oncolor = ioncolor;
        currentcolor = basecolor;
    }

    boolean over() 
    {
        mXscaled = mouseX * _W/width;
        mYscaled = mouseY * _H/height;
        if ( overRect(x, y, w, h, mXscaled, mYscaled) ) {
            //over = true;
            return true;
        } else {
            //over = false;
            return false;
        }
    }

    void display() 
    {
        if (stroke) stroke(stroke_color);
        else noStroke();
        fill(currentcolor);
        rectMode(CENTER);
        rect(x, y, w, h, roundness);

        if (this.switcher) {
            if (state) {
                fill(this.text_color);
                textFont(this.text_font);
                textAlign(CENTER, CENTER);
                text(this.text + "ON", x, y);
            } else {
                fill(this.text_color);
                textFont(this.text_font);
                textAlign(CENTER, CENTER);
                text(this.text + "OFF", x, y);
            }
        } else {
            fill(this.text_color);
            textFont(this.text_font);
            textAlign(CENTER, CENTER);
            text(this.text, x, y);
        }
    }
}

class ImageButton extends Button
{
    PImage img;
    ImageButton(PImage iimg, int ix, int iy, int iw, int ih, color icolor, color ihighlight, color ioncolor) 
    {
        x = ix;
        y = iy;
        w = iw;
        h = ih;
        img = iimg;
        basecolor = icolor;
        highlightcolor = ihighlight;
        oncolor = ioncolor;
        currentcolor = basecolor;
    }

    boolean over() 
    {
        mXscaled = mouseX * _W/width;
        mYscaled = mouseY * _H/height;
        if ( overRect(x, y, w, h, mXscaled, mYscaled) ) {
            //over = true;
            return true;
        } else {
            //over = false;
            return false;
        }
    }

    void display() 
    { 
        if (state) {
            tint(oncolor);
        } else if (this.over()) {
            tint(highlightcolor);
        } else tint(basecolor);
        imageMode(CENTER);
        image(img, x, y, w, h);
    }
}
