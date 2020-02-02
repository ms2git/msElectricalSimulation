classdef lineElement < msElectricSimulation.element
    
    
    properties (SetAccess=private)
        
        
        parentLine=msElectricSimulation.modelling.line.empty(1, 0)
        isIndependentSize=true
        dependency
        
        
    end
        
    
    methods
        
        
        function obj=lineElement(id_)
            obj=obj@msElectricSimulation.element(id_);
        end
        
        
        function dispLine(obj, nIndent)
            prefix='';
            if ~obj.isIndependentSize
                prefix='DEPENDENT ';
            end
            fprintf('%s%s%s: ', blanks(max([0 nIndent-numel(obj.id)])), prefix, obj.id);
        end
        
        
        function setAsDependent(obj, isDependent_, dependency_)
            if nargin<2
                isDependent_=false;
                dependency_=[];
            end
            if isDependent_
                assert(nargin==3);
            end
            obj.isIndependentSize=~isDependent_;
            obj.dependency=dependency_;
        end
        
        
        [mat, vec]=getCCodeMatrixVector(obj, usePrefix)
        
        
    end
    
    
    methods (Hidden)
        
        
        function addParentLine(obj, parentLine_)
            if isempty(obj.parentLine)
                parentLine_.system.addLineElement(obj);
            end
            obj.parentLine(end+1)=parentLine_;
        end
        
        
    end
    
    
    methods % code generation
        
        ret=getCCodeId(obj)
                
        function ret=getCCodeCalculation(obj)
            ret='';
            for idx=1:numel(obj.dependency)
                ret=[ret sprintf('+(%s)*%s', ...
                    obj.value2Cstr(obj.dependency{idx}{1}), ...
                    obj.dependency{idx}{2}.getCCodeId)];
            end
        end
        
        
    end
    
    
end