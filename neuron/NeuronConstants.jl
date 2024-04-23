module NeuronConstants

export LEAK, V_REST, V_THRESHOLD, V_RESET, NOISE_STD, SURPRISAL_SCALING_FACTOR

# LIF Parameters
const LEAK = 0.2
const V_REST = -65.0  
const V_THRESHOLD = -50.0 
const V_RESET = -68.0  
const NOISE_STD = 0.1  

const NEURON_ENERGY_CRITICAL_THRESHOLD = 0.2  # 20% of initial energy

end