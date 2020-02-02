clear
clc
close all

sys=msElectricSimulation.modelling.system('mySys');

% nA=sys.addNode('A');
% nB=sys.addNode('B');
% nC=msElectricSimulation.modelling.node(sys, 'C');
% lAB=sys.addLine(nA, nB);
% lBC=sys.addLine('_BC_', nB, nC);
% lCA=msElectricSimulation.modelling.line(sys, 'CA', nA, nB);
% 
% lAB.addResistance('xx', 12);
% lAB.addResistance('xxxx', 4);
% lAB.addCapacity('cc', 1.34);
% 
% return



lAB=msElectricSimulation.modelling.line(sys, 'ab');
nA=sys.addNode('A');
nB=msElectricSimulation.modelling.node(sys, 'B');
sys.addLine(lAB);
sys.addNode(nA);
sys.addNode(nB);
lAB.setFromNode(nA);
lAB.setToNode(nB);

nC=sys.addNode('C');
lAC=sys.addLine(nA, nC);

nD=msElectricSimulation.modelling.node(sys, 'D');
lAD=sys.addLine(msElectricSimulation.modelling.line(sys, 'xx2', nA, nD));

l4=sys.addLine(msElectricSimulation.modelling.line(sys, 'CD', nC, nD));
lBD=sys.addLine(msElectricSimulation.modelling.line(sys, 'BD', nB, nD));

nE=msElectricSimulation.modelling.node(sys, 'E');
lBE=sys.addLine(msElectricSimulation.modelling.line(sys, 'BE', nB, nE));
lAE=sys.addLine(msElectricSimulation.modelling.line(sys, 'AE', nA, nE));

nY=sys.addNode('Y');
nZ=sys.addNode(msElectricSimulation.modelling.node(sys, 'Z'));
lZA=sys.addLine('ZA', nZ, nA);
lEY=sys.addLine('EY', 'E', 'Y');

lAE.addInductivity(msElectricSimulation.modelling.inductivity('AE', 1e-3))
lAE.addResistance(msElectricSimulation.modelling.resistance('AE', 3))
lAE.addCapacity(msElectricSimulation.modelling.capacity('AE', .1))
lAE.addCrossInductivity(msElectricSimulation.modelling.crossInductivity('AEcross', 2, lAB))
lAE.addDirectProportionalVoltageDrop(msElectricSimulation.modelling.directProportionalVoltageDrop('AE', 1, 'aeIn'))
lAE.addExternalVoltageDrop(msElectricSimulation.modelling.externalVoltageDrop('AE', 'aeIn'))

lAB.addInductivity('AB', 7e-1)
lAB.addResistance('AB', 7e-1)
lAB.addCapacity('AB', 7e-1)
lAB.addCrossInductivity('ABcross', 2, lAE)
lAB.addDirectProportionalVoltageDrop('AB', 7e-1, 'AB_dpvd')
lAB.addDirectProportionalVoltageDrop('AB2', 5e-1, 'AB2_dpvd')
lAB.addExternalVoltageDrop('AB', 'AB_ext')

rAll=msElectricSimulation.modelling.resistance('RALL', 1.3);
arrayfun(@(x) x.addElement(rAll), sys.line);


lBE.addResistance('BE', 3)
lBD.addCapacity('BD', .1)

sys.generateGraph
%sys.showJacobians