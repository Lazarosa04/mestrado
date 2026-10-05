% ex 12

addpath('C:\Users\Ruben\Documents\MATLAB\MATLABcodes1')
load("InputData3.mat")
nNodes= size(Nodes,1);
nLinks= size(Links,1);
nFlows= size(T,1);

sP= cell(1,nFlows);
v = 2e5;    % speed of light in fiber
D = L ./ v;

%% a)

% calculae matriz D = L /. v
% DC = [3 5], nós unicast
% T(f,1); tipo de serviço: 1=unicast, 2=anycast
% T(f,2); origem
% T(f,3); destino (0 nos anycast)
% ver serviço, se unicast:
% kShortestPath(L, origem, destino, numero_paths)
% calcular delay = 
% se for anycast:
% kShortestPath(L, origem, destino_anycast (DC), numero_paths)
% se a origem for anycast -> destino é origem, e delay = 0
% calcular delay

DC = [3 5]; % nós anycast

delay_unicast = [];
delay_anycast = [];

T2 = T;

for f = 1:nFlows
    s = T(f,1);
    o = T(f,2);
    d = T(f,3);

    % se unicast
    if s == 1
        [shortestPath, totalCost] = kShortestPath(D,o,d,1);
        sP{1,f}= shortestPath;
        delay_unicast(end+1) = totalCost(1) * 2;
    else
        % verificar se origem é anycast -> delay = 0
        if ismember(o, DC)
            T2(f,3) = o;
            sP{1, f} = {o};
            delay_anycast(end + 1) = 0;
        else
        % ver para qual dos nós anycast o delay é menor
            %delays_to_DCs = zeros(1,length(DC));
            best_delay = inf;
            best_DC = 0;
            best_path = [];
            for i = 1:length(DC)
                [shortestPath, totalCost] = kShortestPath(D,o,DC(i),1);
                %delays_to_DCs = totalCost;
                % guarda o melhor nó anycast
                if totalCost(1) < best_delay
                    best_delay = totalCost(1);
                    best_DC = DC(i);
                    best_path = shortestPath;
                end
            end
            % escolhe melhor delay e muda 0 para melhor anycast
            delay_anycast(end + 1) = best_delay * 2;
            T2(f,3) = best_DC;
            sP{1,f}= best_path;
        end
    end
end

delay_unicast = delay_unicast * 1000;
delay_anycast = delay_anycast * 1000;

fprintf("Anycast nodes= ");
for i = 1:length(DC)
    fprintf("%d ", DC(i));
end
fprintf("\n");
fprintf("Worst round-trip delay (unicast service)  = %5.2f ms\n", max(delay_unicast));
fprintf("Average round-trip delay (unicast service)= %5.2f ms\n", mean(delay_unicast));
fprintf("Worst round-trip delay (anycast service)  = %5.2f ms\n", max(delay_anycast));
fprintf("Average round-trip delay (anycast service)= %5.2f ms\n", mean(delay_anycast));

% T = (:, 2:5) todas as linhas, colunas 2 à 5
% pesquisa exaustiva -> todos pares de nós possiveis
% ficar com a combinaçao com menor carga ou menor tempo de serviço
% serviço anycast optimaze !!!
% se já fiz [3 5], não adianta fazer [5 3]
% for i = 1:nNodes
%  for j = i+1:nNodes
%   anycastNodes[i j]; -> DC

% Determine the link loads of all links and the worst link load of the solution in 12.a.
% remover a 1a coluna dos serviços
T2 = T2(:, 2:5);

sol= ones(1,nFlows);
Loads= calcLinkLoads(nNodes,Links,T2,sP,sol);
% Determine the worst bandwidth required among all links:
maxLoad= max(max(Loads(:,3:4)));

fprintf("Worst link load = %.1f Gbps \n", maxLoad);

for index = 1:nFlows
    % { 1- 2}: 4.20 2.70
    fprintf("{ %2d - %2d }:     %5.2f  %5.2f \n", Loads(index,1), Loads(index,2), Loads(index,3), Loads(index,4));
end

%% 
% Consider that you can freely select the nodes to connect the two DCs running the service.
% Try all possible combinations of 2 nodes and select the one that minimizes the worst link
% load. Indicate the two selected nodes, the worst round-trip delay and the average round
% trip delay of each service. Compare these results with the results obtained for the anycast
% nodes 3 and 5 and draw conclusions.

worst_link_load = inf;
best_pair = [];
best_delay_unicast = [];
best_delay_anycast = [];

for ii=1:nNodes-1
    for j=ii+1:nNodes
        DC=[ii j];
        sP= cell(1,nFlows);

        delay_unicast = [];
        delay_anycast = [];
        
        T2 = T;
        
        for f = 1:nFlows
            s = T(f,1);
            o = T(f,2);
            d = T(f,3);
        
            % se unicast
            if s == 1
                [shortestPath, totalCost] = kShortestPath(D,o,d,1);
                sP{1,f}= shortestPath;
                delay_unicast(end+1) = totalCost(1) * 2;
            else
                % verificar se origem é anycast -> delay = 0
                if ismember(o, DC)
                    T2(f,3) = o;
                    sP{1, f} = {o};
                    delay_anycast(end + 1) = 0;
                else
                % ver para qual dos nós anycast o delay é menor
                    %delays_to_DCs = zeros(1,length(DC));
                    best_delay = inf;
                    best_DC = 0;
                    best_path = [];
                    for i = 1:length(DC)
                        [shortestPath, totalCost] = kShortestPath(D,o,DC(i),1);
                        %delays_to_DCs = totalCost;
                        % guarda o melhor nó anycast
                        if totalCost(1) < best_delay
                            best_delay = totalCost(1);
                            best_DC = DC(i);
                            best_path = shortestPath;
                        end
                    end
                    % escolhe melhor delay e muda 0 para melhor anycast
                    delay_anycast(end + 1) = best_delay * 2;
                    T2(f,3) = best_DC;
                    sP{1,f}= best_path;
                end
            end
        end

        delay_unicast = delay_unicast * 1000;
        delay_anycast = delay_anycast * 1000;

        T2 = T2(:, 2:5);

        sol= ones(1,nFlows);
        Loads= calcLinkLoads(nNodes,Links,T2,sP,sol);
        % Determine the worst bandwidth required among all links:
        maxLoad= max(max(Loads(:,3:4)));

        if maxLoad < worst_link_load
            worst_link_load = maxLoad;
            best_pair = [ii j];
            best_delay_unicast = delay_unicast;
            best_delay_anycast = delay_anycast;
        end

    end
end

fprintf("Anycast nodes= ");
for i = 1:length(best_pair)
    fprintf("%d ", best_pair(i));
end
fprintf("\n");
fprintf("Worst link load = %.1f Gbps \n", worst_link_load);
fprintf("Worst round-trip delay (unicast service)  = %5.2f ms\n", max(best_delay_unicast));
fprintf("Average round-trip delay (unicast service)= %5.2f ms\n", mean(best_delay_unicast));
fprintf("Worst round-trip delay (anycast service)  = %5.2f ms\n", max(best_delay_anycast));
fprintf("Average round-trip delay (anycast service)= %5.2f ms\n", mean(best_delay_anycast));
%% d)

% Again, consider that you can freely select the nodes to connect the two DCs running the
% service. Try all possible combinations of 2 nodes and select the one that minimizes the
% worst round-trip delay of the anycast service. Indicate the two selected nodes, the worst
% round-trip delay and the average round trip delay of each service. Compare these results
% with all previous results and draw conclusions.

worst_best_delay_anycast = inf;
worst_link_load = 0;
best_pair = [];
best_delay_unicast = [];
best_delay_anycast = [];

for ii=1:nNodes-1
    for j=ii+1:nNodes
        DC=[ii j];
        sP= cell(1,nFlows);

        delay_unicast = [];
        delay_anycast = [];
        
        T2 = T;
        
        for f = 1:nFlows
            s = T(f,1);
            o = T(f,2);
            d = T(f,3);
        
            % se unicast
            if s == 1
                [shortestPath, totalCost] = kShortestPath(D,o,d,1);
                sP{1,f}= shortestPath;
                delay_unicast(end+1) = totalCost(1) * 2;
            else
                % verificar se origem é anycast -> delay = 0
                if ismember(o, DC)
                    T2(f,3) = o;
                    sP{1, f} = {o};
                    delay_anycast(end + 1) = 0;
                else
                % ver para qual dos nós anycast o delay é menor
                    %delays_to_DCs = zeros(1,length(DC));
                    best_delay = inf;
                    best_DC = 0;
                    best_path = [];
                    for i = 1:length(DC)
                        [shortestPath, totalCost] = kShortestPath(D,o,DC(i),1);
                        %delays_to_DCs = totalCost;
                        % guarda o melhor nó anycast
                        if totalCost(1) < best_delay
                            best_delay = totalCost(1);
                            best_DC = DC(i);
                            best_path = shortestPath;
                        end
                    end
                    % escolhe melhor delay e muda 0 para melhor anycast
                    delay_anycast(end + 1) = best_delay * 2;
                    T2(f,3) = best_DC;
                    sP{1,f}= best_path;
                end
            end
        end

        delay_unicast = delay_unicast * 1000;
        delay_anycast = delay_anycast * 1000;

        T2 = T2(:, 2:5);

        sol= ones(1,nFlows);
        Loads= calcLinkLoads(nNodes,Links,T2,sP,sol);
        % Determine the worst bandwidth required among all links:
        maxLoad= max(max(Loads(:,3:4)));

        if max(delay_anycast) < worst_best_delay_anycast
            worst_best_delay_anycast = max(delay_anycast);
            worst_link_load = maxLoad;
            best_pair = [ii j];
            best_delay_unicast = delay_unicast;
            best_delay_anycast = delay_anycast;
        end

    end
end

fprintf("Anycast nodes= ");
for i = 1:length(best_pair)
    fprintf("%d ", best_pair(i));
end
fprintf("\n");
fprintf("Worst link load = %.1f Gbps \n", worst_link_load);
fprintf("Worst round-trip delay (unicast service)  = %5.2f ms\n", max(best_delay_unicast));
fprintf("Average round-trip delay (unicast service)= %5.2f ms\n", mean(best_delay_unicast));
fprintf("Worst round-trip delay (anycast service)  = %5.2f ms\n", max(best_delay_anycast));
fprintf("Average round-trip delay (anycast service)= %5.2f ms\n", mean(best_delay_anycast));