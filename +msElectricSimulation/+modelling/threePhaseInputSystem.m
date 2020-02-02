classdef threePhaseInputSystem < msEloSimulation.basic.compoundElement
    
    
    properties
        lABC
    end
    
    
    methods
        
        
        function obj=threePhaseInputSystem(id_, lA_, lB_, lC_)
            obj=obj@msEloSimulation.basic.compoundElement(id_);
            
            obj.lABC=[lA_, lB_, lC_];
        end
        
        
        function hBlock=createSimulinkEval(obj, hSystem)
            [hBlock, hSys]=hSystem.addSubsystem([obj.id '_eval']);
            
            hCurrent=hSys.addInport('current');
            hFrom=hSystem.addFrom('current');
            hSystem.connect(hFrom, 1, hBlock, 1);
            hSelectStr=arrayfun(@(x) x.id, obj.lABC, 'UniformOutput', false);
            hBusS=hSys.addBusSelector(hSelectStr, 'OutputAsBus', 'on');
            hSys.connect(hCurrent, 1, hBusS, 1)
            hReshape=hSys.addReshape([3,1]);
            hSys.connect(hBusS, 1, hReshape, 1)
            hCurrent=hSys.addGoto('current');
            hSys.connect(hReshape, 1, hCurrent, 1);
            
            hGain=hSys.addGain(obj.A_albe_abc, ...
                'Multiplication', 'Matrix(K*u) (u vector)');
            hCurrent=hSys.addFrom('current');
            hSys.connect(hCurrent, 1, hGain, 1);
            h=hSys.addGoto('current_albe');
            hSys.connect(hGain, 1, h, 1);
            hDemux=hSys.addDemux(2);
            hSys.connect(hGain, 1, hDemux, 1);
            hC=hSys.addReIm2Complex;
            hSys.connect(hDemux, 1, hC, 1)
            hSys.connect(hDemux, 2, hC, 2)
            hMP=hSys.addComplex2MagnitudePhase;
            hSys.connect(hC, 1, hMP, 1);
            h=hSys.addGoto('current_albe_magnitude');
            hSys.connect(hMP, 1, h, 1);
            h=hSys.addGoto('current_albe_phase');
            hSys.connect(hMP, 2, h, 1);
            hSum=hSys.addSum('+');
            hSys.connect(hGain, 1, hSum, 1);
            h=hSys.addGoto('current_albe_currentSum');
            hSys.connect(hSum, 1, h, 1);
            h=hSys.addGoto('current_abc_currentSum');
            hSum=hSys.addSum('+');
            hSys.connect(hSum, 1, h, 1);
            hSys.connect(hCurrent, 1, hSum, 1);
            
            fn={'current_albe', 'current_albe_magnitude', 'current_albe_phase', ...
                'current_albe_currentSum', 'current_abc_currentSum'};
            hBusC=hSys.addBusCreator(numel(fn));
            for idx=1:numel(fn)
                hFrom=hSys.addFrom(fn{idx});
                hSys.connect(hFrom, 1, hBusC, idx, fn{idx});
            end
            hOut=hSys.addOutport('data');
            hSys.connect(hBusC, 1, hOut, 1)
            
            hSys.arrange;
        end
        
        
    end
    
    
end