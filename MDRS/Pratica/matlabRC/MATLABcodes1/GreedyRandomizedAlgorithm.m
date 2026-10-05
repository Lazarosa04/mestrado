function [bSol,bObjective,noCycles,avObjective,bTime] = GreedyRandomizedAlgorithm(nNodes,Links,T,sP,nSP,timeLimit)
% [bSol,bObjective,noCycles,avObjective,bTime] = GreedyRandomizedAlgorithm(...)
% Greedy randomized version of the random algorithm

    t = tic;
    nFlows = size(T,1);
    bObjective = inf;
    noCycles = 0;
    aux = 0;

    while toc(t) < timeLimit
        sol = GreedyRandomizedSelection(nNodes, Links, T, sP, nSP); % greedy randomized
        Loads = calcLinkLoads(nNodes, Links, T, sP, sol);
        load = max(max(Loads(:,3:4)));

        noCycles = noCycles + 1;
        aux = aux + load;

        if load < bObjective
            bSol = sol;
            bObjective = load;
            bTime = toc(t);
        end
    end
    avObjective = aux / noCycles;
end


function sol = GreedyRandomizedSelection(nNodes, Links, T, sP, nSP)
% Gera uma solução greedy randomizada (1ª alternativa)
    % conta o numero de fluxos existentes (fluxos da tabela dada)
    nFlows = size(T,1);
    % ele vai conter qual dos caminhos do SP escolher
    % isto é, sol(1)=3 -> SP{1}{3}
    sol = zeros(1, nFlows);

    % First, choose a random order of the flows t ∈ T
    % ou seja, ordenar ordem dos fluxos de forma random
    flowOrder = randperm(nFlows);

    % calcular o melhor path para cada um dos fluxos, pela ordem random gerada
    for idx = 1:nFlows
        f = flowOrder(idx);  % fluxo atual
        bestLoad = inf;
        bestPath = 0;

        % assign the routing path p ∈ Pt that, together with the previous
        % assigned routing paths, gives the best optimization objective value
        % nSP -> numero de shortest paths
        % testar todos os possiveis paths para cada fluxo, e escolher o melhor
        for p = 1:nSP(f)
            tempSol = sol;
            tempSol(f) = p; % vou criando o path, começo com [1 0 0 ...], se começar no fluxo 1, faço isso para todos os caminhos possiveis de cada fluxo
            % se tem só 3 caminhos, testo o caminho dos 3 e escolho o melhor, faço isso ara cada fluxo
            
            % verificar se o pior Load melhora , se sim escolher path
            tempLoads = calcLinkLoads(nNodes, Links, T, sP, tempSol);
            tempLoadVal = max(max(tempLoads(:,3:4)));

            if tempLoadVal < bestLoad
                bestLoad = tempLoadVal;
                bestPath = p;
            end
        end

        % Atribui o melhor caminho encontrado, ao fluxo certo
        sol(f) = bestPath;
    end
end
