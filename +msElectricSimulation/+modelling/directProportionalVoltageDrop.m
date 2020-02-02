classdef directProportionalVoltageDrop < msElectricSimulation.modelling.lineElement
    
    
    properties (SetAccess=private)
        
        
        value=0
        inputId='unknown'
        
        
    end
    
    
    methods
        
        
        function obj=directProportionalVoltageDrop(id_, varargin)
            obj=obj@msElectricSimulation.modelling.lineElement(id_);
            for idx=1:numel(varargin)
                if isa(varargin{idx}, 'double')
                    obj.setValue(varargin{idx})
                elseif isa(varargin{idx}, 'char')
                    obj.setInputId(varargin{idx})
                else
                    error('unknown type');
                end
            end
        end
        
        
        function dispLine(obj, nIndent)
            obj.dispLine@msElectricSimulation.modelling.lineElement(nIndent);
            fprintf('%s V/%s\n', num2str(obj.value), obj.inputId);
        end
        
        
        function setValue(obj, v)
            obj.value=v;
        end
        
        
        function setInputId(obj, v)
            obj.inputId=v;
        end
        
        
    end
    
    
    methods % code generation
        
        
        function ret=getCCodeId(obj)
            ret=['Prop_' obj.id];
        end
        
        
        function ret=getCCodeVec(obj)
            ret={['PropFac_' obj.inputId]};
        end
        
        
        function [mat, vec]=getCCodeMatrixVector(obj)
            if isempty(obj.parentLine)
                mat=cell(0,0);
                vec=cell(0);
                return
            end
            
            N=numel(obj.parentLine(1).jacobian);
            vec=obj.getCCodeVec;
            J=sparse(N, numel(vec));
            for idx=1:numel(obj.parentLine)
                J=J+obj.parentLine(idx).jacobian';
            end
            mat=repmat({''}, N, numel(vec));
            for idxV=find(J)'
                mat{idxV}=sprintf('(%s)*%s', ...
                    obj.value2Cstr(full(J(idxV))), ...
                    obj.getCCodeId);
            end
        end
        
        
    end
    
    
end