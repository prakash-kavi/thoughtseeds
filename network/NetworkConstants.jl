module NetworkConstants

# Neuronal Grid Constants
const GRID_X_SIZE = 4
const GRID_Y_SIZE = 4
const ENERGY_INTERACTION_RADIUS = 0.25 * min(GRID_X_SIZE, GRID_Y_SIZE)  
const MAX_ENERGY_GAIN = 0.2
const DECAY_RATE = 0.01
NEURONAL_GRID_ENERGY_CRITICAL_THRESHOLD = 0.2


# Umwelt Constants
const OPTIMAL_TEMP = 1.0 
const TEMP_BASELINE = 1.0
const TEMP_FLUCTUATION_AMP = 0.2 
const TEMP_FLUCTUATION_FREQ = 0.1
const MEAN_REVERSION_RATE = 0.1
const NOISE_STD = 0.05 
const ENERGY_REPLENISHMENT_RATE = 0.5 # Average rate of Poisson process
const STEEP_CHANGE_FACTOR = 2.0  

end