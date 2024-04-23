include("E:\\phd-proj\\nph\\julia\\neuron\\NeuronTypes.jl")
include("Surprisal.jl")  
include("NeuronModule.jl")
include("SynapseModule.jl") 

using .NeuronModule
using .SynapseModule 
using .Surprisal: calculate_rate_surprisal, calculate_isi_surprisal  # Import Specific from Surprisal

# Create neurons
neuron1 = Neuron()
neuron2 = Neuron()

# Create a synapse with a delay
synapse = Synapse(neuron1, neuron2, 0.1, :excitatory, 0.05, 0.0)

# Add the synapse to the neurons
push!(neuron1.synapses, synapse)
push!(neuron2.synapses, synapse) 

dt = 0.001  # Simulation time step (make it small enough for your delay) 
total_time = 0.2  # Total simulation duration

# Store membrane potential of neuron2 for plotting
membrane_potential_record = zeros(Int(total_time / dt) + 1)

# Force neuron1 to spike at t = 0.02
neuron1.last_spike_time = 0.02

# Simulation loop
for t in 0:dt:total_time
    update_membrane_potential!(neuron1, dt, 0.5, 0.5)  # Sample temp and energy values
    update_membrane_potential!(neuron2, dt, 0.5, 0.5)
    membrane_potential_record[Int(t / dt) + 1] = neuron2.membrane_potential 
end

using Plots 

plot(0:dt:total_time, membrane_potential_record, label="Membrane Potential of Neuron2")
xlabel!("Time")
ylabel!("Membrane Potential")
title!("Synaptic Delay Example")