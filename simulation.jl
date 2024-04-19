using CSV
using DataFrames
using Plots

include("neuron.jl")
include("config.jl")

const MAX_STEPS = 100
const NUM_NEURONS = 4 
const FOOD_AMOUNT = 0.1  
const REPLENISH_CHANCE = 0.2  

function distribute_energy(neurons, food_amount)
    energy_increase = food_amount / length(neurons)  
    for neuron in neurons
        add_energy!(neuron, energy_increase)
    end
end

function run_simulation(params) 
    println("Running simulation with parameter set id = $(params["id"])")
    neurons = [initialize_neuron() for _ in 1:NUM_NEURONS]
    output_data = [] 

    for step in 1:MAX_STEPS
        println("Time step: $step")
        for (i, neuron) in enumerate(neurons)
            # Parameter Usage Example 1: Activation Scaling 
            activation_input = rand(Normal(), 3) * params["activation_scale"]
            update_activation!(neuron, activation_input)  
            println("Neuron $i activation: $(neuron.activation)")

            # Parameter Usage Example 2: Temperature Variation 
            temperature = params["temperature"]  
            update_identity_belief!(neuron, temperature)

            energy_decay_rate =params["energy_decay_rate"]
            update_energy!(neuron, energy_decay_rate)
            println("Neuron $i energy: $(neuron.energy)")

        end

        # Parameter Usage Example 3: Conditional Food Distribution
        if rand() < params["food_replenish_chance"]
            distribute_energy(neurons, params["food_amount"])
            println("Food distributed")

        end

        # Collect output data
        push!(output_data, Dict(
            "time_step" => step,
            "neuron_1_activation" => neurons[1].activation,
            # ... Other data fields
            "param_set_id" => params["id"] 
        )) 
    end

    return output_data
end

function main()

    for params in PARAM_SETS
        println("Starting simulation with parameter set id = $(params["id"])")
        simulation_data = run_simulation(params)  

        # Convert list of dictionaries to DataFrame
        df = DataFrame(simulation_data)

        # Write DataFrame to CSV file
        CSV.write("simulation_output_$(params["id"]).csv", DataFrame(simulation_data))

        println("Finished simulation with parameter set id = $(params["id"])")
    end
    
end

main()