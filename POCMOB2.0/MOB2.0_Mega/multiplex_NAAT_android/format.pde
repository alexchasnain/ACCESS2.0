color backgroundColor;
color txtColor;
color[] plotColors = new color[7];
PFont titleFont;
PFont labelFont;
PFont detectFont;
PFont alertFont;

// Button Colors/fonts
color buttonOffColor;
color buttonOverColor;
color buttonOnColor;
color buttonTxtColor;
PFont buttonFont;


void setupFonts() {
  titleFont = createFont("Helvetica-Bold", 54, true);
  detectFont = createFont("Helvetica-Bold",  30, true);
  labelFont = createFont("Helvetica-Bold", 36, true);
  buttonFont = createFont("Helvetica", 36, true); // true = smoothing
  alertFont = createFont("Helvetica", 48, true);
}

void setupColors() {
  txtColor = color(255);

  // Button Settings
  backgroundColor = #3498DB;  // "Peter River" blue
  buttonOffColor = #95A5A6;   // "concrete" gray
  buttonOverColor = #7F8C8D;  // "Asbestos" gray -- highlighted color
  buttonOnColor = #2ECC71;    // "Emerald" green
  buttonTxtColor = color(255); // white
  
  plotColors[0] = color(0);  // black
  plotColors[1] = #00721c;  // dark green
  plotColors[2] = #00b22b;  // light green
  plotColors[3] = #001384;  // dark blue
  plotColors[4] = #0024ff;  // light blue
  plotColors[5] = #840000;  // dark red
  plotColors[6] = #ff0000;  // light red
  
}
