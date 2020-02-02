classdef modelingElement < msElectricSimulation.element
    
    
    properties (SetAccess=private)
        
        
        system
        
        
    end
    
    
    methods
        
        
        function obj=modelingElement(system_, id_)
            obj=obj@msElectricSimulation.element(id_);
            obj.system=system_;
            obj.system.addElement(obj);
        end
                
        
    end
    
    
end