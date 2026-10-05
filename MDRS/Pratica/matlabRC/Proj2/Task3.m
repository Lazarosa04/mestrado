%% 3


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

timeLimit= 30;
k= 6;
sP= cell(1,nFlows);
nSP= zeros(1,nFlows);

nUnicast = size(Tu,1);

for f = 1:nFlows
    if f <= nUnicast
        [paths,costs] = kShortestPath(L,T(f,1),T(f,2),k);
        sP{f} = paths;
        nSP(f)= length(costs);
    else
        [path,~] = kShortestPath(L,T(f,1),T(f,2),1);
        sP{f} = path;
        nSP(f)= 1;
    end
end


fprintf("\n===== ALGORITHM D — MULTI-START HILL CLIMBING (GREEDY START) =====\n");
[bSol,bUpgrades,bObjective,noCycles,avObjective,bTime,bE] = ...
    HillClimbing_Greedy_multiStart_v3(nNodes,Links,T,sP,nSP,timeLimit, L);

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

%% 3.c)

DC_candidates = [4 5 6 12 13];
% cria automaticamente todos os pares possiveis
DC_pairs = nchoosek(DC_candidates,2);

bestGlobalE = inf;
bestSolGlobal = inf;

timeLimit = 60;
k = 6;

% para cada par de DC
for c = 1:size(DC_pairs,1)
    
    % par atual
    DC = DC_pairs(c,:);
    fprintf("\nTesting DCs = {%d, %d}\n", DC(1), DC(2));

    % Build Ta_fixed for this DC pair e join to Tu to create T
    Ta_fixed = zeros(size(Ta,1),4);

    for f = 1:size(Ta,1)
        o = Ta(f,1);
        b_up = Ta(f,2);
        b_down = Ta(f,3);

        bestCost = inf;
        bestDC = 0;

        for d = DC
            [~, totalCost] = kShortestPath(L, o, d, 1);
        
            if ~isempty(totalCost) && totalCost(1) < bestCost
                bestCost = totalCost(1);
                bestDC = d;
            end
        end
    
        % Nova linha válida para calcLinkLoads
        Ta_fixed(f,:) = [o, bestDC, b_up, b_down];
    end

    T = [Tu; Ta_fixed];
    nFlows = size(T,1);
    nUnicast = size(Tu,1);

    % Calculate candidate paths
    sP = cell(1,nFlows);
    nSP = zeros(1,nFlows);

    for f = 1:nFlows
        if f <= nUnicast
            [paths,costs] = kShortestPath(L,T(f,1),T(f,2),k);
            sP{f} = paths;
            nSP(f) = length(costs);
        else
            [path,~] = kShortestPath(L,T(f,1),T(f,2),1);
            sP{f} = path;
            nSP(f) = 1;
        end
    end

    % Calculate Energy
    [bSol,bUp,bW,~,~,~,bE] = ...
        HillClimbing_Greedy_multiStart_v3(nNodes,Links,T,sP,nSP,timeLimit,L);

    fprintf("Energy = %.2f | W = %.2f\n", bE, bW);

    if isempty(bSol)
        fprintf("No feasible solution found for DCs = {%d, %d}\n", DC(1), DC(2));
        continue;
    end


    % Update global best
    if bE < bestGlobalE
        bestGlobalE = bE;
        bestDCpair = DC;
        bestW = bW;
        bestUpgrades = bUp;
        bestSolGlobal = bSol;

        bestT  = T;
        bestSP = sP;
    end
end

Loads = calcLinkLoads(nNodes,Links,bestT,bestSP,bestSolGlobal);

fprintf("\n===== BEST DC PAIR (Task 3.c) =====\n");
fprintf("DCs = {%d, %d}\n", bestDCpair(1), bestDCpair(2));
fprintf("Best Energy = %.2f | W = %.2f\n", bestGlobalE, bestW);

printSleepingAndUpgradedLinks(Loads, bestUpgrades);


function printSleepingAndUpgradedLinks(Loads, Upgrades)

    fprintf("Links in sleeping mode: ");
    for i = 1:size(Loads,1)
        if Loads(i,3) + Loads(i,4) == 0
            fprintf("{%d,%d} ", Loads(i,1), Loads(i,2));
        end
    end
    fprintf("\n");

    fprintf("Upgraded links (100 Gbps): ");
    for i = 1:length(Upgrades)
        if Upgrades(i) == 100
            fprintf("{%d,%d} ", Loads(i,1), Loads(i,2));
        end
    end
    fprintf("\n");
end
