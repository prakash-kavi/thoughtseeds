module Umwelt

using Random # For noise generation
using Distributions # Potentially useful
using .NeuronConstants 

# Define an Umwelt struct
mutable struct UmweltSate
    temperature::Float64
    energy_location::Tuple{Float64, Float64}  # (x, y) or similar coordinate system
    energy_amount::Float64 
    time::Float64
end

# Initialize the environment
function init_umwelt()
    umwelt = UmweltSate(TEMP_BASELINE, (0.0, 0.0), 0.0, 0.0)  # Initial state 
    return umwelt
end

# Update temperature (one time step)
function update_temperature!(umwelt::UmweltSate, mode::String="normal")
    # Temperature Fluctuation
    fluctuation = TEMP_FLUCTUATION_AMP * sin(2pi * TEMP_FLUCTUATION_FREQ * umwelt.time)

    # Mean Reversion:
    mean_reversion = MEAN_REVERSION_RATE * (OPTIMAL_TEMP - umwelt.temperature)

    # Noise
    noise = rand(Normal(0, NOISE_STD))

    # Update
    dT = fluctuation + mean_reversion + noise 

    # Mode Adjustment
    if mode == "steep"
        dT *= STEEP_CHANGE_FACTOR
    end

    umwelt.temperature = OPTIMAL_TEMP + dT  
    umwelt.time += 1.0 
end

# Generate energy replenishment (Poisson Process)
function generate_energy!(umwelt::UmweltSate, grid_size) 
    lambda = ENERGY_REPLENISHMENT_RATE 
    num_events = rand(Poisson(lambda))

    if num_events > 0  # Only regenerate if needed
        umwelt.energy_location = (rand(grid_size[1]), rand(grid_size[2]))
        umwelt.energy_amount = rand(0.1:0.3) # Adjust energy range as needed
    end
end

# Energy-related functions
function update_energy!(neuron, energy_consumption_rate::Float64=0.01) 
    base_consumption = energy_consumption_rate  # Base rate of energy consumption
    activity_factor = calculate_activity_factor(neuron)  # You'll need to implement this
    decay_amount = base_consumption * (1.0 + activity_factor)
    neuron.energy -= decay_amount
    neuron.energy = max(0.0, neuron.energy)  # Ensure non-negative energy
end

function add_energy!(neuron::Neuron, energy_gain::Float64)
    neuron.energy += energy_gain 
end

# Helper for calculating activity factor
function calculate_activity_factor(neuron)
    # Example using recent firing rate:
    spike_window = 0.5  # Time window in seconds  
    recent_spikes = neuron.spike_times[(neuron.spike_times .> now() - spike_window) .& (neuron.spike_times .< now())]
    firing_rate = length(recent_spikes) / spike_window
    activity_factor = firing_rate / 10.0  # Adjust scaling as needed (10.0 is an example)
    return activity_factor
end


end # end of module
