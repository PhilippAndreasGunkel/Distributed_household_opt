#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed May 18 13:19:07 2022

@author: phgu
"""


import pandas as pd
import numpy as np
#import matplotlib.pyplot as plt
#import seaborn as sns
#from datetime import datetime
#from statistics import mean 
#from itertools import islice 
#import random
#import matplotlib
#from matplotlib import cm
#from math import isnan
import glob, os
#from multiprocessing import Pool
import time
import warnings
warnings.filterwarnings("ignore")

res_dict_names = {"*_c_El.csv":"Electricity cost",
            "*_c_El_pv.csv":"Electricity production cost from PV",
            "*_c_El_im.csv":"Electricity cost from import",
            "*_c_El_gt.csv":"Grid tariff cost",
            "*_c_El_tx.csv":"Tax cost",
            "*_r_El.csv":"Revenue from electricity export",
            "*_r_Tx.csv":"Tax reimbursment",
            "*_c_Obj.csv":"Total cost of electricity",
            "*_q_El_pv_hp.csv":"PV to HP",
            "*_q_El_bt_hp.csv":"BT to HP",            
            "*_q_El_mp_hp.csv":"MP to HP",            
            "*_q_El_pv_ev.csv":"PV to EV",
            "*_q_El_bt_ev.csv":"BT to EV",            
            "*_q_El_mp_ev.csv":"MP to EV",                
            "*_q_El_pv_bt.csv":"PV to BT",              
            "*_q_El_pv_mp.csv":"PV to MP",              
            "*_q_El_bt_mp.csv":"BT to MP",              
            "*_q_El_mp_bt.csv":"MP to BT",              
            "*_q_El_mp_c.csv":"MP to CO",         
            "*_q_El_bt_c.csv":"BT to CO",    
            "*_q_El_pv_c.csv":"PV to CO",
            "*_cap_inv_pv.csv":"Capacity of PV",
            "*_cap_inv_hst.csv":"Capacity of HST",
            "*_cap_inv_bt.csv":"Capacity of BT",
            "*_cap_inv_hp.csv":"Capacity of HP"
            }




li_sum = ["*_c_El.csv",
            "*_c_El_pv.csv",
            "*_c_El_im.csv",
            "*_c_El_gt.csv",
            "*_c_El_tx.csv",
            "*_r_El.csv",
            "*_r_Tx.csv",
            "*_q_El_pv_hp.csv",
            "*_q_El_bt_hp.csv",           
            "*_q_El_mp_hp.csv",           
            "*_q_El_pv_ev.csv",
            "*_q_El_bt_ev.csv",          
            "*_q_El_mp_ev.csv",              
            "*_q_El_pv_bt.csv",              
            "*_q_El_pv_mp.csv",         
            "*_q_El_bt_mp.csv",             
            "*_q_El_mp_bt.csv",            
            "*_q_El_mp_c.csv" ,       
            "*_q_El_bt_c.csv" ,  
            "*_q_El_pv_c.csv"]

cols_list_addition = [res_dict_names[k] for k in res_dict_names.keys()]
cols_list_addition_tech = ["Max consumption", "Average consumption", "Median consumption", "Std consumption"]
key_list_files = [k for k in res_dict_names.keys()]

households = pd.read_csv(r"/zhome/da/2/118904/Distributed_Household/Household_Opt_Distributed/data/house_ident_sort.csv",sep=",").set_index("H_ID")
for col in cols_list_addition:
    households[col] = 0
for col in cols_list_addition_tech:
    households[col] = 0

households=households.T
#households.loc["Capacity of PV"].unique()S






os.chdir(r'/zhome/da/2/118904/Distributed_Household/Household_Opt_Distributed/results')

path= r'/zhome/da/2/118904/Distributed_Household/Household_Opt_Distributed/results'

iteration = 0
file_list_sum = []

while iteration < 15:    
    print(iteration)
    
    file_list = glob.glob("*.csv")
    time.sleep(40) ### Sleep to avoid permission errors while accessing files that are being written at the moment when folder is screened
    
    
    
    
    for k in key_list_files:
        #print(k)
        for file in file_list:
            file_list_sum.extend(file[:-len(k)+1]) 
            #print(k)
            if str("*"+file[-len(k)+1:]) == k: 
                #print(k)
                if k in li_sum:
                    households.loc[res_dict_names[k],file[:-len(k)+1]]=np.round(pd.read_csv(file,sep=',').sum()["Value"],decimals=2) 
                    #print(str(file[:-len(k)+1])+" "+str(np.round(pd.read_csv(file,sep=',').sum()["Value"],decimals=2)))
                    #print(file+" "+str(file[:len(k)+1]))
                    #print(k)
                
                if k in ["*_c_Obj.csv","*_cap_inv_bt.csv","*_cap_inv_hst.csv","*_cap_inv_hp.csv","*_cap_inv_pv.csv"]:
                    households.loc[res_dict_names[k],file[:-len(k)+1]]=np.round(pd.read_csv(file,sep=',')["Value"][0],decimals=2) 
                    #print(k)    
                else:
                    pass
            else:
                pass
             
             
    #print('there')         
    #df = households.iloc[3]        
    #df = df[df !=0]
    #df2=households[df.index]         
    
    
    
    for file in file_list:
        os.remove(os.path.join(path, file))
    
    if len(file_list)==0:
        iteration = iteration +1
        print("Empty")
    if len(file_list)!=0:
        iteration = 0
        print("Files: "+str(len(file_list)))
    
    time.sleep(10)

households.T.to_csv(r'/zhome/da/2/118904/Distributed_Household/Result_summary.csv')


#households.loc["Capacity of PV"].unique()



