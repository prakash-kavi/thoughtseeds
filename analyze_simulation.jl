using CSV
using DataFrames
using Plots

include("config.jl")

function main()

    p = plot()  # Create an empty plot

    for params in PARAM_SETS
        # Read data from CSV file
        df = CSV.read("simulation_output_$(params["id"]).csv", DataFrame)

        # Plot neuron activation over time
        plot!(p, df.time_step, df.neuron_1_activation, label="Parameter set $(params["id"]) Activation")

        # Plot belief change history for each neuron
        for i in 1:4  # Assuming there are 4 neurons
            history = df[!, "neuron_$(i)_belief_change"]  # Assuming this is the column name for the belief change history
            plot!(p, 1:length(history), history, label="Parameter set $(params["id"]) Neuron $i Belief Change")
        end
    end
    
    # Display the plot
    display(p)
end

main()