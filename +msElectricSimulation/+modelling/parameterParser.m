classdef parameterParser < msElectricSimulation.element
    
    
    properties
        
        
        referenceElements
    
    
    end
        
    
    methods
        
        
        function obj=parameterParser(id_, refEle_)
            obj=obj@msElectricSimulation.element(id_);
            obj.referenceelement=refEle_;
        end
        
        
        [mat, vec]=getCCodeMatrixVector(obj, usePrefix)
        
        
    end
    
    
end