#!/usr/bin/env python
import os
import sys
import csv
import numpy as np
import pandas as pd
import scipy
from scipy.optimize import leastsq
from scipy import stats
import tkinter as Tk
from tkinter.filedialog import askopenfilename
from tkinter.messagebox import showerror
import matplotlib.pyplot as plt


def read_csv(filename):
    data = np.genfromtxt(filename, delimiter=',', skip_header=1)
    return data


def baseline_sub(raw_fluo):
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
        slope, intercept, r_value, p_value, std_err = stats.linregress(x[1:19], fluo[1:19])  # fit to cycles 2-20
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


def analyzeCT(raw_fluo_df, std_threshold=12, slope_threshold=0.5):
    np.seterr(all='ignore')
    raw_fluo = raw_fluo_df.to_numpy()

    if isinstance(raw_fluo, np.ndarray):
        n_cycles = raw_fluo.size
    elif isinstance(raw_fluo, list):
        n_cycles = len(raw_fluo)
    else:
        print('analyzeCT unable to interpret fluo data')
        return [-1, -1]

    bs_fluo_df = baseline_sub(raw_fluo_df)
    bs_fluo = bs_fluo_df[0].to_numpy()

    cycles = np.linspace(0, n_cycles, n_cycles)

    ct_log = 0
    ct_thres = 0
    bsl = 0
    std = 0

    # Calculate baseline value using cycles n0 through n1
    n0 = 10
    n1 = 20
    cycle_bsl = []
    dslope = 0
    if n_cycles > n1:
        # Check if values lie within interquartile range (IQR) -- remove outliers
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
        fluo_thres = bsl + std_threshold * std

        # check which cycles meet the threshold
        ct_thresh_idxs = np.argwhere(bs_fluo[n1:] > fluo_thres)
        ct_thresh_idx = 0
        for i in ct_thresh_idxs:
            slope1, intercept1, r_value1, p_value1, std_err1 = stats.linregress(cycles[10:20],
                                                                                bs_fluo[10:20])  # fit slope of baseline
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
            #          (3) last fluorescence value is at least 1 stdev RFU greater than fluo baseline avg

            if r_value2 > 0.9 and dslope > slope_threshold and raw_fluo[n1 + i] > np.mean(bs_fluo[n0:n1]):
                ct_thresh_idx = n1 + i
                break
            else:
                ct_thresh_idx = -1

        # interpolate cycles numbers
        if ct_thresh_idx > 0:
            div = 0.05
            cycles_interp = np.linspace(ct_thresh_idx - 2, ct_thresh_idx + 1, int(3 / div))
            slope2_fluo = slope2 * cycles + intercept2
            fluo_interp = np.interp(cycles_interp, cycles, slope2_fluo)

            ct_thres = cycles_interp[np.argmax(fluo_interp > fluo_thres), 0]  # argmax returns first instance

        # Fit equation using least squares optimization if signal rises above threshold
        ct_log = 0
        if ct_thres > 0.0001:
            p0 = [30, 30, 5, 30]  # Initial guess for parameters
            plsq = leastsq(residuals, p0, args=(bs_fluo, cycles), maxfev=10000)
            ct_log = ct_logistic(plsq[0])

    return [ct_log, ct_thres, bsl, std * std_threshold, dslope]


# Helper functions for CT calculation
def logistic4(x, A, B, C, D):
    """4PL lgoistic equation."""
    return ((A - D) / (1.0 + ((x / C) ** B))) + D


def residuals(p, y, x):
    """Deviations of data from fitted 4PL curve"""
    A, B, C, D = p
    err = y - logistic4(x, A, B, C, D)
    return err


def peval(x, p):
    """Evaluated value at x with current parameters."""
    A, B, C, D = p
    return logistic4(x, A, B, C, D)


def ct_logistic(p):
    """Calculate Ct based on 4P logistic regression fittig."""
    A, B, C, D = p
    Ct = C * ((-(3.0 * B ** 2.0 * (B ** 2.0 - 1.0)) ** 0.5 - 2.0 * (1.0 - B ** 2.0)) / (B ** 2.0 + 3.0 * B + 2.0)) ** (
                1.0 / B)  # (Tichopad et al 2003)
    return Ct


def parse_serial(filename):
    df = pd.read_csv(filename, header=None)
    time_header = "Time"
    temp_header = "Temperature"
    cyc_header = "Cycles"
    fluo1_header = "CH1"
    fluo2_header = "CH2"
    fluo3_header = "CH3"
    fluo4_header = "CH4"

    temp_time = pd.DataFrame(columns=[time_header, temp_header])
    raw_fluo = pd.DataFrame(columns=[fluo1_header, fluo2_header, fluo3_header, fluo4_header])
    cycles = pd.DataFrame(columns=[cyc_header])

    for index, row in df.iterrows():
        if not (row[0] == "Fluo"):
            dict_temporary_temp_time = {time_header: float(row[0]), temp_header: row[1]}
            temp_time = temp_time.append(dict_temporary_temp_time, ignore_index=True)
        else:
            dict_temporary_fluo = {fluo1_header: row[1], fluo2_header: row[2],
                    fluo3_header: row[3], fluo4_header: row[4]}
            raw_fluo = raw_fluo.append(dict_temporary_fluo, ignore_index=True)
            cycles = cycles.append({cyc_header: row[6]}, ignore_index=True)

    time = temp_time[time_header] - temp_time[time_header][0]
    temp = temp_time[temp_header]

    return temp, time, raw_fluo, cycles


# *incomplete as of Jan 19 2021*
def parse_GUI(temp_filename, fluo_filename):
    temp_time_df = pd.read_csv(temp_filename, header=None)
    fluo_cyc_df = pd.read_csv(fluo_filename, header=None)
    time_header = "Time"
    temp_header = "Temperature"
    cyc_header = "Cycles"
    fluo1_header = "CH1"
    fluo2_header = "CH2"
    fluo3_header = "CH3"
    fluo4_header = "CH4"

    temp_time = pd.DataFrame(columns=[time_header, temp_header])
    raw_fluo = pd.DataFrame(columns=[fluo1_header, fluo2_header, fluo3_header, fluo4_header])
    cycles = pd.DataFrame(columns=[cyc_header])

    for index, row in df.iterrows():
        if not (row[0] == "Fluo"):
            dict_temporary_temp_time = {time_header: float(row[0]), temp_header: row[1]}
            temp_time = temp_time.append(dict_temporary_temp_time, ignore_index=True)
        else:
            dict_temporary_fluo = {fluo1_header: row[1], fluo2_header: row[2],
                    fluo3_header: row[3], fluo4_header: row[4]}
            raw_fluo = raw_fluo.append(dict_temporary_fluo, ignore_index=True)
            cycles = cycles.append({cyc_header: row[6]}, ignore_index=True)

    time = temp_time[time_header] - temp_time[time_header][0]
    temp = temp_time[temp_header]

    return temp, time, raw_fluo, cycles


if __name__ == "__main__":
    filename = askopenfilename(title = "Please select a CSV file with either 'GUI' or 'Serial' in the name.",filetypes = (("CSV Files","*.csv"),))

    string_arduino = "Serial"
    string_gui = "GUI"
    fluo1_header = "CH1"
    fluo2_header = "CH2"
    fluo3_header = "CH3"
    fluo4_header = "CH4"
    bs_fluo1_header = "CH1"
    bs_fluo2_header = "CH2"
    bs_fluo3_header = "CH3"
    bs_fluo4_header = "CH4"

    # parse CSV file from Arduino Serial (fluo data embedded in temp data)
    if string_arduino in filename:
        temp, time, raw_fluo, cycles = parse_serial(filename)

    # parse CSV files from GUI (fluo data and temp data in two separate CSV files)
    # *incomplete as of Jan 19 2021*
    elif string_gui in filename:
        string_fluo = "fluo"
        string_temp = "temp"
    #     raw_fluo_cyc = {}
    #     raw_temp_time = {}
        if string_fluo in filename:
            fluo_filename = filename
            temp_filename = askopenfilename(title = "Please select an additional CSV file with 'GUI' and 'temp' in the name.",
                                            filetypes = (("CSV Files","*.csv"),))
            temp, time, raw_fluo, cycles = parse_GUI(fluo_filename, temp_filename)
        elif string_temp in filename:
            temp_filename = filename
            fluo_filename = askopenfilename(title = "Please select an additional CSV file with 'GUI' and 'fluo' in the name.",
                                            filetypes = (("CSV Files","*.csv"),))
            temp, time, raw_fluo, cycles = parse_GUI(fluo_filename, temp_filename)
        else:
            showerror("Error", "Please select a CSV file with 'GUI' and either 'fluo' or 'temp' in the name.")
    #     raw_fluo_cyc = read_csv(filename_fluo)
    #     raw_temp_time = read_csv(filename_temp)

    else:
        showerror("Error", "Please select a CSV file with either 'GUI' or 'Serial' in the name.")

    # AT's original:
    # cycles = raw_fluo[:, 0]
    # raw_fluo = raw_fluo[:, 1:]

    CH = range(1,raw_fluo.shape[1]+1)
    # bs_fluo = np.zeros_like(raw_fluo)
    bs_fluo = pd.DataFrame(columns=[bs_fluo1_header, bs_fluo2_header, bs_fluo3_header, bs_fluo4_header])

    Cts = []
    # CH = []
    for col in raw_fluo.columns: #range(0, raw_fluo.shape[1]):
        # ct_log, ct_thres, bsl, std, dslope = analyzeCT(raw_fluo[:, col], std_threshold=12, slope_threshold=4)
        ct_log, ct_thres, bsl, std, dslope = analyzeCT(raw_fluo[col], std_threshold=12, slope_threshold=4)
        Cts.append(ct_thres)
        bs_fluo_df = baseline_sub(raw_fluo[col])
        bs_fluo[col] = bs_fluo_df[0]
        # CH.append(col+1)

    # Make a table listing cartridge channel with Ct
    # https: // stackoverflow.com / questions / 9535954 / printing - lists -as-tabular - data
    # row_format = "{:>15}" * (len(teams_list) + 1)
    # print(row_format.format("", *teams_list))
    # for team, row in zip(teams_list, data):
    #     print(row_format.format(team, *row))

    print('Cts: ')
    print(Cts)

    legend = []
    for CH_num in CH:
        label_input_str = 'Please enter the label for CH' + str(CH_num) + ': '
        CH_label = input(label_input_str)
        legend_str = 'CH-' + str(CH_num) + ' (' + CH_label + ')'
        legend.append(legend_str)

    # plt_title_input_str = 'Please enter a title for the plots'
    # plt_title_str = input(plt_title_input_str)

    fig_bs = plt.figure(0)
    plt.plot(cycles[0:45], bs_fluo[[bs_fluo1_header, bs_fluo2_header]].head(45))#[0:44])
    plt.xlabel('Cycle')
    plt.ylabel('Fluorescence (RFU)')
    plt.legend(legend[0:2])
    # plt.title('MOB with EsophaCap & CpG-methylated DNA (β-Actin) 20210118 \n (Fitted Baseline Correction; 3 Pt Moving Average Filter)')
    # analyzed_pcr_title_str = str(os.path.splitext(filename[0])) + '\n(Fitted Baseline Correction; 3 Pt Moving Average Filter)'
    analyzed_pcr_title_str = os.path.basename(filename) + '\n(Fitted Baseline Correction; 3 Pt Moving Average Filter)'
    plt.title(analyzed_pcr_title_str)
    plt.show()

    print(raw_fluo)
    fig_raw = plt.figure(1)
    plt.plot(cycles[0:45], raw_fluo[[fluo1_header, fluo2_header]].head(45))#[0:44])
    plt.xlabel('Cycle')
    plt.ylabel('Fluorescence (RFU)')
    plt.legend(legend[0:2])
    # plt.title('MOB with EsophaCap & CpG-methylated DNA (β-Actin) 20210118 \n (Raw Signal)')
    # raw_pcr_title_str = str(os.path.splitext(filename[0])) + '\n(Raw Signal)'
    raw_pcr_title_str = os.path.basename(filename) + '\n(Raw Signal)'
    plt.title(raw_pcr_title_str)
    plt.show()

    fig_temp = plt.figure(2)
    plt.plot(time, temp)
    plt.xlabel('Time (s)')
    plt.ylabel('Temperature (˚C)')
    # plt.title('Thermal Profile for 20210118 MOB')
    thermal_profile_title_str = 'Thermal Profile for ' + os.path.basename(filename) #str(os.path.splitext(filename[0]))
    plt.title(thermal_profile_title_str)
    plt.show()
