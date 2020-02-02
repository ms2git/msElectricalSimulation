classdef threePhaseMotor < msElectricSimulation.modelling.compound
    
    
    properties (Constant)
        
        
        A_albe_abc=[2/3 -1/3 -1/3; 0 1/sqrt(3) -1/sqrt(3)];
        
        
    end
    
    
    properties
        
        
        lA
        lB
        lC
        lABC
        EMFid
        
        
    end
    
    
    properties
        
        
        hInd
        hIndLine
        hEMF
        hEMFLine
        
        
    end
    
    
    methods
        
        
        function obj=threePhaseMotor(system_, id_, lA_, lB_, lC_, EMFid_)
            obj=obj@msElectricSimulation.modelling.compound(system_, id_);
            
            obj.lA=lA_;
            obj.lB=lB_;
            obj.lC=lC_;
            obj.lABC=[lA_ lB_ lC_];
            obj.EMFid=EMFid_;
            
            obj.addResistances
            obj.addInductivities
            obj.addEMF
            
            obj.system.analyze(false)
        end
        
        
        function ret=getZeroConstraint(obj, hLines)
            ret=zeros(1, numel(hLines));
            for idx=1:numel(obj.lABC)
                ret(hLines==obj.lABC(idx))=1;
            end
            assert(sum(ret)==3)
        end
        
        
        function addResistances(obj)
            hRes=msElectricSimulation.modelling.resistance(obj.id, 1e-2);
            obj.lA.addElement(hRes);
            obj.lB.addElement(hRes);
            obj.lC.addElement(hRes);
        end
        
        
        function addInductivities(obj)
            V=[];
            V.alal=msElectricSimulation.modelling.inductivity(['Psi_' obj.id '_alal'], .07);
            V.bebe=msElectricSimulation.modelling.inductivity(['Psi_' obj.id '_bebe'], .05);
            V.albe=msElectricSimulation.modelling.crossInductivity(['Psi_' obj.id '_albe'], .03);
            for fn=fieldnames(V)'
                obj.system.addLineElement(V.(fn{1}));
            end
            obj.hInd=V;
            
            L=[];
            L.aa={{4/9, V.alal}};
            L.bb={{1/9, V.alal}, {-2*sqrt(3)/9, V.albe}, {1/3, V.bebe}};
            L.cc={{1/9, V.alal}, {2*sqrt(3)/9, V.albe}, {1/3, V.bebe}};
            L.ab={{-2/9, V.alal}, {2*sqrt(3)/9, V.albe}};
            L.bc={{1/9, V.alal}, {-1/3, V.bebe}};
            L.ca={{-2/9, V.alal}, {-2*sqrt(3)/9, V.albe}};
            
            fStr=@(idx1, idx2) sprintf('%s%s', obj.lABC(idx1).id, obj.lABC(idx2).id);
            LL=[];
            LL.aa=msElectricSimulation.modelling.inductivity(fStr(1, 1));
            LL.bb=msElectricSimulation.modelling.inductivity(fStr(2, 2));
            LL.cc=msElectricSimulation.modelling.inductivity(fStr(3, 3));
            LL.ab=msElectricSimulation.modelling.crossInductivity(fStr(1, 2));
            LL.bc=msElectricSimulation.modelling.crossInductivity(fStr(2, 3));
            LL.ca=msElectricSimulation.modelling.crossInductivity(fStr(3, 1));
            for fn=fieldnames(LL)'
                LL.(fn{1}).setAsDependent(true, L.(fn{1}));
            end
            obj.hIndLine=LL;
            
            obj.lA.addInductivity(LL.aa);
            obj.lB.addInductivity(LL.bb);
            obj.lC.addInductivity(LL.cc);
            obj.lA.addCrossInductivity(LL.ab);
            obj.lB.addCrossInductivity(LL.ab);
            obj.lB.addCrossInductivity(LL.bc);
            obj.lC.addCrossInductivity(LL.bc);
            obj.lC.addCrossInductivity(LL.ca);
            obj.lA.addCrossInductivity(LL.ca);
        end
        
        
        function addEMF(obj)
            V=[];
            V.al=msElectricSimulation.modelling.directProportionalVoltageDrop(['Psi_' obj.id '_al_' obj.EMFid], obj.EMFid, 3);
            V.be=msElectricSimulation.modelling.directProportionalVoltageDrop(['Psi_' obj.id '_be_' obj.EMFid], obj.EMFid, 5);
            for fn=fieldnames(V)'
                obj.system.addLineElement(V.(fn{1}));
            end
            obj.hEMF=V;
            
            L=[];
            L.a={{2/3, V.al}};
            L.b={{-1/3, V.al}, {sqrt(3)/3, V.be}};
            L.c={{-1/3, V.al}, {-sqrt(3)/3, V.be}};
            
            fStr=@(idx1) sprintf('%s_%s', obj.lABC(idx1).id, obj.EMFid);
            LL=[];
            LL.a=msElectricSimulation.modelling.directProportionalVoltageDrop(fStr(1));
            LL.b=msElectricSimulation.modelling.directProportionalVoltageDrop(fStr(2));
            LL.c=msElectricSimulation.modelling.directProportionalVoltageDrop(fStr(3));
            for fn=fieldnames(LL)'
                LL.(fn{1}).setAsDependent(true, L.(fn{1}));
                LL.(fn{1}).setInputId(obj.EMFid);
            end
            obj.hEMFLine=LL;
            
            obj.lA.addDirectProportionalVoltageDrop(LL.a);
            obj.lB.addDirectProportionalVoltageDrop(LL.b);
            obj.lC.addDirectProportionalVoltageDrop(LL.c);
        end
        
        
    end
    
    
    methods % code generation
        
        
        function ret=getCCodeId(obj)
            ret=['COMP_' obj.id];
        end
        
        
        function [ret, outputId]=getCCodeEvaluation(obj)
            ret=cell(1, 0);
            outputId=cell(1, 0);
            outputId{end+1}='currentSum';
            ret{end+1}=[obj.getCCodeId '_' outputId{end} '=' obj.lA.getCCodeId('current') '+' obj.lB.getCCodeId('current') '+' obj.lC.getCCodeId('current') ';'];
            outputId{end+1}='currentAlpha';
            ret{end+1}=[obj.getCCodeId '_' outputId{end} '=' obj.lA.getCCodeId('current') ';'];
            outputId{end+1}='currentBeta';
            ret{end+1}=[obj.getCCodeId '_' outputId{end} '=(' obj.value2Cstr(1/sqrt(3)) ')*(' obj.lA.getCCodeId('current') ')+(' ...
                obj.value2Cstr(2/sqrt(3)) ')*(' obj.lB.getCCodeId('current') ');'];
            for fn=fieldnames(obj.hIndLine)'
                outputId{end+1}=obj.hIndLine.(fn{1}).getCCodeId;
                ret{end+1}=[obj.getCCodeId '_' outputId{end} '=' obj.hIndLine.(fn{1}).getCCodeId ';'];
            end
            for fn=fieldnames(obj.hEMFLine)'
                outputId{end+1}=obj.hEMFLine.(fn{1}).getCCodeId;
                ret{end+1}=[obj.getCCodeId '_'  outputId{end} '=' obj.hEMFLine.(fn{1}).getCCodeId ';'];
            end
            outputId=cellfun(@(x) {[obj.id filesep x]}, outputId, 'UniformOutput', false);
        end
        
        
    end
    
    
end