module SynapseModule

using DataStructures  

export transmission_effect

mutable struct Synapse
    source_id::Int
    target_id::Int
    weight::Float64
    type::Symbol 
    delay::Float64 
    stdp_eligibility::Float64 
    spike_queue::Deque{Float64}

    # Constructor
    function Synapse(source_id::Int, target_id::Int, weight::Float64, type::Symbol, delay::Float64, stdp_eligibility::Float64)
        new(source_id, target_id, weight, type, delay, stdp_eligibility, Deque{Float64}())
    end
end

function transmission_effect(synapse::Synapse)
    if synapse.type == :excitatory
        return synapse.weight 
    else 
        return -synapse.weight 
    end
end

function update_synapse_stdp!(synapse::Synapse, dt::Float64)  # Optional dt for future use
    time_diff = synapse.target.last_spike_time - synapse.source.last_spike_time

    if time_diff > 0  # Presynaptic spike before postsynaptic -> potentiation
        synapse.weight += 0.01 * exp(-time_diff / 20.0)  # Adjust constants as needed
    else              # Postsynaptic before presynaptic -> depression
        synapse.weight -= 0.01 * exp(time_diff / 20.0) 
    end

    # Limit weights (optional)
    synapse.weight = clamp(synapse.weight, 0.0, 1.0)  # Keep weights between 0 and 1

    synapse.stdp_eligibility *= 0.95 # Decay of eligibility trace
end

end