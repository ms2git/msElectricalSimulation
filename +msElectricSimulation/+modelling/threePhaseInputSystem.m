classdef threePhaseInputSystem < msElectricSimulation.modelling.compound
    
    
    properties (Constant)
        
        
        A_albe_abc=[2/3 -1/3 -1/3; 0 1/sqrt(3) -1/sqrt(3)];
        
        
    end
    
    
    properties
        
        
        lAH
        lBH
        lCH
        lAL
        lBL
        lCL
        
        
    end
    
    
    methods
        
        
        function obj=threePhaseInputSystem(system_, id_, lAH_, lBH_, lCH_, lAL_, lBL_, lCL_)
            obj=obj@msElectricSimulation.modelling.compound(system_, id_);
            obj.lAH=lAH_;
            obj.lBH=lBH_;
            obj.lCH=lCH_;
            obj.lAL=lAL_;
            obj.lBL=lBL_;
            obj.lCL=lCL_;
        end
        
        
        function ret=getZeroConstraint(obj, hLines)
            ret=zeros(0, numel(hLines));
        end
        
        
    end
    
    
    methods % code generation
        
        
        function ret=getCCodeId(obj)
            ret=['COMP_' obj.id];
        end
        
        
        function [ret, outputId]=getCCodeEvaluation(obj)
            ret=cell(1, 0);
            outputId=cell(1, 0);
            outputId{end+1}='currentA';
            outA=[obj.getCCodeId '_' outputId{end}];
            ret{end+1}=[outA '=' obj.lAH.getCCodeId('current') '-' obj.lAL.getCCodeId('current') ';'];
            outputId{end+1}='currentB';
            outB=[obj.getCCodeId '_' outputId{end}];
            ret{end+1}=[outB '=' obj.lBH.getCCodeId('current') '-' obj.lBL.getCCodeId('current') ';'];
            outputId{end+1}='currentC';
            outC=[obj.getCCodeId '_' outputId{end}];
            ret{end+1}=[outC '=' obj.lCH.getCCodeId('current') '-' obj.lCL.getCCodeId('current') ';'];
            outputId{end+1}='currentSum';
            ret{end+1}=[obj.getCCodeId '_' outputId{end} '=' outA '+' outB '+' outC ';'];
            
            outputId{end+1}='currentAlpha';
            ret{end+1}=[obj.getCCodeId '_' outputId{end} '=' outA ';'];
            outputId{end+1}='currentBeta';
            ret{end+1}=[obj.getCCodeId '_' outputId{end} '=(' obj.value2Cstr(1/sqrt(3)) ')*(' outA ')+(' ...
                obj.value2Cstr(2/sqrt(3)) ')*(' outB ');'];
            
            outputId=cellfun(@(x) {[obj.id filesep x]}, outputId, 'UniformOutput', false);
        end
        
        
    end
    
    
end