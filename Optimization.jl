using CSV, DataFrames
using JuMP, Ipopt, GLPK, Gurobi#Gurobi, CPLEX

global function Model_opt(H_id)
    
    
    
    M = Model(Gurobi.Optimizer)
    set_optimizer_attribute(M, "Threads", 1)
    println(H_id)

    

    T_s2 = T[2:size(T)[1]]
    T_1s = T[1]

    df_house_characteristics,nT_He,HE_Ar,d_El,q_EV_fcharge,bin_EV_avail,SOC_EV_trip,cap_hp,cap_hst,cap_pv,cap_bt = func_load_specific_data(H_id)
    EL_Id = df_house_characteristics[3,:]
    HE_Id = df_house_characteristics[9,:]
    EV_Id = df_house_characteristics[2,:]
    CAT_Id = df_house_characteristics[1,:]
    H = names(df_house_characteristics)
    
    bin_bt = 1
    bin_ev = 1
    bin_pv = 1
    bin_hp = 1
    bin_hst = 1
    ########### XXXX implement bins to say yes or no
    
    #cap_pv = 5
    cap_ev=45
    cap_ev_ch = 10
    soc_EV_init = cap_ev
    #cap_hp = 30
    cap_mp = 21
    #cap_bt = 6
    soc_bt_init = 0
    cap_bt_ch = 2
    mu_bt = 0.95
    p_El_pv = 0#0.059 #€/kWh LCOE https://vbn.aau.dk/ws/portalfiles/portal/266332758/Main_Report_The_role_of_Photovoltaics_towards_100_percent_Renewable_Energy_Systems.pdf
    tx_El = 0.12*0.68   # Elafgift https://skat.dk/skat.aspx?oid=2061620
    gt_ds = 0.025 #18.5
    gt_ts = 0.011#https://energinet.dk/Om-nyheder/Nyheder/2017/04/25/Elforbrugernes-net-og-systemtarif-bliver-8-3-ore-kWh-i-2017
    #cap_hst = 3   #https://ens.dk/sites/ens.dk/files/Analyser/technology_data_catalogue_for_energy_storage.pdf
    soc_hst_init = 0
    cap_hst_ch = 20   #https://ens.dk/sites/ens.dk/files/Analyser/technology_data_catalogue_for_energy_storage.pdf
    mu_hst_t = 0.979 #https://ens.dk/sites/ens.dk/files/Analyser/technology_data_catalogue_for_energy_storage.pdf
    ##### Consider an average cost for el production from PV
    #@variable(M,slack[t=T,h=H],lower_bound=-5000,upper_bound=5000,base_name="slack[t=T,h=H]:") # Electricity flow from meter point to consumption
    
### Flow variables    
    @variable(M,q_El_mp_c[t=T,h=H],lower_bound=0,base_name="q_El_mp_c[t=T,h=H]:") # Electricity flow from meter point to consumption
    @variable(M,q_El_mp_ev[t=T,h=H],lower_bound=0,upper_bound=cap_ev_ch*bin_EV_avail[t,EV_Id[H_id][1]]*bin_ev,base_name="q_El_mp_ev[t=T,h=H]:") # Electricity flow from meter point to EV
    @variable(M,q_El_mp_bt[t=T,h=H],lower_bound=0,upper_bound=cap_mp*bin_bt,base_name="q_El_mp_bt[t=T,h=H]:") # Electricity flow from meter point to EV
 
    #if model_scenario == "New_Tax"
    #    @variable(M,q_El_mp_btvs[t=T,h=H],lower_bound=0,upper_bound=cap_bt[h]*bin_bt,base_name="q_El_mp_btvs[t=T,h=H]:") # Electricity flow from meter point to EV
    #end

    @variable(M,q_El_pv_c[t=T,h=H],lower_bound=0,upper_bound=cap_pv[h]*bin_pv,base_name="q_El_pv_c[t=T,h=H]:") # Electricity flow from PV to consumption
    @variable(M,q_El_pv_mp[t=T,h=H],lower_bound=0,upper_bound=cap_pv[h]*bin_pv,base_name="q_El_pv_mp[t=T,h=H]:") # Electricity flow from PV to meter point
    @variable(M,q_El_pv_ev[t=T,h=H],lower_bound=0,upper_bound=cap_pv[h]*bin_pv*bin_ev,base_name="q_El_pv_ev[t=T,h=H]:") # Electricity flow from PV to EV
    @variable(M,q_El_pv_bt[t=T,h=H],lower_bound=0,upper_bound=cap_mp*bin_pv*bin_bt,base_name="q_El_pv_bt[t=T,h=H]:") # Electricity flow from PV to BT

    @variable(M,q_El_bt_mp[t=T,h=H],lower_bound=0,upper_bound=cap_mp*bin_bt,base_name="q_El_bt_mp[t=T,h=H]:") # Electricity flow from BT to meter point
    @variable(M,q_El_bt_ev[t=T,h=H],lower_bound=0,upper_bound= cap_mp*bin_bt*bin_ev,base_name="q_El_bt_ev[t=T,h=H]:") # Electricity flow from BT to EV
    @variable(M,q_El_bt_c[t=T,h=H],lower_bound=0,upper_bound= cap_mp*bin_bt,base_name="q_El_bt_c[t=T,h=H]:") # Electricity flow from BT to consumption    
    
    #if model_scenario == "New_Tax"
    #    @variable(M,q_El_btvs_mp[t=T,h=H],lower_bound=0,upper_bound=cap_bt[h]*bin_bt,base_name="q_El_btvs_mp[t=T,h=H]:") # Electricity flow from BT to meter point
    #end

    @variable(M,q_El_pv_hp[t=T,h=H],lower_bound=0,upper_bound=cap_mp*bin_hp,base_name="q_El_pv_hp[t=T,h=H]:") # Electricity flow from PV to HP    
    @variable(M,q_El_mp_hp[t=T,h=H],lower_bound=0,upper_bound=cap_mp*bin_hp,base_name="q_El_mp_hp[t=T,h=H]:") # Electricity flow from meter point to HP
    @variable(M,q_El_bt_hp[t=T,h=H],lower_bound=0,upper_bound=cap_mp*bin_hp,base_name="q_El_bt_hp[t=T,h=H]:") # Electricity flow from BT to HP


    @variable(M,q_He_hp_hst[t=T,h=H],lower_bound=0,upper_bound=cap_hst_ch*bin_hst,base_name="q_He_hp_hst[t=T,h=H]:") # Heat flow from HP to heat storage
    @variable(M,q_He_hp_c[t=T,h=H],lower_bound=0,upper_bound=cap_mp*bin_hp,base_name="q_He_hp_c[t=T,h=H]:") # Heat flow from HP to heat consumption
    @variable(M,q_He_hst_c[t=T,h=H],lower_bound=0,upper_bound=cap_hst_ch*bin_hst,base_name="q_He_hst_c[t=T,h=H]:") # Heat flow from heat storage to heat consumption

 
### Technology variables
    #@variable(M,im_El_mp[t=T,h=H],lower_bound=0,upper_bound=cap_mp,base_name="im_El_mp[t=T,h=H]:") # Electricity import capacity to meter point
    #@variable(M,ex_El_mp[t=T,h=H],lower_bound=0,upper_bound=cap_mp,base_name="ex_El_mp[t=T,h=H]:") # Electricity import capacity to meter point


    @variable(M,g_El_pv[t=T,h=H],lower_bound=0,upper_bound=cap_pv[h]*bin_pv,base_name="g_El_pv[t=T,h=H]:") # Electricity generation PV

    @variable(M,soc_El_ev[t=T,h=H],lower_bound=0,upper_bound=cap_ev*bin_EV_avail[t,EV_Id[H_id][1]]*bin_ev,base_name="soc_El_ev[t=T,h=H]:") # State of charge of EV 
    @variable(M,ch_El_ev[t=T,h=H],lower_bound=0,upper_bound=cap_ev_ch*bin_EV_avail[t,EV_Id[H_id][1]]*bin_ev,base_name="ch_El_ev[t=T,h=H]:") # Electricity charging capacity of EV

    @variable(M,soc_El_bt[t=T,h=H],lower_bound=0,upper_bound=cap_bt[h]*bin_bt,base_name="soc_El_bt[t=T,h=H]:") # State of charge of BT 
    @variable(M,ch_El_bt[t=T,h=H],lower_bound=0,upper_bound=cap_bt_ch*bin_bt,base_name="ch_El_bt[t=T,h=H]:") # Electricity charging capacity of BT
    @variable(M,dch_El_bt[t=T,h=H],lower_bound=0,upper_bound=cap_bt_ch*bin_bt,base_name="dch_El_bt[t=T,h=H]:") # Electricity discharging capacity of BT

    #@variable(M,soc_El_btvs[t=T,h=H],lower_bound=0,upper_bound=cap_bt[h]*bin_bt,base_name="soc_El_btvs[t=T,h=H]:") # State of charge of BT 
    #@variable(M,ch_El_btvs[t=T,h=H],lower_bound=0,upper_bound=cap_bt_ch*bin_bt,base_name="ch_El_btvs[t=T,h=H]:") # Electricity charging capacity of BT
    #@variable(M,dch_El_btvs[t=T,h=H],lower_bound=0,upper_bound=cap_bt_ch*bin_bt,base_name="dch_El_btvs[t=T,h=H]:") # Electricity discharging capacity of BT


    @variable(M,soc_He_hst[t=T,h=H],lower_bound=0,upper_bound=cap_hst[h]*bin_hst,base_name="soc_He_hst[t=T,h=H]:") # Heat generation HP
    @variable(M,ch_He_hst[t=T,h=H],lower_bound=0,upper_bound=cap_hst_ch*bin_hst,base_name="ch_He_hst[t=T,h=H]:") # Heat generation HP
    @variable(M,dch_He_hst[t=T,h=H],lower_bound=0,upper_bound=cap_hst_ch*bin_hst,base_name="dch_He_hst[t=T,h=H]:") # Heat generation HP


### Cost variables
    @variable(M,c_El[t=T,h=H],base_name="c_El[t=T,h=H]:") # Electricity cost
    @variable(M,c_El_pv[t=T,h=H],base_name="c_El_pv[t=T,h=H]:") # Electricity cost from PV production
    @variable(M,c_El_im[t=T,h=H],base_name="c_El_im[t=T,h=H]:") # Electricity cost from consumption

    @variable(M,c_El_gt[t=T,h=H],base_name="c_El_gt[t=T,h=H]:") # Electricity cost from grid tariff payments
    @variable(M,c_El_tx[t=T,h=H],base_name="c_El_tx[t=T,h=H]:") # Electricity cost from tax payments

    @variable(M,r_El[t=T,h=H],base_name="r_El[t=T,h=H]:") # Electricity revenue

    @variable(M,r_Tx[t=T,h=H],base_name="r_Tx[t=T,h=H]:") # Electricity revenue

### Investment variables
    @variable(M,g_cap_hp[h=H],lower_bound=0,upper_bound=cap_hp[h],base_name="g_cap_hp[h=H]:") # Generation capacity HP


### Obj variables
    @variable(M,c_Obj[h=H],base_name="c_Obj[h=H]:") # Electricity cost

    #@variable(M,C_BT[s=S],lower_bound=0,upper_bound=1,base_name="C_BT[s=S]:")
    #@variable(M,C_BT[s=S],lower_bound=0,upper_bound=1,base_name="C_BT[s=S]:")
    #@variable(M,C_BT[s=S],lower_bound=0,upper_bound=1,base_name="C_BT[s=S]:")

    #@variable(M,b_st[t=T,y=Y,h=H,s=S],lower_bound=0,upper_bound=1,base_name="b_st[t=T,y=Y,h=H,s=S]:")


    #### Define objective function

    if model_scenario == "BAU"
        @objective(M, Min, sum(
                                #+1 #Investment cost
                                #+1 #Operational and maintanance cost
                                #+1 #Fuel cost
                                #+1 #Grid tariffs
                                #+1 #Taxes
                                + c_El[t,h] # Cost Electricity import
                                + c_El_gt[t,h] # Cost grid tariff payments
                                + c_El_tx[t,h] # Cost tax payments
                                - r_El[t,h] # Revenue Electricity export
                                for t in T
                                for h in H
                                )
                    )
    elseif model_scenario == "New_Tax"
        @objective(M, Min, sum(
                                #+1 #Investment cost
                                #+1 #Operational and maintanance cost
                                #+1 #Fuel cost
                                #+1 #Grid tariffs
                                #+1 #Taxes
                                + c_El[t,h] # Cost Electricity import
                                + c_El_gt[t,h] # Cost grid tariff payments
                                + c_El_tx[t,h] # Cost tax payments
                                - r_El[t,h] # Revenue Electricity export
                                - r_Tx[t,h] #Refund tax
                                for t in T
                                for h in H
                                )
                    )

    end
### Cost constraints
    @constraint(M, Obj_cost[h in H], c_Obj[h] == sum(c_El[t,h] + c_El_gt[t,h] + c_El_tx[t,h] - r_El[t,h] for t in T )) #- r_El[t,h]+ q_El_mp_ev[t,h]

    @constraint(M, Electricity_cost[t in T,h in H], c_El[t,h] ==  + c_El_im[t,h]+c_El_pv[t,h]  ) #

    @constraint(M, Electricity_cost_pv[t in T,h in H], c_El_pv[t,h] == (q_El_pv_c[t,h]  + q_El_pv_ev[t,h] + q_El_pv_hp[t,h]+q_El_pv_bt[t,h]+q_El_pv_mp[t,h])*p_El_pv) #
    @constraint(M, Electricity_cost_mp[t in T,h in H], c_El_im[t,h] == (q_El_mp_c[t,h] + q_El_mp_ev[t,h] + q_El_mp_bt[t,h] + q_El_mp_hp[t,h])*(p_El[t])) #

    if model_scenario == "BAU"
        @constraint(M, Electricity_cost_gt[t in T,h in H], c_El_gt[t,h] == (q_El_mp_c[t,h] + q_El_mp_ev[t,h] + q_El_mp_bt[t,h] + q_El_mp_hp[t,h])*(gt_ds+gt_ts)) #
        @constraint(M, Electricity_cost_tx[t in T,h in H], c_El_tx[t,h] == (q_El_mp_c[t,h] + q_El_mp_ev[t,h] + q_El_mp_bt[t,h] + q_El_mp_hp[t,h])*(+tx_El)) #
        
        @constraint(M, Electricity_revenue[t in T,h in H], r_El[t,h] == (+ q_El_pv_mp[t,h] + q_El_bt_mp[t,h])*p_El[t]) #
    end


    if model_scenario == "New_Tax"
        @constraint(M, Electricity_cost_gt[t in T,h in H], c_El_gt[t,h] == (q_El_mp_c[t,h] + q_El_mp_ev[t,h] + q_El_mp_bt[t,h] + q_El_mp_hp[t,h])*(gt_ds+gt_ts)) #
        @constraint(M, Electricity_cost_tx[t in T,h in H], c_El_tx[t,h] == (q_El_pv_c[t,h]  + q_El_pv_ev[t,h] + q_El_pv_hp[t,h]+ q_El_pv_bt[t,h] + q_El_mp_c[t,h] + q_El_mp_ev[t,h] + q_El_mp_bt[t,h] + q_El_mp_hp[t,h])*(+tx_El)) #
        #@constraint(M, Electricity_cost_tx[t in T,h in H], c_El_tx[t,h] == (q_El_mp_c[t,h] + q_El_mp_ev[t,h] + q_El_mp_bt[t,h] + q_El_mp_hp[t,h]+ q_El_mp_btvs[t,h])*(+tx_El)) #
        
        @constraint(M, Electricity_revenue[t in T,h in H], r_El[t,h] == (+ q_El_pv_mp[t,h] + q_El_bt_mp[t,h] )*p_El[t]) #
        @constraint(M, Tax_revenue[t in T,h in H], r_Tx[t,h] == + q_El_bt_mp[t,h]*tx_El) #

    end



### Energy balance constraints
    @constraint(M, Electricity_Consumption[t in T,h in H], d_El[CAT_Id[h]][t,EL_Id[h]] == q_El_mp_c[t,h]  + q_El_pv_c[t,h] + q_El_bt_c[t,h])# 
    
    @constraint(M, EV_SOC_init[t in T_1s,h in H], soc_El_ev[t,h] == soc_EV_init * bin_ev + +ch_El_ev[t,h]*mu_bt ) #
    @constraint(M, EV_SOC[t in T_s2,h in H], soc_El_ev[t,h] == soc_El_ev[t-1,h]+SOC_EV_trip[t,EV_Id[H_id][1]] *bin_ev +ch_El_ev[t,h]*mu_bt )# 

    if model_scenario == "BAU"
        @constraint(M, BT_SOC_init[t in T_1s,h in H], soc_El_bt[t,h] == soc_bt_init + ch_El_bt[t,h]*mu_bt - dch_El_bt[t,h]*(1/mu_bt)) #
        @constraint(M, BT_SOC[t in T_s2,h in H], soc_El_bt[t,h] == soc_El_bt[t-1,h]+ ch_El_bt[t,h]*mu_bt - dch_El_bt[t,h]*(1/mu_bt))# 
    end

    if model_scenario == "New_Tax"
        @constraint(M, BT_SOC_init[t in T_1s,h in H], soc_El_bt[t,h] == soc_bt_init + ch_El_bt[t,h]*mu_bt - dch_El_bt[t,h]*(1/mu_bt)) #
        @constraint(M, BT_SOC[t in T_s2,h in H], soc_El_bt[t,h] == soc_El_bt[t-1,h] + ch_El_bt[t,h]*mu_bt - dch_El_bt[t,h]*(1/mu_bt))# 
        
    end

    @constraint(M, Heat_Consumption[t in T,h in H], nT_He[HE_Id[h]][t] * HE_Ar[h] * bin_hp == q_He_hp_c[t,h] +q_He_hst_c[t,h] )#nT_He[t,HE_Id[h][1]]*parse(Float16,HE_Ar[h][1])* HE_Ar[h]

    @constraint(M, HST_SOC_init[t in T_1s,h in H], soc_He_hst[t,h] == soc_hst_init*mu_hst_t + q_He_hp_hst[t,h] - q_He_hst_c[t,h]) #
    @constraint(M, HST_SOC[t in T_s2,h in H], soc_He_hst[t,h] == soc_He_hst[t-1,h]*mu_hst_t + q_He_hp_hst[t,h] - q_He_hst_c[t,h])# 


        
### Power balance constraints
    #@constraint(M, MP_imppower_balance[t in T, h in H], im_El_mp[t,h] ==  q_El_mp_c[t,h]+ q_El_mp_ev[t,h]) # + q_El_mp_bt[t,h] + q_El_mp_hp[t,h] 
    #@constraint(M, MP_exppower_balance[t in T, h in H], ex_El_mp[t,h] ==  q_El_pv_mp[t,h] ) #+ q_El_bt_mp[t,h] 
    #@constraint(M, MP_power_balance[t in T, h in H], cap_mp >=  im_El_mp[t,h] ) #+ ex_El_mp[t,h]

    @constraint(M, PV_power_balance[t in T, h in H], cap_pv[h] * nT_PV[t] >= q_El_pv_c[t,h]  + q_El_pv_ev[t,h] + q_El_pv_mp[t,h] + q_El_pv_bt[t,h] + q_El_pv_hp[t,h]) #
    
    @constraint(M, EV_charger_balance[t in T, h in H], ch_El_ev[t,h]== q_El_mp_ev[t,h] + q_El_pv_ev[t,h] + q_El_bt_ev[t,h]) # 
    @constraint(M, EV_charger_forced[t in T, h in H], ch_El_ev[t,h]>= q_EV_fcharge[t,EV_Id[H_id][1]]*bin_ev )

    if model_scenario == "BAU"
        @constraint(M, BT_charger_balance[t in T, h in H], ch_El_bt[t,h]== q_El_mp_bt[t,h] + q_El_pv_bt[t,h] )
        @constraint(M, BT_discharger_balance[t in T, h in H], dch_El_bt[t,h]== q_El_bt_mp[t,h] + q_El_bt_c[t,h] + q_El_bt_ev[t,h] + q_El_bt_hp[t,h]) #
        @constraint(M, BT_fullcharger_balance[t in T, h in H], cap_bt_ch>= ch_El_bt[t,h] + dch_El_bt[t,h] )
    end

    if model_scenario == "New_Tax"
        @constraint(M, BT_charger_balance[t in T, h in H], ch_El_bt[t,h]== q_El_mp_bt[t,h] + q_El_pv_bt[t,h])
        @constraint(M, BT_discharger_balance[t in T, h in H], dch_El_bt[t,h]== q_El_bt_mp[t,h] + q_El_bt_c[t,h] + q_El_bt_ev[t,h] + q_El_bt_hp[t,h]) #
        @constraint(M, BT_fullcharger_balance[t in T, h in H], cap_bt_ch>= ch_El_bt[t,h] + dch_El_bt[t,h] )
        #@constraint(M, BTVS_charger_balance[h in H], sum(q_El_btvs_mp[t,h] for t in T)== sum(q_El_mp_btvs[t,h] for t in T) )
    end

### Technology specific constraints

    @constraint(M, HP_generation[t in T, h in H], q_He_hp_c[t,h] + q_He_hp_hst[t,h] == (q_El_mp_hp[t,h] + q_El_pv_hp[t,h] + q_El_bt_hp[t,h])  * mu_HP[t])
    @constraint(M, HP_generation_limit[t in T, h in H], cap_hp[h] >= (q_El_mp_hp[t,h] + q_El_pv_hp[t,h] + q_El_bt_hp[t,h]) )

    optimize!(M)
    Results_Dict=create_var_dict(M)
    for k in keys(Results_Dict)

    #for k in [:c_El,:c_El_pv,:c_El_im,:c_El_gt,:c_El_tx,:r_El,:r_Tx,:c_Obj]
        CSV.write("results/"*string(H_id[1])*"_"*string(k)*".csv",Results_Dict[k])
    end
    #println(H_id)
    #println(objective_value(M))
    return()
end





