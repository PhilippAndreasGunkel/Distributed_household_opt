using Base: Float16

# #####

# # 1. Global Load Function LoadStandardData()
# # 2. Global Load Function OptModel(Func(LoadSpecificData(H_Id)),Initialize model vars, constraints))
# # 3. Global Execute Function LoadStandardData()
# # 4. Execute pmap(OptModel(H_Id),ListH_Id)
# # 5. Summarize results and export





using CSV, DataFrames
using JuMP, Ipopt, GLPK, Gurobi#Gurobi, CPLEX
using Distributed
#import XLSX
#using BenchmarkTools ### Use for benchmarking functions


if nprocs()== 1
    addprocs(19); # add worker processes
end



@everywhere include("Data_pre_proc.jl")
# # 2. Global Load Function OptModel(Func(LoadSpecificData(H_Id)),Initialize model vars, constraints))
@everywhere include("Optimization.jl")


###Dumb here worker related vars
#h_id = "From Master: Local Household ID"

#list_h_id = ["ID_1","ID_2","ID_3","ID_4","ID_5"]
h_group_1 = ["H_ID_772149"]
h_group_2 = ["H_ID_77215"]
h_group_3 = ["H_ID_772151"]
#h_group_4 = ["H_ID_772147","H_ID_772146"]
#h_group_5 = ["H_ID_772146","H_ID_772145"]
#h_group_6 = ["H_ID_772145","H_ID_772150"]


#list_h_id = [h_group_1,h_group_2,h_group_3]

list_h_id = CSV.read("data/test_household_idents.csv", DataFrame)
# Choose Scenario 
#@everywhere model_scenario = "BAU"
@everywhere model_scenario = "New_Tax"
@everywhere T_slices = Vector(CSV.read("data/T_slice.csv",DataFrame)[:,1]) 


# # 3. Global Execute Function LoadStandardData()
@everywhere func_load_master_data()








batch_size = 19

job_batch_start = Vector(range(1,length(Vector(list_h_id[:,1])),step=batch_size))

job_batch_end =Vector(range(batch_size,length(Vector(list_h_id[:,1])),step=batch_size))




Job_batch = [Vector(range(job_batch_start[Int(n)],job_batch_end[Int(n)],step=1)) for n in 1:(length(Vector(list_h_id[:,1]))/batch_size)]



# # 4. Execute pmap(OptModel(H_Id),ListH_Id)

for jb in Job_batch
	Results = Dict()
	list_jobs = [@spawn Model_opt([h_id]) for h_id in Vector(list_h_id[jb,1])]
	res_pmap = pmap(fetch, list_jobs)
end

