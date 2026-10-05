%% 1
% all links have a capacity of 50 Gbps 
% nodes 5 and 12 -> anycast

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

C = 50;     % capacidade de 50 Gbps

%% a)

% Determine the link loads of all links when the traffic flows of the 
% unicast service are also routed through the shortest path provided 
% by the network (using the lengths of the links). Determine the resulting 
% worst link load.

k= 1;
sP= cell(1,nFlows);
nSP= zeros(1,nFlows);
for f=1:nFlows
    [shortestPath, totalCost] = kShortestPath(L,T(f,1),T(f,2),k);
    sP{f}= shortestPath;
    nSP(f)= length(totalCost);
end
% sP{f}{i} is the i-th path of flow f
% nSP(f) is the number of paths of flow f

% Compute the link loads using the first (shortest) path of each flow:
sol= ones(1,nFlows);
Loads= calcLinkLoads(nNodes,Links,T,sP,sol);
% Determine the worst link load:
maxLoad= max(max(Loads(:,3:4)));
fprintf("Worst link load = %5.2f \n", maxLoad);

% Visualizing Loads (nó chegada - saida : custo)
nLoads = size(Loads,1);
for f = 1:nLoads
    fprintf("{%2d -> %2d}:  %5.2f  %5.2f \n", Loads(f,1), Loads(f,2), Loads(f,3), Loads(f,4));
end


%% b)

% Determine the network energy consumption of the previous
% solution and the links that are put in sleeping mode.
E = energy_consumption_v2(L, Loads, C, nNodes); 
fprintf("E= %5.3f\n", E);

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

%% d)

% Run the algorithm developed in task 1.c for 30 seconds with
% k = 6. Register the worst link load, the network energy consumption and the links in
% sleeping mode of the best obtained solution. Register also the running time at which the
% algorithm has obtained its best solution.

timeLimit= 30;
k= 6;
sP= cell(1,nFlows);
nSP= zeros(1,nFlows);

nUnicast = size(Tu,1);
nAnycast = size(Ta_fixed,1);

for f = 1:nFlows
    if f <= nUnicast
        % UNICAST → k shortest paths
        [paths, costs] = kShortestPath(L, T(f,1), T(f,2), k);
        sP{f}  = paths;
        nSP(f) = length(costs);
    else
        % ANYCAST → APENAS 1 caminho (shortest)
        [path, cost] = kShortestPath(L, T(f,1), T(f,2), 1);
        sP{f}  = path;
        nSP(f) = 1;
    end
end

fprintf("\n===== ALGORITHM D — MULTI-START HILL CLIMBING (GREEDY START) =====\n");
[bSol,bObjective,noCycles,avObjective,bTime] = ...
    HillClimbing_Greedy_multiStart_v1(nNodes,Links,T,sP,nSP,timeLimit, C);

fprintf("W = %.2f Gbps | No. sol = %d | Av. W = %.2f | best time = %.2f sec", ...
    bObjective, noCycles, avObjective, bTime);

Loads  = calcLinkLoads(nNodes,Links,T,sP,bSol);
Energy = energy_consumption_v2(L, Loads, C, nNodes);

fprintf(" | Energy consumption = %5.3f\n", Energy);

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