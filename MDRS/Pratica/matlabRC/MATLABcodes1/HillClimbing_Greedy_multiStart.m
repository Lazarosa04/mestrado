function [bSol,bObjective,noCycles,avObjective,bTime,bE] = HillClimbing_Greedy_multiStart(nNodes,Links,T,sP,nSP,timeLimit,L,a)

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
            sol = GreedyRandomizedSelection(nNodes, Links, T, sP, nSP, a, L);
        end
        Loads = calcLinkLoads(nNodes, Links, T, sP, sol);
        solObj = max(max(Loads(:,3:4)));
        E = energy_consumption(L, Loads);

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

                        tempE = energy_consumption(L, tempLoads);
                        
                        % loads só tem q ser alfa*10
                        if (tempObj <= a*10 && tempE < E)
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
        if solObj < bObjective
            bObjective = solObj;
            bSol = sol;
            bTime = toc(t);
            bE = E;
        end
    end

    avObjective = aux / noCycles;
end



function sol = GreedyRandomizedSelection(nNodes, Links, T, sP, nSP, a, L)
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

            tempE = energy_consumption(L, tempLoads);

            if (tempLoadVal < a*10 && tempE < bestE)
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


function E = energy_consumption(L, Loads)
    E = 0;
    
    nLinks = size(Loads,1);
    
    for i = 1:nLinks
        % verificar se está operacional (>0)
        node1 = Loads(i,1);
        node2 = Loads(i,2);
        linkLoad = Loads(i,3) + Loads(i,4);
        
        if linkLoad > 0
            % Se operacional -> 20 + 10% do comprimento
            E = E + 20 + 0.1 * L(node1, node2);
        else
            % else -> 1
            E = E + 1;
        end 
    end
end
