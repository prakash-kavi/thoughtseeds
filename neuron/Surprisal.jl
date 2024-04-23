module Surprisal

using Distributions

# Surprisal Parameters
const BIN_SIZE = 0.03  # 30 ms bin 
const SURPRISAL_SCALING_FACTOR = 0.2
const MAX_SURPRISAL_INPUT = 0.1

# Calculate rate-based surprisal
function calculate_rate_surprisal(neuron, temp, energy)
    firing_rate_in_bin = calculate_firing_rate(neuron.spike_times, BIN_SIZE)
    baseline_rate = get_specialized_baseline_rate(neuron, temp, energy)  
    surprisal_rate = (firing_rate_in_bin - baseline_rate) / baseline_rate
    return normalize_surprisal(surprisal_rate, temp, energy) 
end

# Calculate ISI-based surprisal using KL divergence 
function calculate_isi_surprisal(neuron, temp, energy)
    isis = diff(neuron.spike_times)  # Calculate Inter-spike intervals
    baseline_dist = get_specialized_baseline_isi_dist(neuron, temp, energy)  

    # Create histograms with appropriate binning
    bin_edges = 0.0:0.01:0.05 # Example bin edges
    observed_hist = histogram(isis, bin_edges = bin_edges, closed = :left)
    expected_hist = histogram(baseline_dist.edges[1:end-1], baseline_dist.weights, bin_edges = bin_edges, closed = :left)

    # Normalize histograms to represent probability distributions
    observed_dist = observed_hist / sum(observed_hist)
    expected_dist = expected_hist / sum(expected_hist)

    # Create DiscreteNonParametric distributions
    obs_dist = DiscreteNonParametric(observed_dist.edges[1:end-1], observed_dist.weights)
    exp_dist = DiscreteNonParametric(expected_dist.edges[1:end-1], expected_dist.weights)

    # Calculate KL Divergence
    kl_divergence = kldivergence(obs_dist, exp_dist)

    return kl_divergence 
end

# Normalize surprisal values logarithmically
function normalize_surprisal(surprisal, temp, energy)
    normalized_surprisal = log(1 + abs(surprisal)) 
    return normalized_surprisal
end

# Map surprisal to input, using dynamic weights
function map_surprisal_to_input(neuron, temp, energy)
    combined_surprisal = neuron.surprisal_rate_weight * calculate_rate_surprisal(neuron, temp, energy) + neuron.surprisal_isi_weight * calculate_isi_surprisal(neuron, temp, energy) 
    input_current = exp(SURPRISAL_SCALING_FACTOR * combined_surprisal * temp) - 1 
    input_current = min(input_current, MAX_SURPRISAL_INPUT) 
    return input_current
end

# Placeholder functions - To be developed in the network phase
function get_specialized_baseline_rate(neuron, temp, energy) 
    # Retrieve or calculate neuron's specialized baseline considering its preferences
end

function get_specialized_baseline_isi_dist(neuron, temp, energy)  
    # Retrieve or calculate neuron's specialized ISI distribution
end

end