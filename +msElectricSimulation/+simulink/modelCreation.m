classdef modelCreation < msElectricSimulation.element
    
    
    properties (Constant, Hidden)
        
        
        sFunctionInput='U';
        sFunctionStateDer='XDOT';
        sFunctionState='X';
        sFunctionOutput='Y';
        sFunctionRWork='RWORK';
        
        
    end
    
    
    properties
        
        
        ode
        
        simulinkModelId
        hSimulink
        hSimulinkSFunc
        
        
    end
    
    
    methods
        
        
        function obj=modelCreation(ode_)
            obj=obj@msElectricSimulation.element(ode_.id);
            obj.ode=ode_;
            obj.createModel
        end
        
        
        function createModel(obj)
            obj.simulinkModelId=[obj.id '_simulink'];
            obj.openSimulinkModel
            obj.createParameter
            obj.createSFunctionSubsystem
            obj.createSFunctionODE
            obj.createSFunctionEval
        end
        
        
        function openSimulinkModel(obj)
            try
                obj.hSimulink=load_system(obj.simulinkModelId);
            catch
                obj.hSimulink=new_system(obj.simulinkModelId, 'Model', 'ErrorIfShadowed');
            end
            open_system(obj.simulinkModelId)
        end
        
        
        function createParameter(obj)
            hS=msElectricSimulation.simulink.subsystem(obj.hSimulink);
            var=obj.ode.getCCodeVariables;
            fn=fieldnames(var);
            for idx=1:numel(fn)
                constantId=fn{idx};
                gotoId=['GOTO_' fn{idx}];
                hBlock=find_system(obj.hSimulink, 'SearchDepth', 1, 'Type', 'block', 'Name', gotoId);
                if isempty(hBlock)
                    dxConstant=70;
                    dxGoto=150;
                    dy=20;
                    dyGap=20;
                    dxGap=20;
                    hConstant=hS.addConstant(var.(fn{idx}), 'Name', constantId);
                    hS.arrangeBlock(hConstant, dxConstant, dy, 0, (dy+dyGap)*(idx-1));
                    hGoto=hS.addGoto(constantId, 'Name', gotoId, 'ShowName', 'off');
                    hS.arrangeBlock(hGoto, dxGoto, dy, dxConstant/2+dxGap+dxGoto/2, (dy+dyGap)*(idx-1));
                    hS.connect(hConstant, 1, hGoto, 1);
                end
            end
        end
        
        
        function createSFunctionSubsystem(obj)
            var=obj.ode.getCCodeVariables;
            fnVar=fieldnames(var);
            
            hS=msElectricSimulation.simulink.subsystem(obj.hSimulink);
            obj.hSimulinkSFunc=hS.addSubsystem(obj.ode.id);
            hGoto1=find_system(obj.hSimulink, 'SearchDepth', 1, 'Type', 'Block', 'Name', ['GOTO_' fnVar{1}]);
            hGoto2=find_system(obj.hSimulink, 'SearchDepth', 1, 'Type', 'Block', 'Name', ['GOTO_' fnVar{end}]);
            hGoto1=get(hGoto1, 'Position');
            hGoto2=get(hGoto2, 'Position');
            dxGoto=hGoto1(3)-hGoto1(1);
            dxGap=20;
            yPosition=[hGoto1(2) hGoto2(4)];
            xPosition=hGoto1(3)+2*dxGap+dxGoto+dxGap+[0 100];
            hS.arrangeBlock(obj.hSimulinkSFunc, diff(xPosition), diff(yPosition), mean(xPosition), mean(yPosition));
            
            hSub=msElectricSimulation.simulink.subsystem(obj.hSimulinkSFunc);
            hMux=hSub.addMux(numel(fnVar));
            hIn=[];
            for idx=1:numel(fnVar)
                hIn(idx)=hSub.addInport(fnVar{idx});
                hSub.setBlockCenter(hIn(idx), 0, 40*(idx-1));
                hSub.connect(hIn(idx), 1, hMux, idx);
                
                hGoto=find_system(obj.hSimulink, 'SearchDepth', 1, 'Type', 'Block', 'Name', ['GOTO_' fnVar{idx}]);
                hGoto=get(hGoto, 'Position');
                hFrom=hS.addFrom(fnVar{idx}, ...
                    'Name', ['FROM_' fnVar{idx}], ...
                    'ShowName', 'off', ...
                    'Position', hGoto+(dxGoto+40)*[1 0 1 0]);
                hS.connect(hFrom, 1, obj.hSimulinkSFunc, idx);
            end
            hIn1=get(hIn(1), 'Position');
            hIn2=get(hIn(end), 'Position');
            dy=hIn2(4)-hIn1(2);
            yPos=mean([hIn1(2) hIn2(4)]);
            xPos=hIn1(3)+50;
            hSub.setBlockHeight(hMux, dy);
            hSub.setBlockCenter(hMux, xPos, yPos);
            hGoto=hSub.addGoto('odeInput');
            hSub.connect(hMux, 1, hGoto, 1);
            hSub.setBlockWidth(hGoto, 100);
            hSub.setBlockCenter(hGoto, xPos+100, yPos);
        end
        
        
        function createSFunctionODE(obj)
            sFuncName=[obj.simulinkModelId '_ODE'];
            cCode=[...
                obj.sFunctionCode_01header(sFuncName, 'ODE') ...
                obj.sFunctionCode_02mdlInitializeSizes('ODE') ...
                obj.sFunctionCode_03mdlInitializeSampleTimes ...
                obj.sFunctionCode_04mdlInitializeConditions('ODE') ...
                obj.sFunctionCode_05mdlDerivatives('ODE') ...
                obj.sFunctionCode_06mdlOutputs('ODE') ...
                obj.sFunctionCode_09footer];
            fid=fopen([sFuncName '.c'], 'w');
            fprintf(fid, '%s', strjoin(cCode, '\n'));
            fclose(fid);
            pause(.5)
            mex([sFuncName '.c']);
            
            hSub=msElectricSimulation.simulink.subsystem(obj.hSimulinkSFunc);
            
            hSFunc=hSub.addSFunction(sFuncName, 'Position', obj.getBlockPosition('Block', 1, 1));
            hFrom=hSub.addFrom('odeInput', 'Position', obj.getBlockPosition('From', 1, 1));
            hSub.connect(hFrom, 1, hSFunc, 1);
            hGoto=hSub.addGoto('odeOutput', 'Position', obj.getBlockPosition('Goto', 1, 1));
            hSub.connect(hSFunc, 1, hGoto, 1);
            
            [~, sortIdx]=sort(arrayfun(@(x) x.id, obj.ode.line, 'UniformOutput', false));
            N=2*obj.ode.getDegreeOfFreedom+2*numel(obj.ode.line);
            for fn={'current', 'currentInt'}
                switch fn{1}
                    case 'current'
                        outIdx=2*obj.ode.getDegreeOfFreedom+(1:numel(obj.ode.line));
                        yIdx=2;
                    case 'currentInt'
                        outIdx=2*obj.ode.getDegreeOfFreedom+numel(obj.ode.line)+(1:numel(obj.ode.line));
                        yIdx=3;
                    otherwise
                        error('unknown case');
                end
                hFrom=hSub.addFrom('odeOutput', 'Position', obj.getBlockPosition('From', 1, yIdx));
                hSelector=hSub.addSelector(N, outIdx(sortIdx), 'Position', obj.getBlockPosition('Selector', 1, yIdx));
                hSub.connect(hFrom, 1, hSelector, 1);
                hDemux=hSub.addDemux(numel(obj.ode.line), 'Position', obj.getBlockPosition('Demux', 1, yIdx));
                hSub.connect(hSelector, 1, hDemux, 1);
                hBus=hSub.addBusCreator(numel(obj.ode.line), 'Position', obj.getBlockPosition('Mux', 1, yIdx));
                for idx=1:numel(obj.ode.line)
                    hSub.connect(hDemux, idx, hBus, idx, obj.ode.line(sortIdx(idx)).id);
                end
                hGoto=hSub.addGoto(fn{1}, 'Position', obj.getBlockPosition('Goto', 1, yIdx));
                hSub.connect(hBus, 1, hGoto, 1);
            end
        end
        
        
        function createSFunctionEval(obj)
            sFuncName=[obj.simulinkModelId '_eval'];
            cCode=[...
                obj.sFunctionCode_01header(sFuncName, 'eval') ...
                obj.sFunctionCode_02mdlInitializeSizes('eval') ...
                obj.sFunctionCode_03mdlInitializeSampleTimes ...
                obj.sFunctionCode_06mdlOutputs('eval') ...
                obj.sFunctionCode_09footer];
            fid=fopen([sFuncName '.c'], 'w');
            fprintf(fid, '%s', strjoin(cCode, '\n'));
            fclose(fid);
            pause(.5)
            mex([sFuncName '.c']);
            
            yOutIdx=4;
            hSub=msElectricSimulation.simulink.subsystem(obj.hSimulinkSFunc);
            hSFunc=hSub.addSFunction(sFuncName, 'Position', obj.getBlockPosition('Block', 1, yOutIdx));
            hFrom1=hSub.addFrom('odeInput', 'Position', obj.getBlockPosition('From', 1, yOutIdx-.25));
            hFrom2=hSub.addFrom('odeOutput', 'Position', obj.getBlockPosition('From', 1, yOutIdx+.25));
            hMux=hSub.addMux(2, 'Position', obj.getBlockPosition('MuxIn', 1, yOutIdx));
            hSub.connect(hFrom1, 1, hMux, 1);
            hSub.connect(hFrom2, 1, hMux, 2);
            hSub.connect(hMux, 1, hSFunc, 1);
            hGoto=hSub.addGoto('evalOutput', 'Position', obj.getBlockPosition('Goto', 1, yOutIdx));
            hSub.connect(hSFunc, 1, hGoto, 1);
            yOutIdx=yOutIdx+1;
            
            [~, out1]=obj.ode.getCCodeEvaluation;
            numOutput=numel(out1);
            
            out1=obj.createSFunctionEvalOutput;
            fn1=fieldnames(out1);
            aaa___data=[];
            for idx1=1:numel(fn1)
                out2=out1.(fn1{idx1});
                fn2=fieldnames(out2);
                if isstruct(out2.(fn2{1}))
                    for idx2=1:numel(fn2)
                        out3=out2.(fn2{idx2});
                        fn3=fieldnames(out3);
                        if isstruct(out3.(fn3{1}))
                            error('TODO: think about recursive implementation!');
                        else
                            yOutIdx=obj.evaluateSFunctionOutput(hSub, 'evalOutput', fn2{idx2}, yOutIdx, numOutput, out3);
                            aaa___data.(fn1{idx1}).(fn2{idx2})=[];
                        end
                    end
                else
                    yOutIdx=obj.evaluateSFunctionOutput(hSub, 'evalOutput', fn1{idx1}, yOutIdx, numOutput, out2);
                    aaa___data.(fn1{idx1})=[];
                end
            end
            
            fClear=@(x) strrep(x, 'aaa___', '');
            
            aaa___data.current=[];
            aaa___data.currentInt=[];
            [~, idxSort]=sort(cellfun(@(x) fClear(x), fieldnames(aaa___data), 'UniformOutput', false));
            aaa___data=orderfields(aaa___data, idxSort);
            fn1=fieldnames(aaa___data)';
            
            yOutIdx=0;
            hGoto=hSub.addOutport('data', 'Position', obj.getBlockPosition('Goto', 2, yOutIdx-1+mean([1 numel(fn1)])));
            hBusCreator=hSub.addBusCreator(numel(fn1), 'Position', obj.getBlockPosition('Mux', 2, yOutIdx-1+[1 numel(fn1)]));
            hSub.connect(hBusCreator, 1, hGoto, 1)
            for idx1=1:numel(fn1)
                hFrom=hSub.addFrom(fn1{idx1}, 'Position', obj.getBlockPosition('From', 2, yOutIdx));
                hSub.connect(hFrom, 1, hBusCreator, idx1, fClear(fn1{idx1}));
                yOutIdx=yOutIdx+1;
            end
            for idx1=1:numel(fn1)
                tmp2=aaa___data.(fn1{idx1});
                if isempty(tmp2)
                    continue
                end
                fn2=fieldnames(tmp2);
                hGoto=hSub.addGoto(fn1{idx1}, 'Position', obj.getBlockPosition('Goto', 2, yOutIdx-1+mean([1 numel(fn2)])));
                hBusCreator=hSub.addBusCreator(numel(fn2), 'Position', obj.getBlockPosition('Mux', 2, yOutIdx-1+[1 numel(fn2)]));
                hSub.connect(hBusCreator, 1, hGoto, 1)
                for idx2=1:numel(fn2)
                    hFrom=hSub.addFrom(fn2{idx2}, 'Position', obj.getBlockPosition('From', 2, yOutIdx));
                    hSub.connect(hFrom, 1, hBusCreator, idx2, fClear(fn2{idx2}));
                    yOutIdx=yOutIdx+1;
                end
            end
        end
        
        
        function ret=createSFunctionEvalOutput(obj)
            [~, out_id]=obj.ode.getCCodeEvaluation;
            T=table();
            for idx=1:numel(out_id)
                for idxOut=1:numel(out_id{idx})
                    newLine=[idx strsplit(out_id{idx}{idxOut}, filesep)];
                    if size(T, 2)<numel(newLine)
                        addX=numel(newLine)-size(T, 2);
                        addY=size(T, 1);
                        addC=reshape(arrayfun(@(x) '', 1:(addX*addY), 'UniformOutput', false), [addY addX]);
                        T=[T cell2table(addC)];
                    elseif numel(newLine)<size(T, 2)
                        newLine=[newLine, arrayfun(@(x) '', 1:(size(T, 2)-numel(newLine)), 'UniformOutput', false)];
                    end
                    T=[T; newLine];
                end
            end
            for idx=size(T, 2):-1:2
                [~, idxS]=sort(T{:, idx});
                T=T(idxS, :);
            end
            T=[T cell2table(reshape(arrayfun(@(x) '', 1:height(T), 'UniformOutput', false), [height(T) 1]))];
            T=table2cell(T);
            for idx=1:numel(T)
                if ischar(T{idx})
                    if ~isempty(T{idx})
                        T{idx}=['aaa___' T{idx}];
                    end
                end
            end
            ret=[];
            for idx=1:size(T, 1)
                evalStr=T(idx, 2:end);
                evalStr=evalStr(cellfun(@(x) ~isempty(x), evalStr));
                evalStr=['ret.' strjoin(evalStr, '.') '=' num2str(T{idx, 1}) ';'];
                eval(evalStr);
            end
        end
        
        
    end
    
    
    methods
        
        
        function yOutIdx=evaluateSFunctionOutput(obj, hSub, fromId, gotoId, yOutIdx, numOutput, outS)
            idSelect=fieldnames(outS);
            nSelect=numel(idSelect);
            idxSelect=zeros(1, nSelect);
            for idxS=1:nSelect
                idxSelect(idxS)=outS.(idSelect{idxS});
            end
            idSelect=cellfun(@(x) strrep(x, 'aaa___', ''), idSelect, 'UniformOutput', false);
            
            hFrom=hSub.addFrom(fromId, 'Position', obj.getBlockPosition('From', 1, yOutIdx));
            hSelector=hSub.addSelector(numOutput, idxSelect, 'Position', obj.getBlockPosition('Selector', 1, yOutIdx));
            hSub.connect(hFrom, 1, hSelector, 1);
            hDemux=hSub.addDemux(nSelect, 'Position', obj.getBlockPosition('Demux', 1, yOutIdx));
            hSub.connect(hSelector, 1, hDemux, 1);
            hBusCreator=hSub.addBusCreator(nSelect, 'Position', obj.getBlockPosition('Mux', 1, yOutIdx));
            for idx=1:nSelect
                hSub.connect(hDemux, idx, hBusCreator, idx, idSelect{idx});
            end
            hGoto=hSub.addGoto(gotoId, 'Position', obj.getBlockPosition('Goto', 1, yOutIdx));
            hSub.connect(hBusCreator, 1, hGoto, 1);
            
            yOutIdx=yOutIdx+1;
        end
        
        
        function ret=sFunctionCode_01header(obj, sFuncName, caseStr)
            ret=cell(1,0);
            ret{end+1}=sprintf('#define S_FUNCTION_NAME %s', sFuncName);
            ret{end+1}='#define S_FUNCTION_LEVEL 2';ret{end+1}='';
            ret{end+1}='';
            ret{end+1}='#if !defined(_WIN32)';
            ret{end+1}='#define dgesv dgesv_';
            ret{end+1}='#endif';
            ret{end+1}='';
            ret{end+1}='';
            ret{end+1}='#include "simstruc.h"';
            ret{end+1}='#include "lapack.h"';
            ret{end+1}='#include "math.h"';
            ret{end+1}='';
            ret{end+1}='';
            N=obj.ode.getDegreeOfFreedom;
            switch caseStr
                case 'ODE'
                    [indep, dep]=obj.ode.getCCodeVariables;
                    fnIndep=fieldnames(indep);
                    for idx=1:numel(fnIndep)
                        ret{end+1}=sprintf('#define %s (%s[%i])', fnIndep{idx}, obj.sFunctionInput, idx-1);
                    end
                    for fn=fieldnames(dep)'
                        ret{end+1}=sprintf('#define %s (%s)', fn{1}, dep.(fn{1}));
                    end
                    for idx=1:N
                        ret{end+1}=sprintf('#define %s%i (%s[%i])', obj.stateIntId, idx, obj.sFunctionState, idx-1);
                    end
                    for idx=1:N
                        ret{end+1}=sprintf('#define %s%i (%s[%i])', obj.stateId, idx, obj.sFunctionState, idx+N-1);
                    end
                    for idx=1:N
                        ret{end+1}=sprintf('#define %sDOT%i (%s[%i])', obj.stateIntId, idx, obj.sFunctionStateDer, idx-1);
                    end
                    for idx=1:N
                        ret{end+1}=sprintf('#define %sDOT%i (%s[%i])', obj.stateId, idx, obj.sFunctionStateDer, idx+N-1);
                    end
                    for idx=1:N^2
                        [idx1, idx2]=ind2sub([N N], idx);
                        ret{end+1}=sprintf('#define %s%i_%i (%s[%i])', obj.massMatrixId, idx1, idx2, obj.sFunctionRWork, idx-1);
                    end
                    for idx=1:N
                        ret{end+1}=sprintf('#define %s%i (%s[%i])', obj.rightHandSideId, idx, obj.sFunctionStateDer, idx+N-1);
                    end
                    for idx=1:numel(obj.ode.line)
                        ret{end+1}=sprintf('#define %s (%s[%i])', obj.ode.line(idx).getCCodeId('current'), obj.sFunctionOutput, 2*N+idx-1);
                    end
                    for idx=1:numel(obj.ode.line)
                        ret{end+1}=sprintf('#define %s (%s[%i])', obj.ode.line(idx).getCCodeId('currentInt'), obj.sFunctionOutput, 2*N+idx-1+numel(obj.ode.line));
                    end
                case 'eval'
                    inputIdx=0;
                    [indep, dep]=obj.ode.getCCodeVariables;
                    fnIndep=fieldnames(indep);
                    for idx=1:numel(fnIndep)
                        ret{end+1}=sprintf('#define %s (%s[%i])', fnIndep{idx}, obj.sFunctionInput, inputIdx);
                        inputIdx=inputIdx+1;
                    end
                    for fn=fieldnames(dep)'
                        ret{end+1}=sprintf('#define %s (%s)', fn{1}, dep.(fn{1}));
                    end
                    for idx=1:N
                        ret{end+1}=sprintf('#define %s%i (%s[%i])', obj.stateIntId, idx, obj.sFunctionInput, inputIdx);
                        inputIdx=inputIdx+1;
                    end
                    for idx=1:N
                        ret{end+1}=sprintf('#define %s%i (%s[%i])', obj.stateId, idx, obj.sFunctionInput, inputIdx);
                        inputIdx=inputIdx+1;
                    end
                    for idx=1:numel(obj.ode.line)
                        ret{end+1}=sprintf('#define %s (%s[%i])', obj.ode.line(idx).getCCodeId('current'), obj.sFunctionInput, inputIdx);
                        inputIdx=inputIdx+1;
                    end
                    for idx=1:numel(obj.ode.line)
                        ret{end+1}=sprintf('#define %s (%s[%i])', obj.ode.line(idx).getCCodeId('currentInt'), obj.sFunctionInput, inputIdx);
                        inputIdx=inputIdx+1;
                    end
                    [ccode, ~]=obj.ode.getCCodeEvaluation;
                    for idx=1:numel(ccode)
                        idx1=strfind(ccode{idx}, '=')-1;
                        ret{end+1}=sprintf('#define %s (%s[%i])', strtrim(ccode{idx}(1:idx1)), obj.sFunctionOutput, idx-1);
                    end
                    internalIdx=0;
                    for idx=1:N^2
                        [idx1, idx2]=ind2sub([N N], idx);
                        ret{end+1}=sprintf('#define %s%i_%i (%s[%i])', obj.massMatrixId, idx1, idx2, obj.sFunctionRWork, internalIdx);
                        internalIdx=internalIdx+1;
                    end
                    for idx=1:N
                        ret{end+1}=sprintf('#define %s%i (%s[%i])', obj.rightHandSideId, idx, obj.sFunctionRWork, internalIdx);
                        ret{end+1}=sprintf('#define %s%i (%s[%i])', obj.stateDerId, idx, obj.sFunctionRWork, internalIdx);
                        internalIdx=internalIdx+1;
                    end
                otherwise
                    error('TODO')
            end
            ret{end+1}='';
            ret{end+1}='';
        end
        
        
        function ret=sFunctionCode_02mdlInitializeSizes(obj, caseStr)
            ret=cell(1,0);
            ret{end+1}='static void mdlInitializeSizes(SimStruct *S)';
            ret{end+1}='{';
            ret{end+1}='  ssSetNumSFcnParams(S, 0);';
            ret{end+1}='  if (ssGetNumSFcnParams(S) != ssGetSFcnParamsCount(S))';
            ret{end+1}='  {';
            ret{end+1}='    return;';
            ret{end+1}='  }';
            ret{end+1}='';
            switch caseStr
                case 'ODE'
                    numContStates=2*obj.ode.getDegreeOfFreedom;
                otherwise
                    numContStates=0;
            end
            ret{end+1}=sprintf('  ssSetNumContStates(S, %i);', numContStates);
            ret{end+1}='  ';
            ret{end+1}='  ssSetNumDiscStates(S, 0);';
            ret{end+1}='  ';
            switch caseStr
                case 'ODE'
                    inputPortDirectFeedThrough=0;
                case 'eval'
                    inputPortDirectFeedThrough=1;
                otherwise
                    error('TODO')
            end
            ret{end+1}='  if (!ssSetNumInputPorts(S, 1)) return;';
            switch caseStr
                case 'ODE'
                    numInput=numel(fieldnames(obj.ode.getCCodeVariables));
                case 'eval'
                    numInput=numel(fieldnames(obj.ode.getCCodeVariables))+...
                        2*obj.ode.getDegreeOfFreedom+2*numel(obj.ode.line);
                otherwise
                    error('unknown case');
            end
            ret{end+1}=sprintf('  ssSetInputPortWidth(S, 0, %i);', numInput);
            ret{end+1}='  ssSetInputPortRequiredContiguous(S, 0, true);';
            ret{end+1}=sprintf('  ssSetInputPortDirectFeedThrough(S, 0, %i);', inputPortDirectFeedThrough);
            
            ret{end+1}='  ';
            ret{end+1}='  if (!ssSetNumOutputPorts(S, 1)) return;';
            switch caseStr
                case 'ODE'
                    numOutput=2*obj.ode.getDegreeOfFreedom+2*numel(obj.ode.line);
                case 'eval'
                    [ccode, ~]=obj.ode.getCCodeEvaluation;
                    numOutput=numel(ccode);
                otherwise
                    error('TODO')
            end
            ret{end+1}=sprintf('  ssSetOutputPortWidth(S, 0, %i);', numOutput);
            ret{end+1}='  ';
            ret{end+1}='  ssSetNumSampleTimes(S, 1);';
            switch caseStr
                case 'ODE'
                    numInternal=obj.ode.getDegreeOfFreedom^2;
                case 'eval'
                    numInternal=obj.ode.getDegreeOfFreedom^2+obj.ode.getDegreeOfFreedom;
                otherwise
                    error('TODO')
            end
            ret{end+1}=sprintf('  ssSetNumRWork(S, %i);', numInternal);
            ret{end+1}='  ssSetNumIWork(S, 0);';
            ret{end+1}='  ssSetNumPWork(S, 0);';
            ret{end+1}='  ssSetNumModes(S, 0);';
            ret{end+1}='  ssSetNumNonsampledZCs(S, 0);';
            ret{end+1}='  ';
            ret{end+1}='  ssSetOperatingPointCompliance(S, USE_DEFAULT_OPERATING_POINT);';
            ret{end+1}='  ';
            ret{end+1}='  ssSetOptions(S, 0);';
            ret{end+1}='}';
            ret{end+1}='';
            ret{end+1}='';
        end
        
        
        function ret=sFunctionCode_03mdlInitializeSampleTimes(obj)
            ret=cell(1,0);
            ret{end+1}='static void mdlInitializeSampleTimes(SimStruct *S)';
            ret{end+1}='{';
            ret{end+1}='  ssSetSampleTime(S, 0, CONTINUOUS_SAMPLE_TIME);';
            ret{end+1}='  ssSetOffsetTime(S, 0, 0.0);';
            ret{end+1}='}';
            ret{end+1}='';
            ret{end+1}='';
        end
        
        
        function ret=sFunctionCode_04mdlInitializeConditions(obj, caseStr)
            ret=cell(1,0);
            if ~strcmp(caseStr, 'ODE')
                return
            end
            ret{end+1}='#define MDL_INITIALIZE_CONDITIONS';
            ret{end+1}='static void mdlInitializeConditions(SimStruct *S)';
            ret{end+1}='{';
            ret{end+1}='  real_T *x0 = ssGetContStates(S);';
            ret{end+1}='  int_T  lp;';
            ret{end+1}=sprintf('  for (lp=0; lp<%i; lp++) {', 2*obj.ode.getDegreeOfFreedom);
            ret{end+1}='     *x0++=0.0; ';
            ret{end+1}='  }';
            ret{end+1}='};';
            ret{end+1}='';
            ret{end+1}='';
        end
        
        
        function ret=sFunctionCode_05mdlDerivatives(obj, caseStr)
            ret=cell(1,0);
            if ~strcmp(caseStr, 'ODE')
                return
            end
            ret{end+1}='#define MDL_DERIVATIVES';
            ret{end+1}='static void mdlDerivatives(SimStruct *S)';
            ret{end+1}='{';
            ret{end+1}=sprintf('  const real_T *%s = (const real_T*) ssGetInputPortSignal(S, 0);', obj.sFunctionInput);
            ret{end+1}=sprintf('  real_T *%s = ssGetdX(S);', obj.sFunctionStateDer);
            ret{end+1}=sprintf('  real_T *%s = ssGetContStates(S);', obj.sFunctionState);
            ret{end+1}=sprintf('  real_T *%s=ssGetRWork(S);', obj.sFunctionRWork);
            [massM, h]=obj.ode.getCCodeODE;
            massM=cellfun(@(x) ['  ' x], massM, 'UniformOutput', false);
            h=cellfun(@(x) ['  ' x], h, 'UniformOutput', false);
            ret=[ret h massM{:}];
            ret{end+1}='  // matrix inversion (matL * uDot = h)';
            ret{end+1}=sprintf('  size_t dimA1=%i;', obj.ode.getDegreeOfFreedom);
            ret{end+1}=sprintf('  size_t dimA2=%i;', obj.ode.getDegreeOfFreedom);
            ret{end+1}='  size_t dimB2=1;';
            ret{end+1}=sprintf('  real_T *matAPtr=&(%s1_1);', obj.massMatrixId);
            ret{end+1}=sprintf('  ptrdiff_t iPivot[%i];', obj.ode.getDegreeOfFreedom);
            ret{end+1}='  ptrdiff_t *iPivotPtr=&iPivot[0];';
            ret{end+1}='  ptrdiff_t info;';
            ret{end+1}=sprintf('  dgesv(&dimA1, &dimB2, matAPtr, &dimA1, iPivotPtr, &(%sDOT1), &dimA2, &info);', obj.stateId);
            ret{end+1}=sprintf('  memcpy(&(%sDOT1), &(%s1), %i*sizeof(real_T));', obj.stateIntId, obj.stateId, obj.ode.getDegreeOfFreedom);
            ret{end+1}='}';
            ret{end+1}='';
            ret{end+1}='';
        end
        
        
        function ret=sFunctionCode_06mdlOutputs(obj, caseStr)
            ret=cell(1,0);
            ret{end+1}='static void mdlOutputs(SimStruct *S, int_T tid)';
            ret{end+1}='{';
            ret{end+1}=sprintf('  real_T *%s = ssGetOutputPortSignal(S, 0);', obj.sFunctionOutput);
            switch caseStr
                case 'ODE'
                    ret{end+1}=sprintf('  const real_T *%s = (const real_T*) ssGetContStates(S);', obj.sFunctionState);
                    ret{end+1}=sprintf('  memcpy(&(%s[0]), &(%s[0]), %i*sizeof(real_T));', obj.sFunctionOutput, obj.sFunctionState, 2*obj.ode.getDegreeOfFreedom);
                    for idx=1:numel(obj.ode.line)
                        ret=[ret cellfun(@(x) ['  ' x], obj.ode.line(idx).getCCodeCurrentEvaluation('current'), 'UniformOutput', false)];
                        ret=[ret cellfun(@(x) ['  ' x], obj.ode.line(idx).getCCodeCurrentEvaluation('currentInt'), 'UniformOutput', false)];
                    end
                case 'eval'
                    [ccode, ~]=obj.ode.getCCodeEvaluation;
                    isODE=cellfun(@(x) startsWith(x, 'ODE_'), ccode);
                    ccode=cellfun(@(x) ['  ' x], ccode, 'UniformOutput', false);
                    
                    ret{end+1}=sprintf('  const real_T *%s = (const real_T*) ssGetInputPortSignal(S, 0);', obj.sFunctionInput);
                    ret{end+1}=sprintf('  real_T *%s=ssGetRWork(S);', obj.sFunctionRWork);
                    [massM, h]=obj.ode.getCCodeODE;
                    massM=cellfun(@(x) ['  ' x], massM, 'UniformOutput', false);
                    h=cellfun(@(x) ['  ' x], h, 'UniformOutput', false);
                    ret=[ret h massM{:}];
                    ret{end+1}='  // as lapack works on RWORK save data before';
                    ret=[ret ccode(isODE)];
                    ret{end+1}='  // matrix inversion (matL * uDot = h)';
                    ret{end+1}=sprintf('  size_t dimA1=%i;', obj.ode.getDegreeOfFreedom);
                    ret{end+1}=sprintf('  size_t dimA2=%i;', obj.ode.getDegreeOfFreedom);
                    ret{end+1}='  size_t dimB2=1;';
                    ret{end+1}=sprintf('  real_T *matAPtr=&(%s1_1);', obj.massMatrixId);
                    ret{end+1}=sprintf('  ptrdiff_t iPivot[%i];', obj.ode.getDegreeOfFreedom);
                    ret{end+1}='  ptrdiff_t *iPivotPtr=&iPivot[0];';
                    ret{end+1}='  ptrdiff_t info;';
                    ret{end+1}=sprintf('  dgesv(&dimA1, &dimB2, matAPtr, &dimA1, iPivotPtr, &(%s1), &dimA2, &info);', obj.stateDerId);
                    ret{end+1}='  // calculate dependent sizes';
                    ret=[ret ccode(~isODE)];
                otherwise
                    error('TODO');
            end
            ret{end+1}='}';
            ret{end+1}='';
            ret{end+1}='';
        end
        
        
        function ret=sFunctionCode_09footer(obj)
            ret=cell(1,0);
            ret{end+1}='#undef MDL_UPDATE';
            ret{end+1}='';
            ret{end+1}='';
            ret{end+1}='#undef MDL_START';
            ret{end+1}='';
            ret{end+1}='';
            ret{end+1}='static void mdlTerminate(SimStruct *S)';
            ret{end+1}='{';
            ret{end+1}='  UNUSED_ARG(S);';
            ret{end+1}='}';
            ret{end+1}='';
            ret{end+1}='';
            ret{end+1}='#ifdef  MATLAB_MEX_FILE';
            ret{end+1}='#include "simulink.c"';
            ret{end+1}='#else';
            ret{end+1}='#include "cg_sfun.h"';
            ret{end+1}='#endif';
        end
        
        
    end
    
    
    methods (Static)
        
        
        function ret=getBlockPosition(typeStr, idxX, idxY)
            y0=0;
            x0=300;
            dy=50;
            
            xGrid=[0 100 140 260 300 400];
            xGrid=xGrid+(idxX-1)*500;
            yPos=[0 16];
            if numel(idxY)==1
                yPos=yPos+(idxY-1)*dy;
            elseif numel(idxY)==2
                yPos1=yPos+(idxY(1)-1)*dy;
                yPos2=yPos+(idxY(2)-1)*dy;
                yPos=[yPos1(1) yPos2(2)];
            end
            
            switch typeStr
                case 'From'
                    xPos=xGrid([1 2]);
                case 'Block'
                    xPos=xGrid([3 4]);
                case 'Selector'
                    xPos=xGrid(3)+[0 20];
                case 'Demux'
                    xPos=xGrid(3)+40+[0 5];
                    yPos=yPos+10*[-1 1];
                case 'Mux'
                    xPos=xGrid(4)-[5 0];
                    yPos=yPos+10*[-1 1];
                case 'MuxIn'
                    xPos=mean(xGrid([2 3]))+2.5*[-1 1];
                    yPos=yPos+10*[-1 1];
                case 'MuxOut'
                    xPos=mean(xGrid([4 5]))+2.5*[-1 1];
                    yPos=yPos+10*[-1 1];
                case 'Goto'
                    xPos=xGrid([5 6]);
                otherwise
                    error('unknown typeStr "%s"', typeStr);
            end
            
            ret=[xPos(1) yPos(1) xPos(2) yPos(2)];
            ret=round(ret+[x0 y0 x0 y0]);
        end
        
        
    end
    
    
end