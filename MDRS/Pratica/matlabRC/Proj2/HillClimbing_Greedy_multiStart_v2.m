function [bSol,bObjective,noCycles,avObjective,bTime,bE] = HillClimbing_Greedy_multiStart_v2(nNodes,Links,T,sP,nSP,timeLimit,L, C)

    t = tic;
    nFlows = size(T,1);

    noCycles = 0;
    aux = 0;
    
    bObjective = inf;
    bE = inf;

    while toc(t) < timeLimit
        
        % Greedy randomized
        sol = zeros(1, nFlows);
        while min(sol) == 0
            sol = GreedyRandomizedSelection(nNodes, Links, T, sP, nSP, L, C);
        end
        Loads = calcLinkLoads(nNodes, Links, T, sP, sol);
        solObj = max(max(Loads(:,3:4)));
        E = energy_consumption_v2(L, Loads, C, nNodes);

        % Hill climbing
        improved = true;
        while improved && toc(t) < timeLimit
            improved = false;
            
            for f = 1:nFlows
                for p = 1:nSP(f)
                    if p ~= sol(f)
                        tempSol = sol;
                        tempSol(f) = p;
                        
                        tempLoads = calcLinkLoads(nNodes, Links, T, sP, tempSol);
                        tempObj = max(max(tempLoads(:,3:4)));

                        tempE = energy_consumption_v2(L, tempLoads, C, nNodes);
                        
                        if (tempObj <= C && tempE < E)
                            sol = tempSol;
                            solObj = tempObj;
                            improved = true;
                            E = tempE;
                        end
                    end
                end
            end
        end

        % Register cycle
        noCycles = noCycles + 1;
        aux = aux + solObj;

        % Update best solution
        if E < bE
            bObjective = solObj;
            bSol = sol;
            bTime = toc(t);
            bE = E;
        end
    end

    avObjective = aux / noCycles;
end



function sol = GreedyRandomizedSelection(nNodes, Links, T, sP, nSP, L, C)
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
        bestE = inf;        % verifica energia

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

            tempE = energy_consumption_v2(L, tempLoads, C, nNodes);

            if (tempLoadVal <= C && tempE < bestE)
                bestLoad = tempLoadVal;
                bestPath = p;
                bestE = tempE;                  % melhor energia
            end
        end
        
        % garantir que vai ter sempre um caminho (1o)
        if bestPath == 0
            return  
        end

        % Atribui o melhor caminho encontrado, ao fluxo certo
        sol(f) = bestPath;
    end
end
