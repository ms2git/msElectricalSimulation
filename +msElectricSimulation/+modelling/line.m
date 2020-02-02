classdef line < msElectricSimulation.modelling.modelingElement
    
    
    properties (SetAccess=private) % modelling
        
        
        fromNode
        toNode
        
        resistance=msElectricSimulation.modelling.resistance.empty(1, 0)
        inductivity=msElectricSimulation.modelling.inductivity.empty(1, 0)
        crossInductivity=msElectricSimulation.modelling.crossInductivity.empty(1, 0)
        capacity=msElectricSimulation.modelling.capacity.empty(1, 0)
        directProportionalVoltageDrop=msElectricSimulation.modelling.directProportionalVoltageDrop.empty(1, 0)
        externalVoltageDrop=msElectricSimulation.modelling.externalVoltageDrop.empty(1, 0)
        
        
    end
    
    
    methods % modelling
        
        
        function obj=line(system_, id_, fromNode_, toNode_)
            obj=obj@msElectricSimulation.modelling.modelingElement(system_, id_);
            if nargin>2
                obj.setFromNode(fromNode_)
            end
            if nargin>3
                obj.setToNode(toNode_)
            end
        end
        
        
        %         function disp(obj)
        %             fnShow={'system', 'fromNode', 'toNode', 'resistance', 'inductivity', 'crossInductivity', 'capacity', 'directProportionalVoltageDrop', 'externalVoltageDrop', 'jacobian'};
        %             N=max(cellfun(@(x) numel(x), fnShow));
        %             fBlanks=@(x) blanks(4+N-numel(x));
        %             fprintf('%ssystem: %s\n', fBlanks('system'), obj.system.id);
        %             for fn={'fromNode', 'toNode'}
        %                 nodeId='-';
        %                 if ~isempty(obj.(fn{1}))
        %                     nodeId=obj.(fn{1}).id;
        %                 end
        %                 fprintf('%s%s: %s\n', fBlanks(fn{1}), fn{1}, nodeId);
        %             end
        %             for fn={'resistance', 'inductivity', 'crossInductivity', 'capacity', 'directProportionalVoltageDrop', 'externalVoltageDrop'}
        %                 fprintf('%s%s:', fBlanks(fn{1}), fn{1});
        %                 if isempty(obj.(fn{1}))
        %                     fprintf(' -\n');
        %                 else
        %                     fprintf('\n');
        %                     for idx=1:numel(obj.(fn{1}))
        %                         obj.(fn{1})(idx).dispLine(numel(fBlanks(''))+4);
        %                     end
        %                 end
        %             end
        %             fprintf('%sjacobian: %s\n', fBlanks('jacobian'), mat2str(full(obj.jacobian)));
        %         end
        
        
        function varargout=setFromNode(obj, fromNode_)
            obj.fromNode=fromNode_;
            obj.fromNode.addOutflowLine(obj)
            obj.checkSystem
            if nargout>0
                varargout{1}=fromNode_;
            end
        end
        
        
        function varargout=setToNode(obj, toNode_)
            obj.toNode=toNode_;
            obj.toNode.addInflowLine(obj)
            obj.checkSystem
            if nargout>0
                varargout{1}=toNode_;
            end
        end
        
        
        function varargout=addResistance(obj, varargin)
            e=obj.addElementWrapper('resistance', varargin{:});
            tmp=obj.addElement(e);
            if nargout>0
                varargout{1}=tmp;
            end
        end
        
        
        function varargout=addCapacity(obj, varargin)
            e=obj.addElementWrapper('capacity', varargin{:});
            tmp=obj.addElement(e);
            if nargout>0
                varargout{1}=tmp;
            end
        end
        
        
        function varargout=addInductivity(obj, varargin)
            e=obj.addElementWrapper('inductivity', varargin{:});
            tmp=obj.addElement(e);
            if nargout>0
                varargout{1}=tmp;
            end
        end
        
        
        function varargout=addCrossInductivity(obj, varargin)
            e=obj.addElementWrapper('crossInductivity', varargin{:});
            tmp=obj.addElement(e);
            if nargout>0
                varargout{1}=tmp;
            end
        end
        
        
        function varargout=addDirectProportionalVoltageDrop(obj, varargin)
            e=obj.addElementWrapper('directProportionalVoltageDrop', varargin{:});
            tmp=obj.addElement(e);
            if nargout>0
                varargout{1}=tmp;
            end
        end
        
        
        function varargout=addExternalVoltageDrop(obj, varargin)
            e=obj.addElementWrapper('externalVoltageDrop', varargin{:});
            tmp=obj.addElement(e);
            if nargout>0
                varargout{1}=tmp;
            end
        end
        
        
        function ret=addElement(obj, e)
            ret=[];
            for fn={'resistance', 'crossInductivity', 'inductivity', 'capacity', 'directProportionalVoltageDrop', 'externalVoltageDrop'}
                if isa(e, ['msElectricSimulation.modelling.' fn{1}])
                    assert(sum(obj.(fn{1})==e)==0);
                    obj.(fn{1})(end+1)=e;
                    e.addParentLine(obj);
                    ret=e;
                end
            end
            if isempty(ret)
                disp(e);
                error('unknown type of element');
            end
            if nargout==0
                clear('ret');
            end
        end
        
        
    end
    
    
    methods (Access=private) % modelling
        
        
        function checkSystem(obj)
            if isempty(obj.fromNode)
                return
            end
            if isempty(obj.toNode)
                return
            end
            if (obj.fromNode==obj.toNode)
                error('fromNode == toNode!');
            end
            obj.system.analyze(false)
        end
        
        
    end
    
    
    methods (Static, Access=private) % modelling
        
        
        function ret=addElementWrapper(varargin)
            typeStr=varargin{1};
            ret=[];
            if isa(varargin{2}, ['msElectricSimulation.modelling.' typeStr])
                ret=varargin{2};
            end
            if ~isempty(ret)
                assert(nargin==2);
                return
            end
            assert(ischar(varargin{2}));
            idStr=varargin{2};
            switch typeStr
                case {'resistance', 'capacity', 'inductivity'}
                    assert(nargin==3);
                    value=varargin{3};
                    assert(isscalar(value));
                    ret=msElectricSimulation.modelling.(typeStr)(idStr, value);
                case 'crossInductivity'
                    assert(nargin==4);
                    value=varargin{3};
                    assert(isscalar(value));
                    sourceLine=varargin{4};
                    assert(isa(sourceLine, 'msElectricSimulation.modelling.line'));
                    ret=msElectricSimulation.modelling.(typeStr)(idStr, value, sourceLine);
                case 'directProportionalVoltageDrop'
                    assert(nargin==4);
                    value=varargin{3};
                    assert(isscalar(value));
                    inputId=varargin{4};
                    assert(ischar(inputId));
                    ret=msElectricSimulation.modelling.(typeStr)(idStr, value, inputId);
                case 'externalVoltageDrop'
                    assert(nargin==3);
                    inputId=varargin{3};
                    assert(ischar(inputId));
                    ret=msElectricSimulation.modelling.(typeStr)(idStr, inputId);
                otherwise
                    error('unknonw type');
            end
        end
        
        
    end
    
    
    properties (SetAccess=private) % analysis
        
        
        jacobian
        
        
    end
    
    
    methods % analysis
        
        
        function setJacobian(obj, j)
            obj.jacobian=j;
        end
        
        
    end
    
    
    methods % code generation
        
        
        function ret=getCCodeId(obj, typeStr)
            assert(any(strcmp(typeStr, {'current', 'currentInt', 'currentDot'})));
            ret=[typeStr '_' obj.id];
        end
        
        
        function ret=getCCodeCurrentEvaluation(obj, typeStr)
            ret=cell(1);
            switch typeStr
                case 'currentInt'
                    stateId_=obj.stateIntId;
                case 'current'
                    stateId_=obj.stateId;
                case 'currentDot'
                    stateId_=obj.stateDerId;
                otherwise
                    error('unknown typeStr "%s"', typeStr);
            end
            ret{1}=sprintf('%s=', obj.getCCodeId(typeStr));
            for idxV=find(obj.jacobian)
                ret{1}=sprintf('%s+(%s)*(%s%i)', ret{1}, ...
                    obj.value2Cstr(full(obj.jacobian(idxV))), ...
                    stateId_, ...
                    idxV);
            end
            ret{1}=[ret{1} ';'];
        end
        
        
        function ccode=getCCodeVoltageDropCalculation(obj)
            ccode=cell(1, 0);
            
            if isempty(obj.resistance)
                ccode{end+1}=sprintf('voltageDrop_%s_resistance=0.;', obj.id);
            else
                ccode{end+1}=sprintf('voltageDrop_%s_resistance=(%s)*(%s);', ...
                    obj.id, ...
                    strjoin(arrayfun(@(x) x.getCCodeId, obj.resistance, 'UniformOutput', false), '+'), ...
                    obj.getCCodeId('current'));
            end
            if isempty(obj.capacity)
                ccode{end+1}=sprintf('voltageDrop_%s_capacity=0.;', obj.id);
            else
                ccode{end+1}=sprintf('voltageDrop_%s_capacity=(%s)*(%s);', ...
                    obj.id, ...
                    strjoin(arrayfun(@(x) ['+(1./' x.getCCodeId ')'], obj.capacity, 'UniformOutput', false), '+'), ...
                    obj.getCCodeId('currentInt'));
            end
            if isempty(obj.inductivity)
                ccode{end+1}=sprintf('voltageDrop_%s_inductivity=0.;', obj.id);
            else
                ccode{end+1}=sprintf('voltageDrop_%s_inductivity=+(%s)*(%s);', ...
                    obj.id, ...
                    strjoin(arrayfun(@(x) x.getCCodeId, obj.inductivity, 'UniformOutput', false), '+'), ...
                    obj.getCCodeId('currentDot'));
            end
            if isempty(obj.crossInductivity)
                ccode{end+1}=sprintf('voltageDrop_%s_crossInductivity=0.;', obj.id);
            else
                tmp='';
                for hCross=obj.crossInductivity
                    for hLine=hCross.parentLine
                        if hLine~=obj
                            tmp=[tmp '+(' hCross.getCCodeId ')*(' hLine.getCCodeId('currentDot') ')'];
                        end
                    end
                end
                ccode{end+1}=sprintf('voltageDrop_%s_crossInductivity=%s;', ...
                    obj.id, tmp);
            end
            if isempty(obj.externalVoltageDrop)
                ccode{end+1}=sprintf('voltageDrop_%s_externalVoltageDrop=0.;', obj.id);
            else
                ccode{end+1}=sprintf('voltageDrop_%s_externalVoltageDrop=%s;', ...
                    obj.id, ...
                    strjoin(arrayfun(@(x) x.getCCodeVec{1}, obj.externalVoltageDrop, 'UniformOutput', false), '+'));
            end
            if isempty(obj.directProportionalVoltageDrop)
                ccode{end+1}=sprintf('voltageDrop_%s_directProportionalVoltageDrop=0.;', obj.id);
            else
                ccode{end+1}=sprintf('voltageDrop_%s_directProportionalVoltageDrop=%s;', ...
                    obj.id, ...
                    strjoin(arrayfun(@(x) ['(' x.getCCodeId ')*(' x.getCCodeVec{1} ')'], obj.directProportionalVoltageDrop, 'UniformOutput', false), '+'));
            end
            tmp=cellfun(@(x) ['voltageDrop_' obj.id '_' x], {'resistance', 'capacity', 'inductivity', 'crossInductivity', 'externalVoltageDrop', 'directProportionalVoltageDrop'}, 'UniformOutput', false);
            ccode{end+1}=sprintf('voltageDrop_%s_total=%s;', obj.id, strjoin(tmp, '+'));
        end
        
        
    end
    
    
    %         function ret=getJacobian(obj)
    %             ret=obj.jacobian;
    %         end
    %
    %
    %         function [mat, vec]=getNumericMatrixVector(obj, typeStr)
    %             N=numel(obj.jacobian);
    %             switch typeStr
    %                 case 'resistance'
    %                     vec=arrayfun(@(x) sprintf('u_%i', x), 1:N, 'UniformOutput', false);
    %                     mat=zeros(N, numel(vec));
    %                     JTJ=full(obj.jacobian'*obj.jacobian);
    %                     for idx=1:numel(obj.(typeStr))
    %                         mat=mat+JTJ*obj.(typeStr)(idx).value;
    %                     end
    %                 case 'inductivity'
    %                     vec=arrayfun(@(x) sprintf('uDot_%i', x), 1:N, 'UniformOutput', false);
    %                     mat=zeros(N, numel(vec));
    %                     JTJ=full(obj.jacobian'*obj.jacobian);
    %                     for idx=1:numel(obj.(typeStr))
    %                         mat=mat+JTJ*obj.(typeStr)(idx).value;
    %                     end
    %                     for idx=1:numel(obj.crossInductivity)
    %                         JTJ=full(obj.crossInductivity(idx).sourceLine.getJacobian'*obj.jacobian);
    %                         mat=mat+JTJ*obj.crossInductivity(idx).value;
    %                     end
    %                 case 'capacity'
    %                     vec=arrayfun(@(x) sprintf('q_%i', x), 1:N, 'UniformOutput', false);
    %                     mat=zeros(N, numel(vec));
    %                     JTJ=full(obj.jacobian'*obj.jacobian);
    %                     for idx=1:numel(obj.(typeStr))
    %                         mat=mat+JTJ*(1/obj.(typeStr)(idx).value);
    %                     end
    %                 case 'directProportionalVoltageDrop'
    %                     vec=cell(1, numel(obj.(typeStr)));
    %                     mat=zeros(N, numel(vec));
    %                     for idx=1:numel(obj.(typeStr))
    %                         vec{idx}=obj.(typeStr)(idx).inputId;
    %                         mat(:, idx)=obj.jacobian'*obj.(typeStr)(idx).value;
    %                     end
    %                  case 'externalVoltageDrop'
    %                     vec=cell(1, numel(obj.(typeStr)));
    %                     mat=zeros(N, numel(vec));
    %                     for idx=1:numel(obj.(typeStr))
    %                         vec{idx}=obj.(typeStr)(idx).inputId;
    %                         mat(:, idx)=obj.jacobian';
    %                     end
    %                 otherwise
    %                     error('unknown case');
    %             end
    %             vec=vec';
    %         end
    %
    %
    %     end
    %
    %
    %     methods
    %
    %
    %         function ret=getCurrentCalculationStr(obj, indepStr)
    %             if nargin<2
    %                 indepStr='u';
    %             end
    %
    %             ret='0';
    %             for idx=1:numel(obj.jacobian)
    %                 if abs(obj.jacobian(idx))<sqrt(eps)
    %                     continue
    %                 end
    %                 ret=[ret '+((' obj.value2str(obj.jacobian(idx), false, true) ')*(' indepStr '_' num2str(idx) '))'];
    %             end
    %         end
    %
    %
    %         function ret=getVoltageLossCalculationStrC(obj, typeStr)
    %             switch typeStr
    %                 case 'inductivity'
    %                     prefix='currentDot_';
    %                 case 'resistance'
    %                     prefix='current_';
    %                 case 'capacity'
    %                     prefix='currentInt_';
    %                 case 'directProportionalVoltageDrop'
    %                     prefix='';
    %                 otherwise
    %                     error('unknown prefix');
    %             end
    %             if isempty(obj.(typeStr))
    %                 ret='0';
    %             else
    %                 ret='';
    %                 for idx=1:numel(obj.(typeStr))
    %                     switch typeStr
    %                         case 'capacity'
    %                             propStr=['(1./(*' obj.(typeStr){idx}.id '))'];
    %                         otherwise
    %                             propStr=['(*' obj.(typeStr){idx}.id ')'];
    %                     end
    %                     switch typeStr
    %                         case {'inductivity', 'resistance', 'capacity'}
    %                             srcStr=obj.(typeStr){idx}.sourceLine.id;
    %                         case 'directProportionalVoltageDrop'
    %                             srcStr=obj.(typeStr){idx}.proportionalId;
    %                     end
    %                     ret=[ret '+(' propStr '*(*' prefix srcStr '))'];
    %                 end
    %             end
    %         end
    %
    %
    %     end
    
    
end