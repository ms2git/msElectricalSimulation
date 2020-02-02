classdef resistance < msElectricSimulation.modelling.lineElement
    
    
    properties (SetAccess=private)
        
        
        value=0
        
        
    end
    
    
    methods
        
        
        function obj=resistance(id_, v)
            obj=obj@msElectricSimulation.modelling.lineElement(id_);
            if nargin>1
                obj.setValue(v);
            end
        end
        
        
        function dispLine(obj, nIndent)
            obj.dispLine@msElectricSimulation.modelling.lineElement(nIndent);
            fprintf('%s %s\n', num2str(obj.value), char(937));
        end
        
        
        function setValue(obj, v)
            obj.value=v;
        end
        
        
    end
    
    
    methods % code generation
        
        
        function ret=getCCodeId(obj)
            ret=['Res_' obj.id];
        end
        
        
        function ret=getCCodeVec(obj)
            N=numel(obj.parentLine(1).jacobian);
            ret=arrayfun(@(x) sprintf('%s%i', obj.stateId, x), 1:N, 'UniformOutput', false);
        end       
        
        
        function [mat, vec]=getCCodeMatrixVector(obj)
            N=numel(obj.parentLine(1).jacobian);
            vec=obj.getCCodeVec;
            JTJ=sparse(N, N);
            for idx=1:numel(obj.parentLine)
                J=obj.parentLine(idx).jacobian;
                JTJ=JTJ+J'*J;
            end
            mat=repmat({''}, N, numel(vec));
            for idxV=find(JTJ)'
                mat{idxV}=sprintf('(%s)*%s', ...
                    obj.value2Cstr(full(JTJ(idxV))), ...
                    obj.getCCodeId);
            end
        end
        
        
    end
    
    
end