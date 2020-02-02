classdef compound < msElectricSimulation.modelling.modelingElement
    
    
    methods
        
        
        function obj=compound(system_, id_)
            obj=obj@msElectricSimulation.modelling.modelingElement(system_, id_);
        end
        
        
        ret=getZeroConstraint(obj, hLines)
        
        
    end
    
    
end