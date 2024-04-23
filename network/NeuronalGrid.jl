module NeuronalGrid

using LinearAlgebra 
using .Neuron 
using .Umwelt
using .NetworkConstants 

# Structs
struct GridNeuron <: Neuron 
    location::Tuple{Float64, Float64}  
    neighbors::Vector{Int}  
end

struct NeuralGrid  
   neurons::Vector{GridNeuron}  
   connectivity_matrix::Matrix{Float64} 
   umwelt::Umwelt  
end

# Initialization Helper
function init_locations() 
    cx = range(-(GRID_X_SIZE - 1), (GRID_X_SIZE - 1), length=GRID_X_SIZE) * 2.0
    cy = range(-(GRID_Y_SIZE - 1), (GRID_Y_SIZE - 1), length=GRID_Y_SIZE) * 2.0

    # Equivalent to NumPy's meshgrid (note Julia's column-major ordering)
    all_x, all_y = broadcast.(cx, cy') 

    # Reshape and transpose
    loc = reshape([all_x[:], all_y[:]], (GRID_X_SIZE * GRID_Y_SIZE, 2))'

    # Adjust x-coordinates for alternating rows
    for i in 1:2:GRID_X_SIZE
        row_start = (i - 1) * GRID_Y_SIZE + 1
        row_end = i * GRID_Y_SIZE
        loc[row_start:row_end, 1] .+= 2.0  # Broadcast addition
    end

    return loc
end

# Initialization
function init_neural_grid(umwelt::Umwelt)  
    locations = init_locations() 
    neurons = GridNeuron[]
    for (i, loc) in enumerate(locations)
        neuron = GridNeuron(loc, []) # Initialize with location, empty neighbors

        # Initialize baselines with broad uniform distributions
        neuron.baseline_rates = Dict{Float64, Float64}()
        neuron.baseline_isi_dists = Dict{Float64, Float64}()

        for temp in range(OPTIMAL_BODY_TEMP - TEMP_DEVIATION_THRESHOLD, 
                          OPTIMAL_BODY_TEMP + TEMP_DEVIATION_THRESHOLD, 
                          step=0.1) 
            for energy in range(ENERGY_THRESHOLD, 1.0, step=0.1) 
                neuron.baseline_rates[(temp, energy)] = Uniform(0, 50) 
                neuron.baseline_isi_dists[(temp, energy)] = Uniform(0.02, 1.0) 
            end 
        end 

        push!(neurons, neuron)
    end

    connectivity_matrix = establish_nearest_neighbor_connectivity(GRID_X_SIZE, GRID_Y_SIZE)
    grid = NeuralGrid(neurons, connectivity_matrix, umwelt) 
    return grid
end

# Helper to establish nearest neighbor connections
function establish_nearest_neighbor_connectivity(grid_x, grid_y)
    connectivity_matrix = zeros(grid_x * grid_y, grid_x * grid_y)

    for i in 1:(grid_x * grid_y)
        current_x, current_y = ind2sub((grid_y, grid_x), i) # Convert linear index to coordinates

        # Neighbors (consider periodic boundaries using mod)
        neighbors = [
            sub2ind((grid_y, grid_x), (current_y - 1) % grid_y + 1, current_x),  # Up
            sub2ind((grid_y, grid_x), (current_y + 1) % grid_y + 1, current_x),  # Down
            sub2ind((grid_y, grid_x), current_y, (current_x - 1) % grid_x + 1),  # Left
            sub2ind((grid_y, grid_x), current_y, (current_x + 1) % grid_x + 1),  # Right 
        ]

        connectivity_matrix[i, neighbors] .= 1.0  # Set connections (adjust weights as needed)
    end

    return connectivity_matrix
end

function calculate_energy_gain(distance_to_source)
    if distance_to_source == 0  # Avoid division by zero if directly on the source
        return MAX_ENERGY_GAIN  # Constant defined in NeuronalGrid
    else
        return MAX_ENERGY_GAIN / (distance_to_source ^ 2) 
    end
end

# Update Functions (Placeholders)
function update_grid!(grid::NeuralGrid, dt::Float64)
    # Environmental Influence 

    # Energy Interaction
    energy_x, energy_y = grid.umwelt.energy_location
    # Energy Interaction with Asynchronous Consumption
    for neuron in grid.neurons
        consumption_probability = calc_consumption_probability(neuron.energy)  # You'll need to implement
        if rand() < consumption_probability  # Simulate Poisson-like consumption 'attempt'
            distance_to_source = norm(neuron.location - grid.umwelt.energy_location)
            if distance_to_source <= ENERGY_INTERACTION_RADIUS
                energy_gain = calculate_energy_gain(distance_to_source) 
                Umwelt.add_energy!(neuron, energy_gain)
            end
        end
        # Energy decay
        Umwelt.update_energy!(neuron) 
    end
    # Neuron State Updates + Synaptic Input
    for neuron in grid.neurons
        synaptic_input = 0.0
        for neighbor_index in neuron.neighbors
            neighbor = grid.neurons[neighbor_index]
            weight = grid.connectivity_matrix[getindex(neuron, neighbor_index)]  
            firing_rate = calculate_firing_rate(neighbor.spike_times, BIN_SIZE)
            synaptic_input += weight * firing_rate
        end

        # Surprisal-based Input Mapping
        temp_surprisal = calculate_rate_surprisal(neuron, grid.umwelt.temperature, neuron.energy) 
        energy_surprisal = ...  # Similar calculation - you'll need to implement this

        # Weighted combination 
        combined_surprisal = 0.5 * temp_surprisal + 0.5 * energy_surprisal

        I_temp = map_surprisal_to_input(combined_surprisal) 
        I_energy = map_surprisal_to_input(combined_surprisal) # Assuming energy surprisal also uses the same mapping

        update_membrane_potential!(neuron, dt, grid.umwelt.temperature, neuron.energy, synaptic_input, I_temp, I_energy) 

        # Spike and Reset + STDP Update
        if neuron.membrane_potential > neuron.V_threshold
             # ... (your spike and reset logic) 
        
            for synapse in neuron.synapses
                update_synapse_stdp!(synapse, dt)
            end
        end
    end

    # Potential Connectivity Updates (if applicable) 
    # ... 
end


# ... Add functions for analysis, visualization, accessing grid data, etc. ...

end # end of module
