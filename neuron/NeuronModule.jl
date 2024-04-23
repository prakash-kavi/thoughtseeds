module NeuronModule

import .SynapseModule  
using .Surprisal
import .NeuronConstants: V_REST, V_THRESHOLD, V_RESET, ENERGY_THRESHOLD, SURPRISAL_SCALING_FACTOR, MAX_SURPRISAL_INPUT, NOISE_STD

using Distributions
using Random
using Plots

# Define the Neuron struct
mutable struct Neuron 
    membrane_potential :: Float64  
    energy :: Float64 
    spike_times :: Vector{Float64} 
    baseline_rate::Float64 
    baseline_isi_dist::DiscreteNonParametric
    surprisal_buffer :: Float64 
    synapses::Vector{Int}  # Store synapse IDs
    last_spike_time::Float64
    energy_critical_threshold :: Float64  # New field

    # Constructor
    function Neuron(membrane_potential::Float64 = V_REST, energy::Float64 = 1.0)
        baseline_rate = 10.0  # Example baseline - to be updated dynamically
        baseline_isi_dist = DiscreteNonParametric([0.1], [1.0])
        new(membrane_potential, energy, Float64[], baseline_rate, baseline_isi_dist, 0.0, Synapse[], 0.0)
    end
end

# Update membrane potential (LIF dynamics)
function update_membrane_potential!(neuron_dict::Dict, self_id::Int, dt::Float64, temperature::Float64, energy::Float64)
    self = neuron_dict[self_id]  

    # Surprisal-based inputs
    surprisal_rate = Surprisal.calculate_rate_surprisal(self, temperature, energy)
    surprisal_isi = Surprisal.calculate_isi_surprisal(self, temperature, energy)

    combined_surprisal = 0.5 * surprisal_rate + 0.5 * surprisal_isi
    I_surprisal(t) = Surprisal.map_surprisal_to_input(combined_surprisal) 

    # Energy-based input
    energy_threshold_effect = max(0.0, (self.ENERGY_THRESHOLD - energy) * 5.0) 
    effective_threshold = self.V_threshold + energy_threshold_effect 

    # Synaptic Input Calculation (Placeholder - Choose your preference)
    I_syn(t) = 0.0 
    for synapse in self.synapses
        source_neuron = neuron_dict[synapse.source_id]

        I_syn(t) += synapse.weight * source_neuron.membrane_potential 

        # Option 2: Synaptic Conductances (Example - Excitatory)
        # g_syn = synapse.weight 
        # E_rev = 0.0  # Excitatory reversal potential
        # I_syn(t) += g_syn * (self.membrane_potential - E_rev) 

        # Option 3: Alpha Function (Implement alpha_function separately)
        # I_syn(t) += alpha_function(dt - synapse.last_spike_time, synapse.weight)

    end

    # Calculate change in membrane potential
    dV = -LEAK * (self.membrane_potential - V_REST) * dt + I_syn(t) + I_surprisal(t) + rand(Normal(0, NOISE_STD)) * dt 

    # Update membrane potential
    self.membrane_potential += dV

    # Spike and Reset:
    if self.membrane_potential > effective_threshold
        self.membrane_potential = V_RESET
        self.last_spike_time = dt
        push!(self.spike_times, dt) 

        # Spike transmission to synapses
        for synapse in self.synapses
            push!(synapse.spike_queue, dt + synapse.delay)
        end
    end

    # Energy Consumption with Safeguard
    if self.last_spike_time == dt  # Spiking condition
        if self.energy > 0.04
            self.energy -= 0.04  
        end 
    else
        if self.energy > 0.01
            self.energy -= 0.01  # Baseline consumption rate
        end 
    end  
end


# Calculate firing rate within a bin
function calculate_firing_rate(spike_times, bin_size)
    num_spikes_in_bin = count(spike_times .> (now() - bin_size))
    firing_rate_in_bin = num_spikes_in_bin / bin_size
    return firing_rate_in_bin
end

function get_baseline_rate(self, temp::Float64, energy::Float64)
    baseline_dist = self.baseline_rates.get((temp, energy), Uniform(0, 50))  # Default: broad uniform
    baseline_rate = median(baseline_dist) 
    return baseline_rate
end

function get_baseline_isi_dist(self, temp::Float64, energy::Float64)
    baseline_dist = self.baseline_isi_dists[(temp, energy)]  
    return baseline_dist 
end
        
# Function to update ISI baselines
function update_isi_baselines!(baseline_isi_dists, observed_isis, temp, energy)
    # Get or create baseline distribution for this (temp, energy) combination
    baseline_dist = baseline_isi_dists.get((temp, energy), DiscreteNonParametric([0.0], [1.0]))  # Initial uniform distribution

    # Calculate new ISI distribution for this bin
    bin_edges = 0.0:0.01:0.05  # Example bin edges
    observed_hist = histogram(observed_isis, bin_edges = bin_edges, closed = :left)
    observed_dist = observed_hist / sum(observed_hist)

    # Update baseline with weighted average (play with alpha for weighting)
    alpha = 0.1  # Weighting factor for new data
    baseline_dist = weightedsum( (1-alpha)*baseline_dist, alpha*observed_dist)

    # Update dictionary with the new baseline
    baseline_isi_dists[(temp, energy)] = baseline_dist
end

function now()
    return time()  # From the base Julia library
end

end  # End of NeuronModule