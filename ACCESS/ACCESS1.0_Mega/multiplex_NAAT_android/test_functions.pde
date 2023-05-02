int time = 0;
float temp = 100;
/*
void test_setup() {
 
    alert_flag = false;
  pt = new float[8][1];
  n_plots = 7;  // fluo (6 wells) and temperature vs. time    
  plotter = new plot2D(plotx-plotw/2, ploty-ploth/2, plotw, ploth, n_plots);
  plotter.ax_lock = true;
  plotter.ax_lim[1] = 50;
  plotter.ax_lim[3] = 50;
  plotter.pt_size = 4;
  
  plotter.labels = true;
  plotter.xlabel = "Time (sec)";
  plotter.ylabel = "Temp(°C)/Fluo";
  plotter.colors = plotColors;

  time = 0;
  temp = 100;
  
}

void test_cycle_plot() {

  time++;
  temp+= Math.random()*5-2.5;

  pt[0][0] = time;
  pt[1][0] = temp;
  
  
  for (int i = 2; i<n_plots+1; i++) {
   if(time%5 ==0){
     
    pt[i][0] = (float)Math.random()*100;
   }
   else{
     pt[i][0] = OOB;
   }
  }
  plotter.loadData(pt);
  //delay(500);
}
*/
