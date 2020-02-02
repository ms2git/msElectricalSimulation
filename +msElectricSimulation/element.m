classdef element < handle
   
    
    properties
        
        
        id
        
        
    end
    
    
    methods
        
        
        function obj=element(id_)
            obj.id=id_;
        end
        
        
    end
    
    
    properties (Constant) % code generation
       
        
        stateDerId='uDot_';
        stateId='u_';
        stateIntId='q_';
        massMatrixId='massMatrix_';
        rightHandSideId='h_';
     
        
    end
    
    
    methods (Static) % code generation
        
        
        function valueStr=value2Cstr(value)
            knownValuesStr={...
                '1/2', '3/2', '5/2', '7/2', '9/2', ...
                '1/3', '2/3', '4/3', '5/3', '7/3', '8/3', ...
                '1/4', '3/4', '9/4', ...
                '1/9', '2/9', '4/9', '5/9', '7/9', ...
                '3/2', ...
                '2*sqrt(3)/9', ...
                'sqrt(2)', 'sqrt(2)/2', 'sqrt(2)/3', '3/2*sqrt(2)', ...
                'sqrt(3)', 'sqrt(3)/2', 'sqrt(3)/3', '2*sqrt(3)/3', 'sqrt(3)/4', '3*sqrt(3)/4'};
            knownValues=cellfun(@(x) eval(x), knownValuesStr);
            
            if abs(round(value)-value)<sqrt(eps)
                valueStr=sprintf('%+.0f.', value);
            else
                idxV=find(abs(abs(value)-knownValues)<sqrt(eps));
                if ~isempty(idxV)
                    valueStr=regexprep(knownValuesStr{idxV(1)}, '\d*', '$0.');
                    if value < 0
                        valueStr=['(-1.)*(' valueStr ')'];
                    end
                else
                    valueStr=sprintf('%+e', value);
                end
            end
        end
       
        
%         function str=value2str(value, isForFormula, convertToDouble)
%             if nargin<2
%                 isForFormula=false;
%             end
%             if nargin<3
%                 convertToDouble=false;
%             end
%             
%             knownValuesStr={'1/2', ...
%                 '1/3', '2/3', ...
%                 '1/4', '3/4', '9/4', ...
%                 '1/9', '2/9', '4/9', '5/9', '7/9', ...
%                 'sqrt(2)', 'sqrt(2)/2', 'sqrt(2)/3', '3/2*sqrt(2)', ...
%                 'sqrt(3)', 'sqrt(3)/2', 'sqrt(3)/3', 'sqrt(3)/4', '3*sqrt(3)/4'};
%             knownValues=cellfun(@(x) eval(x), knownValuesStr);
%             
%             str='';
%             if abs(value-1)<sqrt(eps)
%                 if isForFormula
%                   str=[str sprintf('+')];
%                 else
%                     if convertToDouble
%                        str='1.';
%                     else
%                        str='1'; 
%                     end
%                 end
%             elseif abs(value+1)<sqrt(eps)
%                 if isForFormula
%                     str=[str sprintf('-')];
%                 else
%                     if convertToDouble
%                         str='-1.';
%                     else
%                         str='-1';
%                     end
%                 end
%             elseif abs(value)<sqrt(eps)
%                 if isForFormula
%                     str=[str sprintf('+0')];
%                 else
%                     if convertToDouble
%                         str='0.';
%                     else
%                         str='0';
%                     end
%                 end
%             else
%                 valueStr='';
%                 if abs(abs(value)-round(abs(value)))<sqrt(eps)
%                     if convertToDouble
%                         valueStr=sprintf('%.0f.', abs(value));
%                     else
%                         valueStr=sprintf('%.0f', abs(value));
%                     end
%                 else
%                     idxV=find(abs(abs(value)-knownValues)<sqrt(eps));
%                     if ~isempty(idxV)
%                         tmp=knownValuesStr{idxV};
%                         if ~convertToDouble
%                             tmp=strrep(tmp, '.', '');
%                         end
%                         valueStr=['(' tmp ')'];
%                     end
%                 end
%                 if ~isempty(valueStr)
%                     if value>0
%                         valueStr=['+' valueStr];
%                     else
%                         valueStr=['-' valueStr];
%                     end
%                     %fprintf('\n\n%+e --> %s\n\n', value, valueStr);
%                 else
%                     valueStr=sprintf('%+e', value);
%                 end
%                 str=[str sprintf('%s', valueStr)];
%             end
%         end
        
        
    end
    
    
end