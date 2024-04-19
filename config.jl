# config.jl
const PARAM_SETS = [
    Dict("id" => 1, 
         "activation_scale" => 0.8,        
         "temperature" => 1.0,              
         "food_replenish_chance" => 0.2,    
         "food_amount" => 0.1,              
         "energy_decay_rate" => 0.05       
    ),
    Dict("id" => 2,  
         "activation_scale" => 1.5, 
         "temperature" => 0.75, 
         "food_replenish_chance" => 0.35, 
         "food_amount" => 0.12, 
         "energy_decay_rate" => 0.08 
    )
    # Add more parameter sets as needed
]