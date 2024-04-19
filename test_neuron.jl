include("neuron.jl")  

function test_update_activation!()
    neuron = Neuron([0.2, 0.8])   
    flow_vector = [0.5, 0.5]   
    update_activation!(neuron, flow_vector)   
    println("Updated activation: ", neuron.activation) 
end

test_update_activation!() 