using LinearAlgebra
using Distributions 

# Constants 
const HUNGER_THRESHOLD = 0.7 
const NOISE_FACTOR = 0.05  
const DECAY_RATE = 0.1     
const η_FLOW = 0.2 
const OPTIMAL_BODY_TEMP = 1.0  
const HUNGER_INCREASE_RATE = 0.01  
const TEMP_DEVIATION_THRESHOLD = 0.2 
const ENERGY_THRESHOLD = 0.2  

mutable struct Neuron
    identity_belief :: Vector{Float64}
    energy_weight :: Float64
    activation :: Float64
    energy :: Float64   # Renamed attribute
    connections :: Vector{Neuron} 
    identity_belief_change_history :: Vector{Float64}  
    instability_score :: Float64   
    decay_timer :: Int  
end

function initialize_neuron(identity_belief::Vector{Float64}=rand(3), 
    energy_weight::Float64=1.0, 
    initial_activation::Float64=0.0, 
    initial_energy::Float64=0.5)  
    # Create the Neuron instance 
    new_neuron = Neuron(identity_belief, energy_weight, initial_activation, initial_energy, Neuron[], [], 0.0, 0)

    # Return the initialized neuron
    return new_neuron 
end

function update_activation!(neuron::Neuron, flow_vector::Vector{Float64}, noise_factor::Float64=NOISE_FACTOR, decay_rate::Float64=DECAY_RATE, synaptic_input::Float64=0.0, η_flow::Float64=η_FLOW)
    # Error Handling
    @assert length(flow_vector) == length(neuron.identity_belief) "flow_vector and identity_belief dimensions must match"
    @assert 0 <= DECAY_RATE <= 1 "decay_rate must be between 0 and 1"
    @assert 0 <= NOISE_FACTOR <= 1 "noise_factor must be between 0 and 1"

    # Decay
    neuron.activation *= (1 - DECAY_RATE)

    # Flow Vector Influence 
    alignment = dot(flow_vector, neuron.identity_belief)
    sigmoid_contribution = η_FLOW / (1 + exp(-2 * alignment))  
    neuron.activation += sigmoid_contribution

    # Synaptic Input
    neuron.activation += synaptic_input 

    # Hunger Calculation
    hunger_signal = clamp(1 - neuron.energy / (ENERGY_THRESHOLD + 1e-6), 0, 1) 

    # Incorporate hunger_signal into the update (adjust as needed)
    neuron.activation += hunger_signal * HUNGER_INCREASE_RATE     

    # Noise 
    noise = rand(Normal(0, NOISE_FACTOR))  
    neuron.activation += noise

    # Ensure activation stays within [0, 1]
    neuron.activation = clamp(neuron.activation, 0, 1) 
end

function update_identity_belief!(neuron::Neuron, temperature::Float64)
    temp_deviation = abs(temperature - OPTIMAL_BODY_TEMP) 

    belief_adjustment = temp_deviation * rand(Normal(), length(neuron.identity_belief))  # Ensure matching dimensions

    hunger_signal = clamp(1 - neuron.energy / (ENERGY_THRESHOLD + 1e-6), 0, 1) 
    belief_adjustment += hunger_signal * HUNGER_INCREASE_RATE * ones(length(belief_adjustment))  # Corrected line

    new_belief = neuron.identity_belief + belief_adjustment
    neuron.identity_belief = new_belief / sum(new_belief) 
end

function update_energy!(neuron::Neuron, energy_decay_rate::Float64, energy_consumption_rate::Float64=0.01) 
    expenditure = energy_consumption_rate * (1 + 3 * neuron.activation) 
    neuron.energy -= expenditure  
    neuron.energy -= neuron.energy * energy_decay_rate
    neuron.energy = max(0, neuron.energy) 
end

function add_energy!(neuron::Neuron, energy_gain::Float64)
    neuron.energy += energy_gain  # Update 'energy'
end