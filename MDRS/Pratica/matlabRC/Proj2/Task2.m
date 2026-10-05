%% 2


load("InputDataProject2.mat")
nNodes= size(Nodes,1);
nLinks= size(Links,1);
addpath('C:\Users\Ruben\Documents\MATLAB\MATLABcodes1')

DC = [5 12];

Ta_fixed = zeros(size(Ta,1), 4);

% posiçoes 2 e 3 -> tráfego de ida e volta (respetivamente)
for f = 1:size(Ta,1)
    o = Ta(f,1);
    b_up = Ta(f,2);
    b_down = Ta(f,3);

    best_Cost = inf;
    best_DC = 0;

    for d = DC
        [~, totalCost] = kShortestPath(L, o, d, 1);
        if totalCost(1) < best_Cost
            best_Cost = totalCost(1);
            best_DC = d;
        end
    end

    % Nova linha válida para calcLinkLoads
    Ta_fixed(f,:) = [o, best_DC, b_up, b_down];
end

T = [Tu; Ta_fixed];
nFlows= size(T,1);

C = 50;

%% b)
% Run the algorithm developed in task 2.a for 30 seconds with
% k = 6. Register the worst link load, the network energy consumption and the links in
% sleeping mode of the best obtained solution. Register also the running time at which the
% algorithm has obtained its best solution.

timeLimit= 30;
%k= 6;
k = inf;
sP= cell(1,nFlows);
nSP= zeros(1,nFlows);
nUnicast = size(Tu,1);

for f = 1:nFlows
    if f <= nUnicast
        [paths,costs] = kShortestPath(L,T(f,1),T(f,2),6);
        sP{f} = paths;
        nSP(f)= length(costs);
    else
        [path,~] = kShortestPath(L,T(f,1),T(f,2),1);
        sP{f} = path;
        nSP(f)= 1;
    end
end


fprintf("\n===== ALGORITHM D — MULTI-START HILL CLIMBING (GREEDY START) =====\n");
[bSol,bObjective,noCycles,avObjective,bTime, bE] = ...
    HillClimbing_Greedy_multiStart_v2(nNodes,Links,T,sP,nSP,timeLimit, L, C);

fprintf("W = %.2f Gbps | No. sol = %d | Av. W = %.2f | best time = %.2f sec | Energy consumption = %.2f\n", ...
    bObjective, noCycles, avObjective, bTime, bE);

Loads  = calcLinkLoads(nNodes,Links,T,sP,bSol);

fprintf("List of links in sleeping mode: ");
for i = 1:size(Loads,1)
    linkLoad = Loads(i,3) + Loads(i,4);
    if linkLoad == 0
        node1 = Loads(i,1);
        node2 = Loads(i,2);
        fprintf('{%d, %d} ', node1, node2);
    end
    if i == (size(Loads,1) - 1)
        fprintf("\n");
    end
end