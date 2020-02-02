classdef crossInductivity < msElectricSimulation.modelling.lineElement
    
    
    properties (SetAccess=private)
        
        
        value=0
        
        
    end
    
    
    methods
        
        
        function obj=crossInductivity(id_, varargin)
            obj=obj@msElectricSimulation.modelling.lineElement(id_);
            for idx=1:numel(varargin)
                if isa(varargin{idx}, 'double')
                    obj.setValue(varargin{idx})
                elseif isa(varargin{idx}, 'msElectricSimulation.modelling.line')
                    varargin{idx}.addElement(obj)
                else
                    error('unknown type');
                end
            end
        end
        
        
        function dispLine(obj, nIndent)
            obj.dispLine@msElectricSimulation.modelling.lineElement(nIndent);
            fprintf('%s mH\n', num2str(1e3*obj.value));
        end
        
        
        function setValue(obj, v)
            obj.value=v;
        end
        
        
    end
    
    
    methods % code generation
        
        
        function ret=getCCodeId(obj)
            ret=['IndCross_' obj.id];
        end
        
        
        function ret=getCCodeVec(obj)
            N=numel(obj.parentLine(1).jacobian);
            ret=arrayfun(@(x) sprintf('%s%i', obj.stateDerId, x), 1:N, 'UniformOutput', false);
        end
        
        
        function [mat, vec]=getCCodeMatrixVector(obj)
            if isempty(obj.parentLine)
                mat=cell(0,0);
                vec=cell(0);
                return
            end
            
            N=numel(obj.parentLine(1).jacobian);
            vec=obj.getCCodeVec;
            JTJ=sparse(N, N);
            for idx1=1:numel(obj.parentLine)
                J1=obj.parentLine(idx1).jacobian;
                for idx2=1:numel(obj.parentLine)
                    if idx2~=idx1
                        J2=obj.parentLine(idx2).jacobian;
                        JTJ=JTJ+J1'*J2;
                    end
                end
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