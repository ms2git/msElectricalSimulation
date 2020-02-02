classdef externalVoltageDrop < msElectricSimulation.modelling.lineElement
    
    
    properties (SetAccess=private)
        
        
        inputId='unknown'
        
        
    end
    
    
    methods
        
        
        function obj=externalVoltageDrop(id_, v)
            obj=obj@msElectricSimulation.modelling.lineElement(id_);
            if nargin>1
                obj.setInputId(v);
            end
        end
        
        
        function dispLine(obj, nIndent)
            obj.dispLine@msElectricSimulation.modelling.lineElement(nIndent);
            fprintf('%s V\n', obj.inputId);
        end
        
        
        function setInputId(obj, id_)
            obj.inputId=id_;
        end
        
        
    end
    
    
    methods % code generation
        
        
        function ret=getCCodeId(obj)
            ret='';
        end
        
        
        function ret=getCCodeVec(obj)
            ret={['Ext_' obj.inputId]};
        end
        
        
        function [mat, vec]=getCCodeMatrixVector(obj)
            N=numel(obj.parentLine(1).jacobian);
            vec=obj.getCCodeVec;
            J=sparse(N, numel(vec));
            for idx=1:numel(obj.parentLine)
                J=J+obj.parentLine(idx).jacobian';
            end
            mat=repmat({''}, N, numel(vec));
            for idxV=find(J)'
                mat{idxV}=sprintf('%s', ...
                    obj.value2Cstr(full(J(idxV))));
            end
        end
        
        
    end
    
    
end