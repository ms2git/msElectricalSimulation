classdef node < msElectricSimulation.modelling.modelingElement
    
    
    properties
        
        
        inflowLines=msElectricSimulation.modelling.line.empty(1,0)
        outflowLines=msElectricSimulation.modelling.line.empty(1,0)
        
        
    end
    
    
    properties
        
        
        position=[NaN NaN]
        
        
    end
    
    
    methods
        
        
        function obj=node(system_, id_, position_)
            obj=obj@msElectricSimulation.modelling.modelingElement(system_, id_);
            if nargin>2
                obj.setPosition(position_)
            end
        end
        
        
        function varargout=addOutflowLine(obj, l_)
            tmp=obj.addLine(l_, 'outflowLines');
            if nargout>0
                varargout{1}=tmp;
            end
        end
        
        
        function varargout=addInflowLine(obj, l_)
            tmp=obj.addLine(l_, 'inflowLines');
            if nargout>0
                varargout{1}=tmp;
            end
        end
        
        
        function setPosition(obj, v_)
            if numel(v_)==1
                v_=[real(v_) imag(v_)];
            end
            obj.position=v_;
        end
        
        
    end
    
    
    methods (Access = private)
        
        
        function ret=addLine(obj, ele_, containerId)
            if any(arrayfun(@(x) strcmp(x.id, ele_.id), [obj.outflowLines obj.inflowLines]))
                warning('%s "%s" already exist! Skip it.', containerId, ele_.id);
                return
            end
            obj.(containerId)(end+1)=ele_;
            ret=ele_;
        end
        
        
    end
    
    
end