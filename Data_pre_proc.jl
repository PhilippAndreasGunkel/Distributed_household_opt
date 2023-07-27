using CSV, DataFrames
using JuMP, Ipopt, GLPK#Gurobi, CPLEX
#import XLSX


## Define functions for loading data
# 1. Global: Define Function(LoadStandardData())
# 2. Global: Define Function(LoadSpecificData(H_Id))



### XXXXXXX make a check for every import on datatype
# a)

### Checking if variable type is correct
### https://stackoverflow.com/questions/57863153/julia-how-to-obtain-the-types-of-every-column-of-a-dataframe-table
# mapcols(eltype,Sets)
# Dict(names(El_price) .=> eltype.(eachcol(El_price)))

# b)
### Reading data into the correct type
### https://discourse.julialang.org/t/csv-error-reading-numbers-as-string/51341/10
# DataFrame(CSV.File("data/SolarCF.csv"; types = Dict(:SolarCF=> Float32)))

# c)
### Give proper naming, q_el_res, q_h_res, q_el_ev etc....



global function func_load_master_data()

    ###################### Sets           ######################
    global T_tot = Vector(CSV.read("data/Hours.csv", DataFrame)[T_slices,1]) 
    global T = Vector(range(1,size(T_tot)[1],step=1))     
    global Y = Vector(CSV.read("data/Years.csv", DataFrame)[:,1]) 
    global S = Vector(CSV.read("data/Scenario.csv", DataFrame)[:,1]) 
    


    global p_El = Vector(CSV.read("data/Electricity_prices_high.csv", DataFrame)[T_slices,1])  

    global nT_PV = Vector(CSV.read("data/SolarCF.csv", DataFrame)[T_slices,1])  
    
    global mu_HP = Vector(CSV.read("data/HP_CoP.csv", DataFrame)[T_slices,1])  


    ###################### Heat profiles  ######################
    #global A1 = Vector(CSV.read("data/consumption_data/heat/A1.csv", DataFrame)[:,1])
    #global A2 = Vector(CSV.read("data/consumption_data/heat/A2.csv", DataFrame)[:,1])
    #global A3 = Vector(CSV.read("data/consumption_data/heat/A3.csv", DataFrame)[:,1])



    println("Load master data")
    return T,Y,S,p_El,nT_PV,mu_HP
end


global function func_load_specific_data(h_ids)
    #println(h_ids)
    
    
    house_identifier = CSV.read("data/Household_identifier.csv", select=h_ids,DataFrame)
    house_ident_filter = CSV.read("data/Household_identifier_sub_test.csv",DataFrame)


 ############## EL   
    EL_id = house_identifier[3,:]
    SO_id = Vector(house_identifier[1,:])
    #### Bad code, func eachcol doesnt work, need to find solution
    q_El = Dict(file => CSV.read("data/consumption_data/electricity/"*file*".csv", select=Vector(EL_id[names(house_identifier)[findall(in(house_ident_filter[in.(house_ident_filter.Category, Ref([file])), :][:,"H_ID"]),names(house_identifier))]]),DataFrame)[T_slices,:] for file in SO_id)



############## EV    
    EV_Id = Vector(house_identifier[2,:])

    q_EV_fcharge = CSV.read("data/consumption_data/electric_vehicle/EV_FCharge.csv", select=EV_Id,DataFrame)[T_slices,:]
    bin_EV_avail = CSV.read("data/consumption_data/electric_vehicle/EV_availability.csv", select=EV_Id,DataFrame)[T_slices,:]
    SOC_EV_trip = CSV.read("data/consumption_data/electric_vehicle/EV_minSOC.csv", select=EV_Id,DataFrame)[T_slices,:]

############## HEAT
    HE_Id = Vector(house_identifier[9,:])
    q_He = CSV.read("data/consumption_data/heat/heat_consumption.csv", select=HE_Id, DataFrame)[T_slices,:]
    
    q_Hee = Dict(h => q_He[:,h] for h in names(q_He))

    HE_Are = Dict(har => parse(Float64,house_identifier[8,har]) for har in names(house_identifier))
    Cap_HP = Dict(har => parse(Float64,house_identifier[10,har]) for har in names(house_identifier))
    Cap_HST = Dict(har => parse(Float64,house_identifier[11,har]) for har in names(house_identifier))
    Cap_PV = Dict(har => parse(Float64,house_identifier[12,har]) for har in names(house_identifier))
    Cap_BT = Dict(har => parse(Float64,house_identifier[13,har]) for har in names(house_identifier))

    #CSV.read(inputfile, delim=" ", header=1, type=String, select=[:a,:b])
    return house_identifier,q_Hee,HE_Are,q_El,q_EV_fcharge,bin_EV_avail,SOC_EV_trip,Cap_HP,Cap_HST,Cap_PV,Cap_BT
end



global function create_var_dict(MM)
    str(x) = string(x) # Getting string function
    spl(x) = split(x, ",") # Spliting with comma function
    var_str = str.(all_variables(MM)) #Getting the string of all variables in a model
    sets_str = (s -> SubString(s, nextind(s, findfirst(":[", s)[1]+1), prevind(s, findlast(']', s)))).(var_str) # Obtaining the sets string
    var_name_str = (s -> SubString(s, 1, prevind(s, findfirst('[', s)))).(var_str) # Obtaining the name of variables
    uniq_var_names = unique(var_name_str) # Obtaining unique names of variables
    Variable_dict = Dict{Symbol,DataFrame}()
    for un in uniq_var_names # Looping over variables
        Bool = var_name_str .== un # Boolean value to filter total vectors
        Names = unique([split(el, ",") for el in (s -> SubString(s, nextind(s, findfirst('[', s)), prevind(s, findfirst(']', s)))).(var_str[Bool])])[1] # Getting the names of the sets for particular variable
        Sets_str_spl = [split(el, ",") for el in sets_str[Bool]] # Split sets of filtered vector with comma
        df = DataFrame([Any for i in 1:length(Names)],[Symbol(s) for s in Names], sum(Bool)) # Create empty dataframe
        df[:,:] = permutedims(reshape(vcat(Sets_str_spl...), length(Names), sum(Bool))) # Pass sets values
        df[!,:Value] = value.(all_variables(MM))[Bool] # Pass values
        Variable_dict[Symbol(un)] = df # Pass dataframe to dictionary
    end
    return Variable_dict
end







