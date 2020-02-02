classdef system < msElectricSimulation.element
    
    
    properties (SetAccess=private, Hidden) % for modelling
        
        
        node=msElectricSimulation.modelling.node.empty(1, 0)
        line=msElectricSimulation.modelling.line.empty(1, 0)
        compound=cell(1, 0)
        
        resistance=msElectricSimulation.modelling.resistance.empty(1, 0)
        inductivity=msElectricSimulation.modelling.inductivity.empty(1, 0)
        crossInductivity=msElectricSimulation.modelling.crossInductivity.empty(1, 0)
        capacity=msElectricSimulation.modelling.capacity.empty(1, 0)
        directProportionalVoltageDrop=msElectricSimulation.modelling.directProportionalVoltageDrop.empty(1, 0)
        externalVoltageDrop=msElectricSimulation.modelling.externalVoltageDrop.empty(1, 0)
        %inputParameter=msElectricSimulation.modelling.inputParameter.empty(1, 0)
        
        
    end
    
    
    methods % for modelling
        
        
        function obj=system(id_)
            obj=obj@msElectricSimulation.element(id_);
        end
        
        
        function varargout=addNode(obj, n_)
            if ischar(n_)
                n_=msElectricSimulation.modelling.node(obj, n_);
            end
            tmp=obj.addElement(n_);
            if nargout>0
                varargout{1}=tmp;
            end
        end
        
        
        function ret=getNode(obj, id_)
            ret=obj.getElement(id_, 'node');
        end
        
        
        function varargout=addLine(obj, varargin)
            if numel(varargin)==1
                line_=varargin{1};
            elseif numel(varargin)>1
                if numel(varargin)==2
                    fromNode=varargin{1};
                    toNode=varargin{2};
                    lineId='';
                elseif numel(varargin)==3
                    lineId=varargin{1};
                    fromNode=varargin{2};
                    toNode=varargin{3};
                else
                    error('unknown number of input arguments.');
                end
                if ischar(fromNode)
                    fromNode=obj.getNode(fromNode);
                end
                if ischar(toNode)
                    toNode=obj.getNode(toNode);
                end
                if isempty(lineId)
                    lineId=sprintf('%s_%s', fromNode.id, toNode.id);
                end
                assert(ischar(lineId));
                tmp=msElectricSimulation.modelling.line(obj, lineId, fromNode, toNode);
                if nargout>0
                    varargout{1}=tmp;
                end
                return
            end
            tmp=obj.addElement(line_);
            if nargout>0
                varargout{1}=tmp;
            end
        end
        
        
        function ret=getLine(obj, id_)
            ret=obj.getElement(id_, 'line');
        end
        
        
        function addCompound(obj, h)
            obj.addElement(h)
        end
        
        
    end
    
    
    methods (Hidden)
        
        
        function addLineElement(obj, le)
            containerId='';
            for fn={'resistance', 'inductivity', 'crossInductivity', 'capacity', 'directProportionalVoltageDrop', 'externalVoltageDrop'}
                if and(isempty(containerId), isa(le, ['msElectricSimulation.modelling.' fn{1}]))
                    containerId=fn{1};
                end
            end
            if isempty(containerId)
                error('unknown type');
            end
            haveIdx=sum(obj.(containerId)==le);
            if haveIdx==0
                if any(arrayfun(@(x) strcmp(x.id, le.id), obj.(containerId)))
                    error('have already an lineElement of type "%s" with id "%s"', class(le), le.id);
                end
                obj.(containerId)(end+1)=le;
            else
                assert(haveIdx==1)
            end
        end
        
        
        function ret=addElement(obj, ele_)
            containerId='';
            if any(cellfun(@(x) isa(ele_, ['msElectricSimulation.modelling.' x]), {'node', 'line'}))
                containerId=strrep(class(ele_), 'msElectricSimulation.modelling.', '');
            elseif isa(ele_, 'msElectricSimulation.modelling.compound')
                containerId='compound';
            end
            if isempty(containerId)
                error('unknown type of class "%s"', class(ele_));
            end
            
            switch containerId
                case {'line', 'node'}
                    haveId=find(arrayfun(@(x) strcmp(x.id, ele_.id), obj.(containerId)));
                    if ~isempty(haveId)
                        if obj.(containerId)(haveId)~=ele_
                            error('%s "%s" already exist! Skip it.', containerId, ele_.id);
                        end
                    end
                    if isempty(haveId)
                        obj.(containerId)(end+1)=ele_;
                    end
                case 'compound'
                    haveId=find(cellfun(@(x) strcmp(x.id, ele_.id), obj.(containerId)));
                    if ~isempty(haveId)
                        if obj.(containerId){haveId}~=ele_
                            error('%s "%s" already exist! Skip it.', containerId, ele_.id);
                        end
                    end
                    if isempty(haveId)
                        obj.(containerId){end+1}=ele_;
                    end
            end
            ret=ele_;
        end
        
        
        function ret=getElement(obj, id_, containerId)
            idx=arrayfun(@(x) strcmp(x.id, id_), obj.(containerId));
            if isempty(idx)
                warning('%s "%s" does not exist!', (containerId), id_);
                return
            end
            assert(sum(idx)==1);
            ret=obj.(containerId)(idx);
        end
        
        
    end
    
    
    methods % for visualization
        
        
        function varargout=generateGraph(obj)
            colId=arrayfun(@(x) x.id, obj.line, 'UniformOutput', false);
            rowId=arrayfun(@(x) x.id, obj.node, 'UniformOutput', false);
            xData=arrayfun(@(x) x.position(1), obj.node, 'UniformOutput', true);
            yData=arrayfun(@(x) x.position(2), obj.node, 'UniformOutput', true);
            
            NodeTable=table(rowId', 'VariableNames', {'Name'});
            
            sIdx=arrayfun(@(x) find(x.fromNode==obj.node), obj.line)';
            tIdx=arrayfun(@(x) find(x.toNode==obj.node), obj.line)';
            EdgeTable=table([sIdx tIdx], 'VariableNames', {'EndNodes'});
            EdgeTable(:, end+1)=num2cell(ones(height(EdgeTable), 1));
            EdgeTable.Properties.VariableNames{end}='Weight';
            EdgeTable(:, end+1)=colId';
            EdgeTable.Properties.VariableNames{end}='Code';
            
            G = digraph(EdgeTable,NodeTable);
            if nargout==0
                fh=findobj('Type', 'Figure', ...
                    'Name', obj.id);
                if isempty(fh)
                    fh=figure('Name', obj.id);
                end
                clf(fh);
                h=plot(G, ...
                    'NodeLabel',G.Nodes.Name, ...
                    'EdgeLabel',G.Edges.Code, ...
                    'Interpreter', 'none');
                if ~any(isnan([xData yData]))
                    set(h, ...
                        'XData', xData, ...
                        'YData', yData)
                end
            else
                varargout{1}=G;
            end
        end
        
        
        function [mat, vec]=getMatrixVector(obj, typeStr)
            [matStr, vec]=obj.getCCodeMatrixVector(typeStr);
            
            id=arrayfun(@(x) x.id, obj.(typeStr), 'UniformOutput', false);
            switch typeStr
                case {'resistance', 'inductivity', 'capacity', 'crossInductivity', 'directProportionalVoltageDrop'}
                    value=arrayfun(@(x) x.value, obj.(typeStr));
                    n=cellfun(@(x) numel(x), id);
                    [~, idxS]=sort(n, 'descend');
                    for idxId=idxS
                        for idx=1:numel(matStr)
                            matStr{idx}=strrep(matStr{idx}, id{idxId}, num2str(value(idxId)));
                        end
                    end
                case 'externalVoltageDrop'
                otherwise
                    error('unknonw type "%s"', typeStr);
            end
            mat=zeros(size(matStr));
            for idx=1:numel(matStr)
                if ~isempty(matStr{idx})
                    mat(idx)=eval(matStr{idx});
                end
            end
        end
        
        
        function showJacobians(obj)
            for idx=1:numel(obj.line)
                vStr=arrayfun(@(x) obj.value2Cstr(x), ...
                    full(obj.line(idx).jacobian), ...
                    'UniformOutput', false);
                vStr=['[' strjoin(vStr, ' ') ']'];
                
                fprintf('%s%s: %s\n', ...
                    blanks(max([0; 20-numel(obj.line(idx).id)])), ...
                    obj.line(idx).id, ...
                    vStr);
            end
        end
        
        
    end
    
    
    properties (Access=private) % for analysis
        
        
        degreeOfFreedom=0
        
        
    end
    
    
    methods % for analysis
        
        
        function ret=getDegreeOfFreedom(obj)
            if obj.degreeOfFreedom==0
                obj.analyze
            end
            if isempty(obj.line(1).jacobian)
                obj.analyze
            end
            obj.degreeOfFreedom=numel(obj.line(1).jacobian);
            
            ret=obj.degreeOfFreedom;
        end
        
        
        function [mat, vec]=getNodeInputMatrix(obj, varargin)
            if nargin==1
                varargin=num2cell(obj.node);
            end
            for idx=1:numel(varargin)
                hNode=varargin{idx};
                if ischar(hNode)
                    hNode=obj.getNode(hNode);
                    varargin{idx}=hNode;
                end
                if ~isa(hNode, 'msElectricSimulation.modelling.node')
                    error('have no node');
                end
            end
            mat=zeros(obj.getDegreeOfFreedom, numel(varargin));
            for idx=1:numel(varargin)
                hNode=varargin{idx};
                for idx2=1:numel(hNode.outflowLines)
                    mat(:, idx)=mat(:, idx)+...
                        hNode.outflowLines(idx2).jacobian';
                end
                for idx2=1:numel(hNode.inflowLines)
                    mat(:, idx)=mat(:, idx)-...
                        hNode.inflowLines(idx2).jacobian';
                end
            end
            if nargin==1
                idxV=sum(abs(mat), 1)>sqrt(eps);
                mat=mat(:, idxV);
                varargin=varargin(idxV);
            end
            if nargout>1
                vec=cellfun(@(x) x.id, varargin, 'UniformOutput', false);
            end
        end
        
        
        function [startNodes, evalLines, fromNodeIsKnown]=getNodeVoltageCalculation(obj)
            unusedLines=obj.line;
            evalLines=msElectricSimulation.modelling.line.empty(1,0);
            
            [~, nodeId]=obj.getNodeInputMatrix;
            allKnownNodes=cellfun(@(x) obj.getNode(x), nodeId);
            knownNodes=allKnownNodes(1);
            startNodes=knownNodes;
            unknownNodes=setdiff(obj.node, knownNodes);
            
            fromNodeIsKnown=zeros(1, 0, 'logical');
            
            while ~isempty(unknownNodes)
                addFurtherNode=false;
                idxV=find(arrayfun(@(x) ...
                    and(any(x.fromNode==knownNodes), any(x.toNode==unknownNodes)), ...
                    unusedLines));
                if ~isempty(idxV)
                    knownNodes(end+1)=unusedLines(idxV(1)).toNode;
                    unknownNodes=setdiff(unknownNodes, knownNodes(end));
                    evalLines(end+1)=unusedLines(idxV(1));
                    unusedLines=setdiff(unusedLines, evalLines(end));
                    fromNodeIsKnown(end+1)=true;
                    addFurtherNode=true;
                end
                idxV=find(arrayfun(@(x) ...
                    and(any(x.toNode==knownNodes), any(x.fromNode==unknownNodes)), ...
                    unusedLines));
                if ~isempty(idxV)
                    knownNodes(end+1)=unusedLines(idxV(1)).fromNode;
                    unknownNodes=setdiff(unknownNodes, knownNodes(end));
                    evalLines(end+1)=unusedLines(idxV(1));
                    unusedLines=setdiff(unusedLines, evalLines(end));
                    fromNodeIsKnown(end+1)=false;
                    addFurtherNode=true;
                end
                if ~addFurtherNode
                    tmp=setdiff(allKnownNodes, knownNodes);
                    knownNodes(end+1)=tmp(1);
                    startNodes(end+1)=tmp(1);
                    unknownNodes=setdiff(unknownNodes, knownNodes(end));
                end
            end
            
            if false
                for idx=1:numel(knownNodes)
                    fprintf('node%i: %s\n', idx, knownNodes(idx).id);
                end
                for idx=1:numel(evalLines)
                    fprintf('line%i: %s\n', idx, evalLines(idx).id);
                end
            end
            
            % fprintf('startNodeId: %s\n', startNodeId);
            for idx=1:numel(evalLines)
                lineId=evalLines(idx).id;
                fromId=evalLines(idx).fromNode.id;
                toId=evalLines(idx).toNode.id;
                lSign=fromNodeIsKnown(idx);
                % fprintf('line %s from %s to %s ### %i\n', lineId, fromId, toId, lSign);
            end
            
        end
        
        
    end
    
    
    methods %(Access=private) % for analysis
        
        
        function analyze(obj, showMatrix)
            if nargin<2
                showMatrix=true;
            end
            
            A=zeros(numel(obj.node), numel(obj.line));
            for idx=1:numel(obj.node)
                [~, ~, idxV]=intersect(obj.node(idx).inflowLines, obj.line);
                A(idx, idxV)=1;
                [~, ~, idxV]=intersect(obj.node(idx).outflowLines, obj.line);
                A(idx, idxV)=-1;
            end
            
            if showMatrix
                T=array2table(A, ...
                    'RowNames', arrayfun(@(x) x.id, obj.node, 'UniformOutput', false), ...
                    'VariableNames', arrayfun(@(x) x.id, obj.line, 'UniformOutput', false));
                disp(T);
            end
            
            for idx=1:numel(obj.compound)
                Aadd=obj.compound{idx}.getZeroConstraint(obj.line);
                if size(Aadd, 1)>0
                    A=[A
                        Aadd];
                    if showMatrix
                        Tadd=array2table(Aadd, ...
                            'RowNames', arrayfun(@(x) sprintf('%s_%i', obj.compound{idx}.id, x), 1:size(Aadd, 1), 'UniformOutput', false), ...
                            'VariableNames', arrayfun(@(x) x.id, obj.line, 'UniformOutput', false));
                        T=[T
                            Tadd];
                        disp(Tadd);
                    end
                end
            end
            
            evalIdx=sum(abs(A), 2)>1;
            evalA=A(evalIdx, :);
            if showMatrix
                evalT=T(evalIdx, :);
                disp(evalT);
            end
            
            [R, idxDependent]=rref(evalA);
            idxBasis=setdiff(1:size(R, 2), idxDependent);
            if showMatrix
                disp('matrixR');
                disp(R);
                disp('idxDependent');
                disp(idxDependent);
                disp('idxBasis');
                disp(idxBasis);
            end
            
            %RDependent=R(:, idxDependent);
            RBasis=R(:, idxBasis);
            if showMatrix
                disp('RBasis');
                disp(RBasis);
            end
            linesDependent=obj.line(idxDependent);
            linesBasis=obj.line(idxBasis);
            for idx=1:numel(linesBasis)
                tmpJac=sparse(1, numel(idxBasis));
                tmpJac(idx)=1;
                linesBasis(idx).setJacobian(tmpJac);
            end
            for idx=1:numel(linesDependent)
                linesDependent(idx).setJacobian(sparse(-RBasis(idx, :)));
            end
            obj.line=obj.line([idxBasis idxDependent]);
        end
        
        
    end
    
    
    methods % code generation
        
        
        function [mat, vec]=getCCodeMatrixVector(obj, typeStr)
            N=numel(obj.line(1).jacobian);
            switch typeStr
                case {'resistance', 'capacity', 'inductivity', 'crossInductivity'}
                    mat=repmat({''}, N, N);
                    vec=[];
                    for idx=1:numel(obj.(typeStr))
                        [matTmp, vecTmp]=obj.(typeStr)(idx).getCCodeMatrixVector;
                        for idx2=1:numel(matTmp)
                            if ~isempty(matTmp{idx2})
                                mat{idx2}=[mat{idx2} '+(' matTmp{idx2} ')'];
                            end
                        end
                        if isempty(vec)
                            vec=vecTmp;
                        else
                            assert(all(arrayfun(@(x) strcmp(vec{x}, vecTmp{x}), 1:numel(vec))));
                        end
                    end
                    if isempty(vec)
                        mat=[];
                    end
                case {'directProportionalVoltageDrop', 'externalVoltageDrop'}
                    mat=repmat({''}, N, numel(obj.(typeStr)));
                    vec=cell(1, numel(obj.(typeStr)));
                    for idx=1:numel(obj.(typeStr))
                        [mat_, vec_]=obj.(typeStr)(idx).getCCodeMatrixVector;
                        if ~isempty(mat_)
                            mat(:, idx)=mat_;
                            vec(idx)=vec_;
                        end
                    end
                    idxV=cellfun(@(x) ~isempty(x), vec);
                    mat=mat(:, idxV);
                    vec=vec(idxV);
                case 'nodeInput'
                    [matN, vec]=obj.getNodeInputMatrix;
                    mat=repmat({''}, size(matN, 1), size(matN, 2));
                    for idx=1:numel(matN)
                        if abs(matN(idx))>sqrt(eps)
                            mat{idx}=obj.value2Cstr(matN(idx));
                        end
                    end
                    vec=cellfun(@(x) ['nodeInput_' x], vec, 'UniformOutput', false);
                otherwise
                    error('unknown typeStr "%s"', typeStr);
            end
            if ~isempty(vec)
                vecU=unique(vec);
                if numel(vecU)~=numel(vec)
                    matU=repmat({''}, N, numel(vecU));
                    for idx=1:numel(vecU)
                        for idxV=find(cellfun(@(x) strcmp(x, vecU{idx}), vec))
                            for idx2=1:N
                                if ~isempty(mat{idx2, idxV})
                                    matU{idx2, idx}=[matU{idx2, idx} '+(' mat{idx2, idxV} ')'];
                                end
                            end
                        end
                    end
                    vec=vecU;
                    mat=matU;
                end
            end
        end
        
        
        function [massMatrix, h]=getCCodeODE(obj)
            N=numel(obj.line(1).jacobian);
            
            h=arrayfun(@(x) sprintf('%s%i=', obj.rightHandSideId, x), 1:N, 'UniformOutput', false);
            [a,b]=obj.getCCodeMatrixVector('nodeInput');
            for idx2=1:size(a, 2)
                for idx1=1:size(a, 1)
                    if ~isempty(a{idx1, idx2})
                        h{idx1}=[h{idx1} '+((' a{idx1, idx2} ')*(' b{idx2} '))'];
                    end
                end
            end
            for fn={'resistance', 'capacity', 'directProportionalVoltageDrop', 'externalVoltageDrop'}
                [a,b]=obj.getCCodeMatrixVector(fn{1});
                for idx2=1:size(a, 2)
                    for idx1=1:size(a, 1)
                        if ~isempty(a{idx1, idx2})
                            h{idx1}=[h{idx1} '-((' a{idx1, idx2} ')*(' b{idx2} '))'];
                        end
                    end
                end
            end
            for idx=1:numel(h)
                if strfind(h{idx}, '=')==numel(h{idx})
                    h{idx}=[h{idx} '0.'];
                end
                h{idx}=[h{idx} ';'];
            end
            
            [massMatrix, LuDot]=obj.getCCodeMatrixVector('inductivity');
            [CL, CLuDot]=obj.getCCodeMatrixVector('crossInductivity');
            if ~isempty(CL)
                assert(all(arrayfun(@(idx) strcmp(LuDot{idx}, CLuDot{idx}), 1:numel(LuDot))));
            end
            for idx=1:numel(massMatrix)
                if ~isempty(CL)
                    if ~isempty(CL{idx})
                        massMatrix{idx}=['(' massMatrix{idx} ')+(' CL{idx} ')'];
                    end
                end
                if isempty(massMatrix{idx})
                    massMatrix{idx}='0.';
                end
            end
            for idx=1:numel(massMatrix)
                [idx1, idx2]=ind2sub(size(massMatrix), idx);
                massMatrix{idx}=sprintf('%s%i_%i=%s;', obj.massMatrixId, idx1, idx2, massMatrix{idx});
            end
        end
        
        
        function [ccode, id]=getCCodeEvaluation(obj)
            ccode=cell(1, 0);
            id=cell(1, 0);
            for idx=1:obj.getDegreeOfFreedom
                ccode{end+1}=sprintf('ODE_h_%i=h_%i;', idx, idx);
                id{end+1}={['ODE' filesep 'h' filesep sprintf('h_%i', idx)]};
            end
            for idx1=1:obj.getDegreeOfFreedom
                for idx2=1:obj.getDegreeOfFreedom
                    ccode{end+1}=sprintf('ODE_M_%i_%i=massMatrix_%i_%i;', idx2, idx1, idx2, idx1);
                    id{end+1}={['ODE' filesep 'massMatrix' filesep sprintf('M_%i_%i', idx2, idx1)]};
                end
            end
            for idx=1:numel(obj.line)
                tmp=obj.line(idx).getCCodeCurrentEvaluation('currentDot');
                ccode=[ccode tmp];
            end
            id=[id arrayfun(@(x) {['currentDot' filesep x.id]}, obj.line, 'UniformOutput', false)];
            for idx=1:numel(obj.line)
                tmp=obj.line(idx).getCCodeVoltageDropCalculation;
                ccode=[ccode tmp];
                for idxTmp=1:numel(tmp)
                    idx1=strfind(tmp{idxTmp}, '_');
                    idx2=strfind(tmp{idxTmp}, '=');
                    typeStr=tmp{idxTmp}((idx1(2)+1):(idx2-1));
                    id{end+1}={['byLine' filesep obj.line(idx).id filesep typeStr], ...
                        ['byType' filesep typeStr filesep obj.line(idx).id]};
                end
            end
            tmp=obj.getCCodeNodeVoltageCalculation;
            ccode=[ccode tmp];
            for idxTmp=1:numel(tmp)
                idx1=strfind(tmp{idxTmp}, '_');
                idx2=strfind(tmp{idxTmp}, '=');
                idStr=tmp{idxTmp}((idx1(1)+1):(idx2-1));
                id{end+1}={['nodeVoltage' filesep idStr]};
            end
            for idx=1:numel(obj.compound)
                [code_, id_]=obj.compound{idx}.getCCodeEvaluation;
                ccode=[ccode code_];
                id=[id id_];
            end
        end
        
        
        function [indep, dep]=getCCodeVariables(obj)
            indep=[];
            dep=[];
            for fn={'resistance', 'capacity', 'inductivity', 'crossInductivity'}
                h=obj.(fn{1});
                for idx=1:numel(h)
                    if h(idx).isIndependentSize
                        indep.(h(idx).getCCodeId)=h(idx).value;
                    else
                        dep.(h(idx).getCCodeId)=h(idx).getCCodeCalculation;
                    end
                end
            end
            for fn={'directProportionalVoltageDrop', 'externalVoltageDrop'}
                h=obj.(fn{1});
                for idx=1:numel(h)
                    if h(idx).isIndependentSize
                        indep.(h(idx).getCCodeId)=h(idx).value;
                        vec=h(idx).getCCodeVec;
                        for idx2=1:numel(vec)
                            indep.(vec{idx2})=0;
                        end
                    else
                        dep.(h(idx).getCCodeId)=h(idx).getCCodeCalculation;
                    end
                end
            end
            for fn={'nodeInput'}
                [~, vec]=obj.getCCodeMatrixVector(fn{1});
                for idx=1:numel(vec)
                    indep.(vec{idx})=0;
                end
            end
            indep=orderfields(indep);
        end
        
        
        function ret=getCCodeNodeVoltageCalculation(obj)
            [startNode, evalLines, fromNodeIsKnown]=obj.getNodeVoltageCalculation;
            ret=cell(1,0);
            for idx=1:numel(startNode)
                ret{end+1}=sprintf('nodeVoltage_%s=nodeInput_%s;', startNode(idx).id, startNode(idx).id);
            end
            for idx=1:numel(evalLines)
                lineId=evalLines(idx).id;
                fromId=evalLines(idx).fromNode.id;
                toId=evalLines(idx).toNode.id;
                if fromNodeIsKnown(idx)
                    ret{end+1}=sprintf('nodeVoltage_%s=nodeVoltage_%s-voltageDrop_%s_total;', ...
                        toId, fromId, lineId);
                else
                    ret{end+1}=sprintf('nodeVoltage_%s=nodeVoltage_%s+voltageDrop_%s_total;', ...
                        fromId, toId, lineId);
                end
            end
        end
        
        
    end
    
    
    %
    %
    %     methods % for calculation
    %
    
    %
    %
    %         function ret=showInputMatrix(obj, varargin)
    %             [retNum, ~]=getInputMatrix(obj, varargin{:});
    %             ret=cell(size(retNum));
    %             for idx=1:numel(retNum)
    %                 ret{idx}=obj.value2str(retNum(idx), false, nargout>0);
    %             end
    %             if nargout==0
    %                 disp(ret)
    %                 clear('ret');
    %             end
    %         end
    %
    %
    %         function [ret, id]=getOutputMatrix(obj)
    %             id=arrayfun(@(x) x.id, obj.line, 'UniformOutput', false);
    %             ret=zeros(numel(id), numel(obj.line(1).jacobian));
    %             for idx=1:numel(obj.line)
    %                 ret(idx, :)=full(obj.line(idx).jacobian);
    %             end
    %             [~, idxS]=sort(id);
    %             id=id(idxS);
    %             ret=ret(idxS, :);
    %         end
    %
    %
    
    %
    %
    %         function getSteadyStateCurrent(obj, u)
    %             %UI=dgl.getInputMatrix(n.S, n.G);
    %             %u=R\(UI*[1; 0])
    %
    %             R=obj.getResistanceMatrix;
    %             U=obj.getInputMatrix;
    %             stateV=R\(U*u)
    %             obj.getLineCurrent(stateV)
    %         end
    %
    %
    %         function getLineCurrent(obj, stateV)
    %             for idx=1:numel(obj.line)
    %                 fprintf('%s%s: % 10.3f A (% e)\n', ...
    %                     blanks(20-numel(obj.line(idx).id)), ...
    %                     obj.line(idx).id, ...
    %                     obj.line(idx).jacobian*stateV, ...
    %                     obj.line(idx).jacobian*stateV);
    %             end
    %         end
    %
    %
    
    
end