% -log(x) -> inverso <- exp(-x)

clear all
close all
clc

addpath('C:\Users\Ruben\Documents\MATLAB\MATLABcodes2')
load('InputData2.mat')
nNodes= size(Nodes,1);
nLinks= size(Links,1);
nFlows= size(T,1);

MTTR= 24;
CC= 450;
MTBF= (CC*365*24)./L;
A= MTBF./(MTBF + MTTR);
A(isnan(A))= 1;
Alog= -log(A);

%% a) e b)
% só 1 path (mais curto)
k = 1;
sP= cell(2,nFlows);
nSP= zeros(1,nFlows);
availabilityTotal = 0;


for f=1:nFlows
    [shortestPath, totalCost] = kShortestPath(Alog,T(f,1),T(f,2),k);
    sP{1,f}= shortestPath;
    nSP(f)= length(totalCost);
    availabity = AvailabilityCalculator(shortestPath{1}, A);
    availabilityTotal = availabilityTotal + availabity;
    fprintf("Flow %d: Availability= %.7f - Path= %s \n", f, availabity, num2str(shortestPath{1}));
end
% média de todos os fluxos
fprintf("Average availability= %.7f", availabilityTotal/nFlows);

%% c) e d)

% Assume that the most available path (computed in 10.a) of each flow is its first routing
% path. For each flow, compute a second routing path (if exists) given by the most available
% path which is link disjoint with the previously computed first routing path. Determine the
% availability of the routing solution of each flow. Is there always a second routing path for
% all flows? Why?

k= 1;
sP= cell(2,nFlows);
nSP= zeros(1,nFlows);
% sP{1,f}{i} is the 1st path of the i-th path pair of flow f
% sP{2,f}{i} is the 2nd path of the i-th path pair of flow f
% nSP(f) is the number of path pairs of flow f

availabilityTotal = 0;

for f=1:nFlows
    [shortestPath, totalCost] = kShortestPath(Alog,T(f,1),T(f,2),k);
    sP{1,f}= shortestPath;
    nSP(f)= length(totalCost);
    availabity1 = AvailabilityCalculator(shortestPath{1}, A);
    %fprintf("Flow %d: Availability= %.7f - Path1= %s \n", f, availabity, num2str(shortestPath{1}));
    for i= 1:nSP(f)
        Aaux= Alog;
        path1= sP{1,f}{i};
        for j=2:length(path1)
            Aaux(path1(j),path1(j-1))= inf;
            Aaux(path1(j-1),path1(j))= inf;
        end
        [shortestPath, totalCost] = kShortestPath(Aaux,T(f,1),T(f,2),1);
        if ~isempty(shortestPath)
            sP{2,f}{i}= shortestPath{1};
            %fprintf("                                   Path2= %s \n", num2str(shortestPath{1}));
            availabity2 = AvailabilityCalculator(shortestPath{1}, A);
        else
            %fprintf("                                   Path2= \n");
            availabity2 = 0;
        end
        
    end
    % 1 - [(1 - availabity1) * (1 - availabity2)]
    availabity = 1 - ((1 - availabity1) * (1 - availabity2));
    availabilityTotal = availabilityTotal + availabity;
    fprintf("Flow %d: Availability= %.7f - Path1= %s \n", f, availabity, num2str(sP{1,f}{1}));
    if ~isempty(sP{2,f}) 
        fprintf("                                   Path2= %s \n", num2str(sP{2,f}{1}));
    else
        fprintf("                                   Path2= \n");
    end
end

fprintf("Average availability= %.7f", availabilityTotal/nFlows);

%% e)

% Compute how much bandwidth capacity is required on each link to support all flows with
% 1+1 protection when each flow is routed by the routing solution of 10.c. Compute also the
% worst bandwidth capacity required among all links and the total bandwidth required in all
% links.

sol= ones(1,nFlows);
Loads= calculateLinkBand1plus1(nNodes,Links,T,sP,sol);
% Determine the worst bandwidth required among all links:
maxLoad= max(max(Loads(:,3:4)));
% Determine the total bandwidth required in all links:
TotalBand= sum(sum(Loads(:,3:4)));

fprintf("Worst bandwidth capacity = %.1f Gbps \n", maxLoad);
fprintf("Total bandwidth capacity on all links = %.1f Gbps \n", TotalBand);


for index = 1:nFlows
    % { 1- 2}: 4.20 2.70
    fprintf("{ %2d - %2d }:     %5.2f  %5.2f \n", Loads(index,1), Loads(index,2), Loads(index,3), Loads(index,4));
end

%% e)

% Compute how much bandwidth capacity is required on each link to support all flows with
% 1:1 protection when each flow is routed by the routing solution of 10.c. Compute also the
% worst bandwidth capacity required among all links and the total bandwidth required in all
% links. Compare these results with the results of 10.e and take conclusions.

sol= ones(1,nFlows);
Loads= calculateLinkBand1to1(nNodes,Links,T,sP,sol);
% Determine the worst bandwidth required among all links:
maxLoad= max(max(Loads(:,3:4)));
% Determine the total bandwidth required in all links:
TotalBand= sum(sum(Loads(:,3:4)));

fprintf("Worst bandwidth capacity = %.1f Gbps \n", maxLoad);
fprintf("Total bandwidth capacity on all links = %.1f Gbps \n", TotalBand);


for index = 1:nFlows
    % { 1- 2}: 4.20 2.70
    fprintf("{ %2d - %2d }:     %5.2f  %5.2f \n", Loads(index,1), Loads(index,2), Loads(index,3), Loads(index,4));
end
