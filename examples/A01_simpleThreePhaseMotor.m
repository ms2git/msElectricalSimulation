clear
clc
close all

sys=msElectricSimulation.modelling.system('threePhaseMotor');

nodesTmp={
    'A', 2, 000
    'B', 2, 120
    'C', 2, 240
    'a', 1, 000
    'b', 1, 120
    'c', 1, 240};
nodes=[];
for idx=1:size(nodesTmp, 1)
    nodes.(nodesTmp{idx, 1})=msElectricSimulation.modelling.node(sys, ...
        nodesTmp{idx, 1}, ...
        nodesTmp{idx, 2}*exp(complex(0, nodesTmp{idx, 3}/180*pi)));
end
clear('nodesTmp');

linesTmp={'ab', 'bc', 'Aa', 'ca', 'Bb', 'Cc'};
lines=[];
for idx=1:numel(linesTmp)
    lines.(linesTmp{idx})=msElectricSimulation.modelling.line(sys, ...
        linesTmp{idx}, ...
        sys.getNode(linesTmp{idx}(1)), ...
        sys.getNode(linesTmp{idx}(2)));
end
clear('linesTmp')


tPM=msElectricSimulation.modelling.threePhaseMotor(sys, '3PM', lines.ab, lines.bc, lines.ca, 'omega');

hRes=msElectricSimulation.modelling.resistance('R', .3);
lines.Aa.addResistance(hRes)
lines.Bb.addResistance(hRes)
lines.Cc.addResistance(hRes)
hInd=msElectricSimulation.modelling.inductivity('L', 1e-3);
lines.Aa.addElement(hInd)
lines.Bb.addElement(hInd)
lines.Cc.addElement(hInd)
hCap=msElectricSimulation.modelling.capacity('C', 1e-2);
lines.Aa.addElement(hCap)


ode=msElectricSimulation.simulink.modelCreation(sys);




return


if withCompare
nodesTmp={
    'a1', 1, -10
    'a2', 1, 10
    'b1', 1, 110
    'b2', 1, 130
    'c1', 1, 230
    'c2', 1, 250};
nodes2=[];
for idx=1:size(nodesTmp, 1)
    nodes2.(nodesTmp{idx, 1})=msElectricSimulation.modelling.node(nodesTmp{idx, 1}, ...
        nodesTmp{idx, 2}*exp(complex(0, nodesTmp{idx, 3}/180*pi))+3);
    sys.addNode(nodes2.(nodesTmp{idx, 1}));
end
clear('nodesTmp');

linesTmp={'a2b1', 'b2c1', 'c2a1'};
lines2=[];
for idx=1:numel(linesTmp)
    lines2.(linesTmp{idx})=msElectricSimulation.modelling.line(linesTmp{idx}, ...
        sys.getNode(linesTmp{idx}([1 2])), ...
        sys.getNode(linesTmp{idx}([3 4])));
end
clear('linesTmp')
tPM2=msElectricSimulation.modelling.threePhaseMotor('3PM2', lines2.a2b1, lines2.b2c1, lines2.c2a1, 'omega');
end


sys.analyze;
sys.showJacobians
ode=msElectricSimulation.simulink.modelCreation(sys);
