void test_heater(float temp, float time, int heater) {
    ardSend("t"+heater+"("+temp+","+time+")");
    serialMode = 1; // data logging initiated with asterisk

    n_plots = 1;  // just temperature vs. time    
    temp_plotter = new plot2D(plotx-plotw, ploty-ploth/2, plotw, ploth, n_plots);
    temp_plotter.pt_size = 4;
    temp_plotter.labels = true;
    temp_plotter.xlabel = "Time (sec)";
    temp_plotter.ylabel = "Temperature (°C)";
    temp_pt = new float[2][1];

    n_plots = 4;  // 4 fluo channels 
    fluo_plotter = new plot2D(plotx, ploty, plotw, ploth, 1);
    fluo_plotter.pt_size = 4;
    fluo_plotter.labels = true;
    fluo_plotter.xlabel = "Cycle";
    fluo_plotter.ylabel = "Fluorescence (mV)";
    fluo_pt = new float[n_plots+1][1];
}


boolean cycle_flag = false;
boolean bisCon_flag = false;
void cycle() {
    //cycle_flag = true;
    float hotsTime = 0;
    if (pcrHotSwitch.state) {
        hotsTime = pcrHotsTime;
    }
    int detect = 0;
    if (fluoSwitch.state) {
        detect = 1;
    }
    int pcrAnnTemp_cal = cart2HB_pcr(pcrAnnTemp);
    int pcrDenTemp_cal = cart2HB_pcr(pcrDenTemp);
    ardSend("cycle("+pcrAnnTemp_cal+","+pcrAnnTime+","+pcrDenTemp_cal+","+pcrDenTime+","+cycleN+","+hotsTime+","+detect+")");
    serialMode = 1; // data logging initiated with asterisk


    n_plots = 1;  // fluo (6 wells) and temperature vs. time    
    temp_plotter = new plot2D(plotx-plotw, ploty-ploth/2, plotw, ploth, n_plots);
    temp_plotter.pt_size = 4;
    temp_plotter.ax_lock = false;
    //temp_plotter.ax_lim[1] = 8000;   // settings for axes limits {xmin, xmax, ymin,ymax}
    //temp_plotter.ax_lim[3] = 300;
    temp_plotter.labels = true;
    temp_plotter.xlabel = "Time (sec)";
    temp_plotter.ylabel = "Temp(°C)"; 
    temp_pt = new float[2][1];

    n_plots = 4;  // just temperature vs. time    
    fluo_plotter = new plot2D(plotx, ploty, plotw, ploth, n_plots);
    fluo_plotter.pt_size = 4;
    fluo_plotter.labels = true;
    fluo_plotter.xlabel = "Cycle";
    fluo_plotter.ylabel = "Fluorescence (mV)";
    fluo_plotter.colors = plotColors;
    fluo_pt = new float[n_plots+1][1];
    
    if (detect == 1) { 
        println("Detect ON -- fluo plot initialized");
    }
}

void bisCon() {
    //bisCon_flag = true;
    ardSend("bisCon("+bisDigTemp+","+bisDigTime+","+bisDenTemp+","+bisDenTime+","+bisConTemp+","+bisConTime+","+bisBindTemp+","+bisBindTime+")");

    serialMode = 1; // data logging initiated with asterisk
    n_plots = 1;  // just temperature vs. time    
    temp_plotter = new plot2D(plotx-plotw, ploty-ploth/2, plotw, ploth, n_plots);
    temp_plotter.pt_size = 4;
    temp_plotter.labels = true;
    temp_plotter.xlabel = "Time (sec)";
    temp_plotter.ylabel = "Temperature (°C)";
    temp_pt = new float[2][1];
}

int cart2HB_pcr(int cart_temp) {
    // converts pcr target cartridge temperature to heatblock temperature based on calibtration curve
    
    return cart_temp; // no conversion
    //return parseInt((cart_temp-3.9591)/0.8985);
}
