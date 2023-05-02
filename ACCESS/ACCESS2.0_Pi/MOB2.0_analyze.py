#!/usr/bin/env python
import os
import sys
import csv
import numpy as np
import pandas as pd
import scipy
from scipy.optimize import leastsq
from scipy import stats
from scipy.signal import savgol_filter
import tkinter as Tk
from tkinter.filedialog import askopenfilename
from tkinter.messagebox import showerror
import matplotlib.pyplot as plt

SLOPE_THRESH = 0.25
STD_THRESH = 9
MIN_THRESH = 5

def read_csv(filename):
    data = np.genfromtxt(filename, delimiter=',', skip_header=1)
    return data


def baseline_subtract(raw_fluo):
    raw_fluo = raw_fluo.to_numpy()
    if isinstance(raw_fluo, np.ndarray):
        n_cycles = raw_fluo.size
    else:
        n_cycles = len(raw_fluo)
    if n_cycles > 20:
        # Use convolve to create running average
        N = 3  # running mean window
        fluo = np.convolve(raw_fluo, np.ones((N,)) / N, mode='valid')
        fluo = np.append(fluo, raw_fluo[-(N - 1):])

        x = np.arange(1, n_cycles + 1)
        slope, intercept, r_value, p_value, std_err = stats.linregress(x[1:23], fluo[1:23])  # fit to cycles 2-20
        # p_coeff = np.polyfit(x[0:20],fluo[0:20],2)
        # p_fit = np.poly1d(p_coeff)
        # baseline_fit = p_fit(x)
        baseline_fit = slope * x + intercept

        bs_fluo = fluo - baseline_fit
        bs_fluo = pd.DataFrame(bs_fluo)
        return bs_fluo
    else:
        fluo = pd.DataFrame(fluo)
        return fluo


# def analyzeCT(raw_fluo_df, std_threshold=12, slope_threshold=0.5):
#     np.seterr(all='ignore')
#     raw_fluo = raw_fluo_df.to_numpy()
#
#     if isinstance(raw_fluo, np.ndarray):
#         n_cycles = raw_fluo.size
#     elif isinstance(raw_fluo, list):
#         n_cycles = len(raw_fluo)
#     else:
#         print('analyzeCT unable to interpret fluo data')
#         return [-1, -1]
#
#     bs_fluo_df = baseline_subtract(raw_fluo_df)
#     bs_fluo = bs_fluo_df[0].to_numpy()
#
#     cycles = np.linspace(0, n_cycles, n_cycles)
#
#     ct_log = 0
#     ct_thres = 0
#     bsl = 0
#     std = 0
#
#     # Calculate baseline value using cycles n0 through n1
#     n0 = 10
#     n1 = 20
#     cycle_bsl = []
#     dslope = 0
#     if n_cycles > n1:
#         # Check if values lie within interquartile range (IQR) -- remove outliers
#         iqr = stats.iqr(bs_fluo[n0:n1])
#         for i in range(n0, n1):
#             if bs_fluo[i] - np.mean(bs_fluo[n0:n1]) > iqr:
#                 # Outlier detected and ignored
#                 pass
#             else:
#                 cycle_bsl.append(bs_fluo[i])
#
#         bsl = np.mean(cycle_bsl)
#         std = np.std(cycle_bsl)
#
#         # set threshold as 'std_threshold' times standard deviation higher than baseline
#         fluo_thres = bsl + std_threshold * std
#
#         # check which cycles meet the threshold
#         ct_thresh_idxs = np.argwhere(bs_fluo[n1:] > fluo_thres)
#         ct_thresh_idx = 0
#         for i in ct_thresh_idxs:
#             slope1, intercept1, r_value1, p_value1, std_err1 = stats.linregress(cycles[10:20],
#                                                                                 bs_fluo[10:20])  # fit slope of baseline
#             if n1 + i > n_cycles - 4:
#                 slope2, intercept2, r_value2, p_value2, std_err2 = stats.linregress(
#                     cycles[int(n1 + i - 2):n_cycles - 1], bs_fluo[int(n1 + i - 2):n_cycles - 1])  # fit slope around Ct
#             else:
#                 slope2, intercept2, r_value2, p_value2, std_err2 = stats.linregress(
#                     cycles[int(n1 + i - 1):int(n1 + i + 2)],
#                     bs_fluo[int(n1 + i - 1):int(n1 + i + 2)])  # fit slope around Ct
#             dslope = slope2 - slope1
#             # check if (1) slope2 is a good fit -- ignore jumps in fluorescence
#             #          (2) slope is greater than the predefined threshold
#             #          (3) last fluorescence value is at least 1 stdev RFU greater than fluo baseline avg
#
#             if r_value2 > 0.9 and dslope > slope_threshold and raw_fluo[n1 + i] > np.mean(bs_fluo[n0:n1]):
#                 ct_thresh_idx = n1 + i
#                 break
#             else:
#                 ct_thresh_idx = -1
#
#         # interpolate cycles numbers
#         if ct_thresh_idx > 0:
#             div = 0.05
#             cycles_interp = np.linspace(ct_thresh_idx - 2, ct_thresh_idx + 1, int(3 / div))
#             slope2_fluo = slope2 * cycles + intercept2
#             fluo_interp = np.interp(cycles_interp, cycles, slope2_fluo)
#
#             ct_thres = cycles_interp[np.argmax(fluo_interp > fluo_thres), 0]  # argmax returns first instance
#
#         # Fit equation using least squares optimization if signal rises above threshold
#         ct_log = 0
#         if ct_thres > 0.0001:
#             p0 = [30, 30, 5, 30]  # Initial guess for parameters
#             plsq = leastsq(residuals, p0, args=(bs_fluo, cycles), maxfev=10000)
#             ct_log = ct_logistic(plsq[0])
#
#     return [ct_log, ct_thres, bsl, std * std_threshold, dslope]
#
#
# # Helper functions for CT calculation
# def logistic4(x, A, B, C, D):
#     """4PL lgoistic equation."""
#     return ((A - D) / (1.0 + ((x / C) ** B))) + D
#
# def residuals(p, y, x):
#     """Deviations of data from fitted 4PL curve"""
#     A, B, C, D = p
#     err = y - logistic4(x, A, B, C, D)
#     return err
#
# def peval(x, p):
#     """Evaluated value at x with current parameters."""
#     A, B, C, D = p
#     return logistic4(x, A, B, C, D)
#
# def ct_logistic(p):
#     """Calculate Ct based on 4P logistic regression fittig."""
#     A, B, C, D = p
#     Ct = C * ((-(3.0 * B ** 2.0 * (B ** 2.0 - 1.0)) ** 0.5 - 2.0 * (1.0 - B ** 2.0)) / (B ** 2.0 + 3.0 * B + 2.0)) ** (
#                 1.0 / B)  # (Tichopad et al 2003)
#     return Ct


def analyzeCT(raw_fluo_df, std_threshold=12, slope_threshold=0.5):
    #####################################################################################################################################
    ## input fluo array containing all fluorescence values -- calculate CT and return [CT_logistic, CT_threshold]
    #####################################################################################################################################
    np.seterr(all='ignore')
    raw_fluo = raw_fluo_df.to_numpy()

    if isinstance(raw_fluo, np.ndarray):
        n_cycles = raw_fluo.size
    elif isinstance(raw_fluo, list):
        n_cycles = len(raw_fluo)
    else:
        print('analyzeCT unable to interpret fluo data')
        return [-1, -1]

    # Replace nan with interpolated values
    raw_fluo = replace_nan(raw_fluo)

    bs_fluo_df = baseline_subtract(raw_fluo_df)
    bs_fluo = bs_fluo_df[0].to_numpy()
    # fluo = baseline_subtract(raw_fluo)

    cycles = np.linspace(0, n_cycles, n_cycles)

    ct_log = 0
    ct_thres = 0
    bsl = 0
    std = 0

    # Calculate baseline value using cycles n0 through n1
    n0 = 5
    n1 = 20
    cycle_bsl = []
    dslope = 0
    if n_cycles > n1:
        # Check if values lie within interquartile range (IQR) -- remove outliers for baseline calculation
        iqr = stats.iqr(bs_fluo[n0:n1])
        for i in range(n0, n1):
            if bs_fluo[i] - np.mean(bs_fluo[n0:n1]) > iqr:
                # Outlier detected and ignored
                pass
            else:
                cycle_bsl.append(bs_fluo[i])

        bsl = np.mean(cycle_bsl)
        std = np.std(cycle_bsl)

        # set threshold as 'std_threshold' times standard deviation higher than baseline
        fluo_thres = max(bsl + std_threshold * std, MIN_THRESH)

        # check which cycles meet the threshold
        ct_thresh_idxs = np.argwhere(bs_fluo[n1:] > fluo_thres)
        ct_thresh_idx = 0
        for i in ct_thresh_idxs:
            slope1, intercept1, r_value1, p_value1, std_err1 = stats.linregress(cycles[n0:n1],
                                                                                bs_fluo[n0:n1])  # fit slope of baseline
            if n1 + i > n_cycles - 4:
                slope2, intercept2, r_value2, p_value2, std_err2 = stats.linregress(
                    cycles[int(n1 + i - 2):n_cycles - 1], bs_fluo[int(n1 + i - 2):n_cycles - 1])  # fit slope around Ct
            else:
                slope2, intercept2, r_value2, p_value2, std_err2 = stats.linregress(
                    cycles[int(n1 + i - 1):int(n1 + i + 2)],
                    bs_fluo[int(n1 + i - 1):int(n1 + i + 2)])  # fit slope around Ct
            dslope = slope2 - slope1

            # check if (1) slope2 is a good fit -- ignore jumps in fluorescence
            #          (2) slope is greater than the predefined threshold
            #          (3) last fluorescence value is at least 1 stdev RFU greater than raw baseline avg
            if r_value2 > 0.9 and dslope > slope_threshold and raw_fluo[n1 + i] > raw_fluo[
                0]:  # np.mean(raw_fluo[n0:n1]):
                ct_thresh_idx = n1 + i
                break
            else:
                ct_thresh_idx = -1

        # interpolate fluo vs. cycles to calculate Ct using threshold method
        if ct_thresh_idx > 0:
            div = 0.05
            cycles_interp = np.linspace(ct_thresh_idx - 2, ct_thresh_idx + 1, int(3 / div))
            slope2_fluo = slope2 * cycles + intercept2
            # print(slope2_fluo)
            fluo_interp = np.interp(cycles_interp, cycles, slope2_fluo)
            ct_thres = cycles_interp[np.argmax(fluo_interp > fluo_thres), 0]  # argmax returns first instance

        # if standalone_flag:
        #     stdev_log_str = "Stdev Threshold Multiplier/stdev:," + str(std_threshold) + ',' + str(std) + '\n'
        #     analysis_file.write(stdev_log_str)

        # Fit logistic equation using least squares optimization if signal rises above threshold
        ct_log = 0
        if ct_thres > 0.0001: # and standalone_flag == True:
            p0 = [30, 30, 5, 30]  # Initial guess for parameters
            plsq = leastsq(residuals, p0, args=(bs_fluo, cycles), maxfev=10000)
            ct_log = ct_logistic(plsq[0])

    return [ct_log, ct_thres, bsl, std * std_threshold, dslope]


#####################################################################################################################################
## Helper functions for CT calculation
#####################################################################################################################################
def logistic4(x, A, B, C, D):
    """4PL lgoistic equation."""
    return ((A-D)/(1.0+((x/C)**B))) + D
def residuals(p, y, x):
    """Deviations of data from fitted 4PL curve"""
    A,B,C,D = p
    err = y-logistic4(x, A, B, C, D)
    return err
def peval(x, p):
    """Evaluated value at x with current parameters."""
    A,B,C,D = p
    return logistic4(x, A, B, C, D)
def ct_logistic(p):
    """Calculate Ct based on 4P logistic regression fittig."""
    A,B,C,D = p
    Ct = C*((-(3.0*B**2.0*(B**2.0-1.0))**0.5 - 2.0*(1.0-B**2.0))/(B**2.0+3.0*B+2.0))**(1.0/B) # (Tichopad et al 2003)
    return Ct
def replace_nan(fluo):
#####################################################################################################################################
## replace nan errors with average value of fluorescence measurements on either side of nan cycles
#####################################################################################################################################
    if isinstance(fluo,np.ndarray):
        n_cycles = fluo.size
    elif isinstance(fluo,list):
        n_cycles = len(fluo)

    curr_cycle = 0
    right_cycle = 0
    left_cycle = 0
    right_fluo = 0
    left_fluo = 0
    for i in range(0,n_cycles):
        curr_cycle = i

        if np.isnan(fluo[i]):
            print('nan detected at cycle', i)
            # find the first cycle > i that has a non-"nan" number
            while np.isnan(fluo[curr_cycle]) and curr_cycle < n_cycles:
                curr_cycle += 1
            if curr_cycle == n_cycles:
                right_cycle = i # nan exists at the very end of the array - set to i as a marker
            else:
                right_cycle = curr_cycle
                right_fluo = fluo[curr_cycle]

            # find the first cycle < i that has a non-"nan" number
            curr_cycle = i
            if curr_cycle == 0:
                left_cycle = 0
                left_fluo = right_fluo
            else:
                left_cycle = curr_cycle-1
                left_fluo = fluo[curr_cycle-1]

            if right_cycle == i:    # nan exists on right side - set equal to left side
                right_fluo = left_fluo

            # Set all in between fluo values equal to average of left and right fluo
            for nan_idx in range(i,right_cycle+1):
                fluo[nan_idx] = (left_fluo + right_fluo)/2
                print('Replaced ', nan_idx,' with ', fluo[nan_idx])

    return fluo


def melt(raw_melt_fluo_df, melt_temp_df):
    """
    perform melt curve analysis
    :param melt_temp_df: 1-column melt temperature (˚C) dataframe
    :param raw_melt_fluo_df: 1-column raw melt fluorescence (RFU) dataframe
    :return:
         melt_fluo_temp: 1-column -dFluo/dTemp (RFU/˚C) dataframe
    """
    melt_temp =  melt_temp_df.to_numpy()
    raw_melt_fluo = raw_melt_fluo_df.to_numpy()

    # Moving average filter for smoothing
    N = 3  # running mean window
    maf_melt_fluo = np.convolve(raw_melt_fluo, np.ones((N,)) / N, mode='valid')
    maf_melt_fluo = np.append(maf_melt_fluo, raw_melt_fluo[-(N - 1):])

    # Baseline subtraction
    x = np.arange(1, maf_melt_fluo.size + 1)
    slope, intercept, r_value, p_value, std_err = stats.linregress(x[1:9], maf_melt_fluo[1:9])  # fit to first 10 temperatures
    baseline_fit = slope * x + intercept
    bs_melt_fluo = maf_melt_fluo - baseline_fit

    # # Savitzky Golay filter for smoothing
    # window_len = 29
    # # melt_savgol = savgol_filter(raw_melt_fluo, window_len, 2, mode='nearest')
    # d_melt_fluo_savgol = savgol_filter(bs_melt_fluo, window_len, 2, deriv=1, mode='nearest')
    # drmf_dmt_arr = savgol_filter(d_melt_fluo_savgol, window_len, 2, mode = 'nearest')

    # Finding the negative first derivative of raw melt fluorescence with respect to melt temperature
    drmf_dmt_arr = -np.diff(bs_melt_fluo)/np.diff(melt_temp[:,0])

    # Make a 2-column dataframe with both -dFluo/dTemp and melt temperature
    # drmf_dmt_header = "-dFluo/dTemp"
    drmf_dmt = pd.DataFrame(drmf_dmt_arr)
    # drmf_dmt = pd.DataFrame({drmf_dmt_header: drmf_dmt_arr})

    return drmf_dmt


def parse_serial(filename, melt_flag = False):
    """
    parse CSV file from Arduino Serial (fluo data embedded in temp data)
    :param filename: filepath for single CSV file storing data from Arduino Serial
    :param melt_flag:
    :return:
        temp: temperature (˚C) dataframe
        time: time (s) dataframe
        raw_fluo: raw fluorescence (RFU) dataframe
        cycles: cycle dataframe
    :param filename:
    """
    df = pd.read_csv(filename, header=None)
    time_header = "Time"
    temp_header = "Temperature"
    cyc_header = "Cycle"
    fluo1_header = "CH1"
    fluo2_header = "CH2"
    fluo3_header = "CH3"
    fluo4_header = "CH4"

    temp = pd.DataFrame(columns=[temp_header])
    time = pd.DataFrame(columns=[time_header])
    raw_fluo = pd.DataFrame(columns=[fluo1_header, fluo2_header, fluo3_header, fluo4_header])
    cycles = pd.DataFrame(columns=[cyc_header])

    # if Arduino Serial data is PCR/MOB, extract temperature, time, raw fluorescence, and cycle data
    if not melt_flag:
        for index, row in df.iterrows():
            if not (row[0] == "Fluo"):
                time = time.append({time_header: float(row[0])}, ignore_index=True)
                temp = temp.append({temp_header: row[1]}, ignore_index=True)
            else:
                dict_temporary_fluo = {fluo1_header: row[1], fluo2_header: row[2],
                                       fluo3_header: row[3], fluo4_header: row[4]}
                raw_fluo = raw_fluo.append(dict_temporary_fluo, ignore_index=True)
                cycles = cycles.append({cyc_header: row[6]}, ignore_index=True)
        time = time[time_header] - time[time_header][0]
        return temp, time, raw_fluo, cycles

    # if Arduino Serial data is melt curve analysis, extract temperature and raw fluorescence data only
    else:
        for index, row in df.iterrows():
            if row[0] == "Fluo":
                dict_temporary_fluo = {fluo1_header: row[1], fluo2_header: row[2],
                                       fluo3_header: row[3], fluo4_header: row[4]}
                raw_fluo = raw_fluo.append(dict_temporary_fluo, ignore_index=True)
            elif len(row[0]) == 2:
                temp = temp.append({temp_header: int(row[0])}, ignore_index=True)
        return temp, raw_fluo


# parse CSV files from GUI (fluo data and temp data in two separate CSV files)
def parse_GUI(fluo_filename, temp_filename):
    """
    parse CSV files from GUI (fluo data and temp data in 2 separate CSV files)
    :param fluo_filename: filepath for CSV file (1 of 2) storing data from GUI
    :param temp_filename: filepath for CSV file (2 of 2) storing data from GUI
    :return:
        temp: temperature (˚C) dataframe
        time: time (s) dataframe
        raw_fluo: raw fluorescence (RFU) dataframe
        cycles: cycle dataframe
    """
    temp_time_df = pd.read_csv(temp_filename, header=1)
    fluo_cyc_df = pd.read_csv(fluo_filename, header=1)
    time_header = 'Time (sec)' #"Time"
    temp_header = 'Temperature (°C)' #"Temperature"
    cyc_header = "Cycle"
    fluo1_header = "CH1"
    fluo2_header = "CH2"
    fluo3_header = "CH3"
    fluo4_header = "CH4"

    time = temp_time_df[[time_header]]
    temp = temp_time_df[[temp_header]]
    raw_fluo = fluo_cyc_df[[fluo1_header, fluo2_header, fluo3_header, fluo4_header]]
    cycles = fluo_cyc_df[[cyc_header]]

    time = time[time_header] - time[time_header][0]

    return temp, time, raw_fluo, cycles


if __name__ == "__main__":
    root = Tk.Tk()
    root.withdraw()  # use to hide tkinter window
    filename = askopenfilename(title = "Please select a CSV file with either 'GUI' or 'Serial' in the name.",
                               parent = root, filetypes = (("CSV Files","*.csv"),))

    # Setting dataframe headers
    string_arduino = "Serial"
    string_gui = "GUI"
    string_melt = "Melt"
    fluo1_header = "CH1"
    fluo2_header = "CH2"
    fluo3_header = "CH3"
    fluo4_header = "CH4"
    CH_header = "CH"
    Ct_header = "Ct"
    Ct_bs_header = "Ct_bs"

    # parse CSV file from Arduino Serial (fluo data embedded in temp data)
    if string_melt in filename:
        melt_temp, raw_melt_fluo = parse_serial(filename, melt_flag=True)

        drmf_dmt = pd.DataFrame()
        cols = [fluo1_header, fluo2_header, fluo3_header, fluo4_header]
        counter = 0
        for col in raw_melt_fluo.columns:
            drmf_dmt_each = melt(raw_melt_fluo[col],melt_temp)
            drmf_dmt[cols[counter]] = drmf_dmt_each.values[:,0]
            counter += 1
        print(drmf_dmt)

    # parse CSV file from Arduino Serial (fluo data embedded in temp data)
    elif string_arduino in filename:
        serial_file_chosen_str = "You selected the CSV file '" + os.path.basename(filename) + "' with Arduino Serial data."
        print(serial_file_chosen_str)
        # check if Arduino Serial file is for melt curve analysis data (as opposed to PCR/MOB)
        # if string_melt not in filename:
        temp, time, raw_fluo, cycles = parse_serial(filename)

    # parse CSV files from GUI (fluo data and temp data in two separate CSV files)
    elif string_gui in filename:
        string_fluo = "fluo"
        string_temp = "temp"
        if string_fluo in filename:
            fluo_filename = filename
            GUI_fluo_file_chosen_str = "You selected the CSV file '" + os.path.basename(fluo_filename) + "' with GUI fluorescence data."
            print(GUI_fluo_file_chosen_str)
            temp_filename = askopenfilename(title = "Please select an additional CSV file with 'GUI' and 'temp' in the name.",
                                            filetypes = (("CSV Files","*.csv"),))
            GUI_temp_file_chosen_str = "You selected the CSV file '" + os.path.basename(temp_filename) + "' with GUI temperature data."
            print(GUI_temp_file_chosen_str)
            temp, time, raw_fluo, cycles = parse_GUI(fluo_filename, temp_filename)
        elif string_temp in filename:
            temp_filename = filename
            GUI_temp_file_chosen_str = "You selected the CSV file '" + os.path.basename(temp_filename) + "' with GUI temperature data."
            print(GUI_temp_file_chosen_str)
            fluo_filename = askopenfilename(title = "Please select an additional CSV file with 'GUI' and 'fluo' in the name.",
                                            filetypes = (("CSV Files","*.csv"),))
            GUI_fluo_file_chosen_str = "You selected the CSV file '" + os.path.basename(fluo_filename) + "' with GUI fluorescence data."
            print(GUI_fluo_file_chosen_str)
            temp, time, raw_fluo, cycles = parse_GUI(fluo_filename, temp_filename)
        else:
            showerror("Error", "Please select a CSV file with 'GUI' and either 'fluo' or 'temp' in the name.")
    else:
        showerror("Error", "Please select a CSV file with either 'GUI' or 'Serial' in the name.")

    # AT's original:
    # cycles = raw_fluo[:, 0]
    # raw_fluo = raw_fluo[:, 1:]

    # bs_fluo = np.zeros_like(raw_fluo)
    bs_fluo = pd.DataFrame(columns=[fluo1_header, fluo2_header, fluo3_header, fluo4_header])

    # Calculate Cts
    Cts = []
    # ct_log_all = pd.DataFrame(columns=[fluo1_header, fluo2_header, fluo3_header, fluo4_header])
    for col in raw_fluo.columns: #range(0, raw_fluo.shape[1]):
        # ct_log, ct_thres, bsl, std, dslope = analyzeCT(raw_fluo[:, col], std_threshold=12, slope_threshold=4)
        ct_log, ct_thres, bsl, std, dslope = analyzeCT(raw_fluo[col], std_threshold=12, slope_threshold=4)
        Cts.append(ct_thres)
        # ct_log_all[col] = ct_log
        bs_fluo_df = baseline_subtract(raw_fluo[col])
        bs_fluo[col] = bs_fluo_df[0] # avoids making a column of lists with the baseline-subtracted data
    Cts_bs = []
    # ct_log_all = pd.DataFrame(columns=[fluo1_header, fluo2_header, fluo3_header, fluo4_header])
    for col in bs_fluo.columns:  # range(0, raw_fluo.shape[1]):
        ct_log_bs, ct_thres_bs, bsl_bs, std_bs, dslope_bs = analyzeCT(bs_fluo[col], std_threshold=12, slope_threshold=4)
        Cts_bs.append(ct_thres_bs)

    # Printing Cts
    CH_df = pd.DataFrame({CH_header: range(1,5)}) # range(1,raw_fluo.shape[1]+1)}) #
    Cts_df = pd.DataFrame({Ct_header: Cts})
    Cts_bs_df = pd.DataFrame({Ct_bs_header: Cts_bs})
    CH_df = CH_df.reset_index(drop=True)     # reset index
    Cts_df = Cts_df.reset_index(drop=True)     # reset index
    Cts_bs_df = Cts_bs_df.reset_index(drop=True)     # reset index
    CH_Ct_df = CH_df.join(Cts_df)
    CH_Ct_Ct_bs_df = CH_Ct_df.join(Cts_bs_df)
    print(CH_Ct_Ct_bs_df.to_string(index=False))

    # Setting legend text after prompting user
    legend = []
    for CH_num in CH_df[CH_header].to_numpy():
        label_input_str = 'Please enter the label for CH' + str(CH_num) + ': '
        CH_label = input(label_input_str)
        legend_str = 'CH-' + str(CH_num) + ' (' + CH_label + ')'
        legend.append(legend_str)

    # # Plotting melt data
    # fig_melt = plt.figure(0)
    # plt.plot(melt_temp.loc[1:28,:], drmf_dmt.loc[1:,:])
    # plt.xlabel('Temperature (˚C)')
    # plt.ylabel('-dFluo/dTemp (RFU/˚C)')
    # plt.legend(legend[0:4])
    # melt_profile_title_str = 'Melt Profile for ' + os.path.basename(filename) +\
    #                          '\n(Fitted Baseline Correction; 3 Pt Moving Average Filter)'
    # plt.title(melt_profile_title_str)
    # plt.show()

    # Plotting parameters
    SMALL_SIZE = 14
    MEDIUM_SIZE = 16
    # BIGGER_SIZE = 18
    plt.rc('font', size=SMALL_SIZE)  # controls default text sizes
    plt.rc('axes', titlesize=SMALL_SIZE)  # fontsize of the axes title
    plt.rc('axes', labelsize=MEDIUM_SIZE)  # fontsize of the x and y labels
    plt.rc('xtick', labelsize=SMALL_SIZE)  # fontsize of the tick labels
    plt.rc('ytick', labelsize=SMALL_SIZE)  # fontsize of the tick labels
    plt.rc('legend', fontsize=SMALL_SIZE)  # legend fontsize

    # Plotting analyzed data
    fig_bs = plt.figure(0)
    plt.plot(cycles.head(45), bs_fluo.head(45))
    plt.xlabel('Cycle')
    plt.ylabel('Fluorescence (RFU)')
    plt.legend(legend[0:4])
    # analyzed_pcr_title_str = os.path.basename(filename) + '\n(Fitted Baseline Correction; 3 Pt Moving Average Filter)'
    # plt.title(analyzed_pcr_title_str)
    plt.show()

    # Plotting raw data
    fig_raw = plt.figure(1)
    plt.plot(cycles.head(45), raw_fluo.head(45))
    plt.xlabel('Cycle')
    plt.ylabel('Fluorescence (RFU)')
    plt.legend(legend[0:4])
    raw_pcr_title_str = os.path.basename(filename) + '\n(Raw Signal)'
    plt.title(raw_pcr_title_str)
    plt.show()

    # Plotting raw data
    # fig_ct_log_all = plt.figure(2)
    # plt.plot(cycles.head(45), ct_log_all.head(45))
    # plt.xlabel('Cycle')
    # plt.ylabel('Fluorescence (RFU)')
    # plt.legend(legend[0:4])
    # # plt.title('MOB with EsophaCap & CpG-methylated DNA (β-Actin) 20210118 \n (Raw Signal)')
    # # raw_pcr_title_str = str(os.path.splitext(filename[0])) + '\n(Raw Signal)'
    # raw_pcr_title_str = os.path.basename(filename) + '\n(Ct Log)'
    # plt.title(raw_pcr_title_str)
    # plt.show()

    # Plotting thermal profile
    fig_temp = plt.figure(3)
    plt.plot(time, temp)
    plt.xlabel('Time (s)')
    plt.ylabel('Temperature (˚C)')
    thermal_profile_title_str = 'Thermal Profile for ' + os.path.basename(filename) #str(os.path.splitext(filename[0]))
    plt.title(thermal_profile_title_str)
    plt.show()
