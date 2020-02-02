classdef subsystem
    
    
    properties (Access=private)
        hSystem
    end
    
    
    methods
        
        
        function obj=subsystem(hSystem_)
            obj.hSystem=hSystem_;
        end
        
        
        
        % %         function arrange(obj)
        % %             Simulink.BlockDiagram.arrangeSystem(...
        % %                 [get_param(obj.hSystem, 'Parent') '/' get_param(obj.hSystem, 'Name')])
        % %         end
        % %
        % %
        function ret=getBlockH(obj)
            ret=obj.hSystem;
        end
        %
        %
        %         function setBlockSizeAccordingPorts(obj, referencePositionStr, refPos, dx, dy1)
        %             if nargin<4
        %                 dx=100;
        %             end
        %             if nargin<5
        %                 dy1=15;
        %             end
        %             hIn=find_system(obj.hSystem, 'SearchDepth', 1, 'BlockType', 'Inport');
        %             hOut=find_system(obj.hSystem, 'SearchDepth', 1, 'BlockType', 'Outport');
        %             nPorts=1+max([numel(hIn) numel(hOut)]);
        %             switch lower(referencePositionStr)
        %                 case 'northeast'
        %                         x1=refPos(1)-dx;
        %                         x2=refPos(1);
        %                         y1=refPos(2);
        %                         y2=refPos(2)+nPorts*dy1;
        %                 case 'southeast'
        %                         x1=refPos(1)-dx;
        %                         x2=refPos(1);
        %                         y1=refPos(2)-nPorts*dy1;
        %                         y2=refPos(2);
        %                 otherwise
        %                     error('unknown referencePosition "%s"', referencePositionStr);
        %             end
        %             pos=[x1 y1 x2 y2];
        %             set(obj.hSystem, 'Position', pos)
        %         end
        
        
    end
    
    
    methods % add source
        
        
        function ret=addConstant(obj, value, varargin)
            hBlock=obj.addSource('Constant');
            if numel(value)>1
                valueStr=mat2str(value);
            else
                valueStr=num2str(value);
            end
            obj.setBlockParameter(hBlock, 'Value', valueStr, varargin{:});
            if nargout>0
                ret=hBlock;
            end
        end
        
        
        function ret=addInport(obj, id, varargin)
            if nargin<2
                id='';
            end
            hBlock=obj.addSource('Inport', 'In1');
            if ~isempty(id)
                set_param(hBlock, 'Name', id);
            end
            obj.setBlockParameter(hBlock, varargin{:})
            if nargout>0
                ret=hBlock;
            end
        end
        
        
        function ret=addGround(obj, varargin)
            hBlock=obj.addSource('Ground');
            obj.setBlockParameter(hBlock, varargin{:});
            if nargout>0
                ret=hBlock;
            end
        end
        
        
    end
    
    
    methods % add signal routing
        
        
        function ret=addMux(obj, nInputs, varargin)
            hBlock=obj.addSignalRouting('Mux');
            obj.setBlockParameter(hBlock, 'Inputs', num2str(nInputs), varargin{:})
            if nargout>0
                ret=hBlock;
            end
        end
        
        
        function ret=addDemux(obj, nOutputs, varargin)
            hBlock=obj.addSignalRouting('Demux');
            obj.setBlockParameter(hBlock, 'Outputs', num2str(nOutputs), varargin{:})
            if nargout>0
                ret=hBlock;
            end
        end
        
        
        function ret=addVectorConcatenate(obj, nInputs, varargin)
            hBlock=obj.addSignalRouting('Vector Concatenate');
            obj.setBlockParameter(hBlock, 'NumInputs', num2str(nInputs), varargin{:})
            if nargout>0
                ret=hBlock;
            end
        end
        
        
        function ret=addBusCreator(obj, nInputs, varargin)
            hBlock=obj.addSignalRouting('BusCreator', 'Bus Creator');
            obj.setBlockParameter(hBlock, 'Inputs', num2str(nInputs), varargin{:})
            if nargout>0
                ret=hBlock;
            end
        end
        
        
        function ret=addBusSelector(obj, signalStr, varargin)
            if ischar(signalStr)
                signalStr={signalStr};
            end
            hBlock=obj.addSignalRouting('BusSelector', 'Bus Selector');
            obj.setBlockParameter(hBlock, 'OutputSignals', strjoin(signalStr, ','), varargin{:})
            if nargout>0
                ret=hBlock;
            end
        end
        
        
        function ret=addGoto(obj, gotoId, varargin)
            hBlock=obj.addSignalRouting('Goto');
            obj.setBlockParameter(hBlock, 'GotoTag', gotoId, varargin{:})
            if nargout>0
                ret=hBlock;
            end
        end
        
        
        function ret=addFrom(obj, fromId, varargin)
            hBlock=obj.addSignalRouting('From');
            obj.setBlockParameter(hBlock, 'GotoTag', fromId, varargin{:})
            if nargout>0
                ret=hBlock;
            end
        end
        
        
        function ret=addManualSwitch(obj, varargin)
            hBlock=obj.addSignalRouting('Manual Switch');
            obj.setBlockParameter(hBlock, varargin{:})
            if nargout>0
                ret=hBlock;
            end
        end
        
        
        function ret=addSelector(obj, inputDim, outIdx, varargin)
            hBlock=obj.addSignalRouting('Selector');
            obj.setBlockParameter(hBlock, ...
                'IndexOptions', 'Index vector (dialog)', ...
                'InputPortWidth', num2str(inputDim), ...
                'IndexParamArray', {mat2str(outIdx)}, ...
                varargin{:})
            if nargout>0
                ret=hBlock;
            end
        end
        
        
        function ret=addSwitch(obj, varargin)
            hBlock=obj.addSignalRouting('Switch');
            obj.setBlockParameter(hBlock, varargin{:})
            if nargout>0
                ret=hBlock;
            end
        end
        
        
    end
    
    
    methods % add math operations
        
        
        function ret=addSum(obj, nInputs, varargin)
            if isnumeric(nInputs)
                nInputs=repmat('+', 1, nInputs);
            end
            hBlock=obj.addMathOperations('Sum');
            obj.setBlockParameter(hBlock, 'Inputs', nInputs, varargin{:})
            if nargout>0
                ret=hBlock;
            end
        end
        
        
        function ret=addProduct(obj, nInputs, varargin)
            if nargin<2
                nInputs=2;
            end
            if ~ischar(nInputs)
                nInputs=num2str(nInputs);
            end
            hBlock=obj.addMathOperations('Product');
            obj.setBlockParameter(hBlock, 'Inputs', nInputs, varargin{:})
            if nargout>0
                ret=hBlock;
            end
        end
        
        
        function ret=addGain(obj, value, varargin)
            if isnumeric(value)
                if numel(value)==1
                    value=num2str(value);
                else
                    value=mat2str(value);
                end
            end
            hBlock=obj.addMathOperations('Gain');
            obj.setBlockParameter(hBlock, 'Gain', value, varargin{:})
            if nargout>0
                ret=hBlock;
            end
        end
        
        
        function ret=addUnaryMinus(obj, varargin)
            hBlock=obj.addMathOperations('Unary Minus');
            obj.setBlockParameter(hBlock, varargin{:})
            if nargout>0
                ret=hBlock;
            end
        end
        
        
        function ret=addReshape(obj, dim, varargin)
            hBlock=obj.addMathOperations('Reshape');
            obj.setBlockParameter(hBlock, ...
                'OutputDimensions', mat2str(dim), ...
                'OutputDimensionality', 'Customize', ...
                varargin{:})
            if nargout>0
                ret=hBlock;
            end
        end
        
        
        function ret=addReIm2Complex(obj)
            hBlock=obj.addMathOperations('RealImagToComplex', 'Real-Imag to Complex');
            if nargout>0
                ret=hBlock;
            end
        end
        
        
        function ret=addComplex2MagnitudePhase(obj)
            hBlock=obj.addMathOperations('ComplexToMagnitudeAngle', 'Complex to Magnitude-Angle');
            if nargout>0
                ret=hBlock;
            end
        end
        
        
    end
    
    
    methods % add sinks
        
        
        function ret=addTerminator(obj, varargin)
            hBlock=obj.addSinks('Terminator');
            obj.setBlockParameter(hBlock, varargin{:})
            if nargout>0
                ret=hBlock;
            end
        end
        
        
        function ret=addOutport(obj, id, varargin)
            if nargin<2
                id='';
            end
            hBlock=obj.addSinks('Outport', 'Out1');
            if ~isempty(id)
                obj.setBlockParameter(hBlock, 'Name', id)
            end
            obj.setBlockParameter(hBlock, varargin{:});
            if nargout>0
                ret=hBlock;
            end
        end
        
        
    end
    
    
    methods % add continous
        
        
        function ret=addIntegrator(obj, varargin)
            hBlock=obj.addContinuous('Integrator');
            obj.setBlockParameter(hBlock, varargin{:});
            if nargout>0
                ret=hBlock;
            end
        end
        
        
    end
    
    
    methods % add discrete
        
        
        function ret=addMemory(obj, varargin)
            hBlock=obj.addDiscrete('Memory');
            obj.setBlockParameter(hBlock, varargin{:});
            if nargout>0
                ret=hBlock;
            end
        end
        
        
    end
    
    
    methods % add ports and subsystems
        
        
        function ret=addSubsystem(obj, id)
            ret=find_system(obj.hSystem, 'SearchDepth', 1, 'Type', 'block', 'Name', id);
            if isempty(ret)
                ret=obj.addPortsAndSubsystems('SubSystem', 'Subsystem');
                obj.setBlockParameter(ret, 'Name', id);
            else
                hLines=find_system(obj.hSystem, ...
                    'SearchDepth', 1, ...
                    'Findall', 'on', ...
                    'Type', 'Line');
                idxSrc=arrayfun(@(x) get_param(x, 'SrcBlockHandle')==ret, hLines);
                idxDst=arrayfun(@(x) any(get_param(x, 'DstBlockHandle')==ret), hLines);
                idxDel=(idxSrc+idxDst)>0;
                delete_line(hLines(idxDel));
                
                try
                    Simulink.SubSystem.deleteContents(ret)
                catch err
                    disp(err)
                end
            end
            
            parentStr=[get(ret, 'Path') '/' get(ret, 'Name')];
            
            delete_block(...
                find_system(parentStr, ...
                'SearchDepth',1, ...
                'Parent', parentStr, ...
                'Type', 'Block'));
            delete_line(...
                find_system(parentStr, ...
                'SearchDepth',1, ...
                'Findall', 'on', ...
                'Parent', parentStr, ...
                'Type', 'Line'));
        end
        
        
    end
    
    
    methods % add user-defined functions
        
        
        function ret=addSFunction(obj, sFunctionFilename, varargin)
            hBlock=obj.addUserDefinedFunctions('S-Function');
            obj.setBlockParameter(hBlock, ...
                'FunctionName', sFunctionFilename, ....
                varargin{:});
            if nargout>0
                ret=hBlock;
            end
        end
        
        
    end
    
    
    methods (Static)
        
        
        function ret=connect(hSource, idxSource, hTarget, idxTarget, id)
            if isa(hSource, 'msEloSimulation.simulink.subsystem')
                hSource=hSource.getBlockH;
            end
            if isa(hTarget, 'msEloSimulation.simulink.subsystem')
                hTarget=hTarget.getBlockH;
            end
            if ischar(idxSource)
                if strcmpi(idxSource, 'end')
                    
                    idxSource=numel(find_system(hSource, 'SearchDepth', 1, 'BlockType', 'Outport'));
                else
                    error('unknown str');
                end
            end
            if ischar(idxTarget)
                if strcmpi(idxTarget, 'end')
                    idxTarget=numel(find_system(hTarget, 'SearchDepth', 1, 'BlockType', 'Inport'));
                else
                    error('unknown str');
                end
            end
            hLine=add_line(get(hSource, 'Parent'), ...
                [get(hSource, 'Name') '/' num2str(idxSource)], ...
                [get(hTarget, 'Name') '/' num2str(idxTarget)]);
            if nargin>4
                if ~isempty(id)
                    set_param(hLine, 'Name', id);
                end
            end
            if nargout>1
                ret=hLine;
            end
        end
        
        
        function setBlockCenter(hBlock, xCenter, yCenter)
            pos=get_param(hBlock, 'Position');
            dx=diff(pos([1 3]));
            dy=diff(pos([2 4]));
            pos=round([xCenter-dx/2 yCenter-dy/2 xCenter+dx/2 yCenter+dy/2]);
            set_param(hBlock, 'Position', pos)
        end
        
        
        function setBlockWidth(hBlock, dx)
            pos=get_param(hBlock, 'Position');
            xCenter=mean(pos([1 3]));
            pos=round([xCenter-dx/2 pos(2) xCenter+dx/2 pos(4)]);
            set_param(hBlock, 'Position', pos)
        end
        
        
        function setBlockHeight(hBlock, dy)
            pos=get_param(hBlock, 'Position');
            yCenter=mean(pos([2 4]));
            pos=round([pos(1) yCenter-dy/2 pos(3) yCenter+dy/2]);
            set_param(hBlock, 'Position', pos)
        end
        
        
        function arrangeBlock(hBlock, dx, dy, xCenter, yCenter)
            msElectricSimulation.simulink.subsystem.setBlockWidth(hBlock, dx);
            msElectricSimulation.simulink.subsystem.setBlockHeight(hBlock, dy);
            msElectricSimulation.simulink.subsystem.setBlockCenter(hBlock, xCenter, yCenter);
        end
        
        
    end
    
    
    methods (Access=private)
        
        
        function hBlock=addSimulinkLibraryObject(obj, libraryPath, blockType, libraryName)
            id=find_system(obj.hSystem, 'BlockType', blockType);
            id=sprintf('%s%i', blockType, numel(id)+1);
            
            targetP=[get(obj.hSystem, 'Name') '/' id];
            if ~isempty(get(obj.hSystem, 'Parent'))
                targetP=[get(obj.hSystem, 'Path') '/' targetP];
            end
            hBlock=add_block(['simulink/' libraryPath '/' libraryName], ...
                targetP);
        end
        
        
        function hBlock=addSource(obj, blockType, libraryName)
            if nargin<3
                libraryName=blockType;
            end
            hBlock=obj.addSimulinkLibraryObject('Sources', blockType, libraryName);
        end
        
        
        function hBlock=addSignalRouting(obj, blockType, libraryName)
            if nargin<3
                libraryName=blockType;
            end
            hBlock=obj.addSimulinkLibraryObject('Signal Routing', blockType, libraryName);
        end
        
        
        function hBlock=addMathOperations(obj, blockType, libraryName)
            if nargin<3
                libraryName=blockType;
            end
            hBlock=obj.addSimulinkLibraryObject('Math Operations', blockType, libraryName);
        end
        
        
        function hBlock=addSinks(obj, blockType, libraryName)
            if nargin<3
                libraryName=blockType;
            end
            hBlock=obj.addSimulinkLibraryObject('Sinks', blockType, libraryName);
        end
        
        
        function hBlock=addContinuous(obj, blockType, libraryName)
            if nargin<3
                libraryName=blockType;
            end
            hBlock=obj.addSimulinkLibraryObject('Continuous', blockType, libraryName);
        end
        
        
        function hBlock=addDiscrete(obj, blockType, libraryName)
            if nargin<3
                libraryName=blockType;
            end
            hBlock=obj.addSimulinkLibraryObject('Discrete', blockType, libraryName);
        end
        
        
        function hBlock=addPortsAndSubsystems(obj, blockType, libraryName)
            if nargin<3
                libraryName=blockType;
            end
            hBlock=obj.addSimulinkLibraryObject('Ports & Subsystems', blockType, libraryName);
        end
        
        
        function hBlock=addUserDefinedFunctions(obj, blockType, libraryName)
            if nargin<3
                libraryName=blockType;
            end
            hBlock=obj.addSimulinkLibraryObject('User-Defined Functions', blockType, libraryName);
        end
        
        
    end
    
    
    methods (Static, Access=private)
        
        
        function setBlockParameter(hBlock, varargin)
            for idx=1:2:numel(varargin)
                try
                    set_param(hBlock, varargin{idx}, varargin{idx+1});
                catch err
                    disp(err);
                    fprintf('Can not set parameter "%s=%s", skip it. ', ...
                        varargin{idx}, ...
                        varargin{idx+1});
                    fprintf('Parameter value stays at "%s".\n', ...
                        get_param(hBlock, varargin{idx}));
                end
            end
        end
        
        
    end
    
    
end