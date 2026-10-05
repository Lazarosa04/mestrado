function [bSol,bUpgrades,bObjective,noCycles,avObjective,bTime,bE] = ...
    HillClimbing_Greedy_multiStart_v3(nNodes,Links,T,sP,nSP,timeLimit,L)

    t = tic;
    nFlows = size(T,1);
    nLinks = size(Links,1);

    noCycles = 0;
    auxW = 0;
    % defenir variaveis de saida default, caso não aja solução
    bE = inf;
    bObjective = inf;

    bSol = [];
    bUpgrades = [];
    bTime = inf;
    % Limite máximo de iterações no Hill Climbing para evitar loops infinitos 
    % ou excesso de cálculo
    maxHCiters = 40;

    while toc(t) < timeLimit
        % Tentativas de gerar uma solução inicial viável com abordagem Greedy Randomizada
        % Caso a função não consiga encontrar um caminho válido para algum fluxo, tentamos novamente
        % Limitamos o número de tentativas a maxGreedyTries para evitar loops infinitos

        maxGreedyTries = 20;
        tries = 0;
        sol = zeros(1,nFlows);
        while min(sol)==0 && tries < maxGreedyTries
            sol = GreedyRandomizedSelection(nNodes,Links,T,sP,nSP);
            tries = tries + 1;
        end

        if min(sol) == 0
            continue;
        end
        %fprintf("    Greedy tries = %d\n", tries);

        upgrades = 50 * ones(nLinks,1);   % all links start at 50

        Loads = calcLinkLoads(nNodes,Links,T,sP,sol);
        W = max(max(Loads(:,3:4)));
        E = energy_consumption_v3(L,Loads,upgrades,nNodes);

        % Hill Climbing
        improved = true;
        % hcIter limita o número de iterações para evitar pesquisas excessivas sem ganhos significativos
        hcIter = 0;
        while improved && toc(t) < timeLimit && hcIter < maxHCiters
            improved = false;
            hcIter = hcIter + 1;

            for f = 1:nFlows
                for p = 1:nSP(f)
                    if p ~= sol(f)
                        tempSol = sol;
                        tempSol(f) = p;

                        tempLoads = calcLinkLoads(nNodes,Links,T,sP,tempSol);

                        if all(tempLoads(:,3) <= upgrades) && all(tempLoads(:,4) <= upgrades)

                            tempE = energy_consumption_v3(L,tempLoads,upgrades,nNodes);
                            
                            if tempE < E
                                sol = tempSol;
                                Loads = tempLoads;
                                E = tempE;
                                W = max(max(Loads(:,3:4)));
                                improved = true;
                            end
                        end
                    end
                end
            end

            % Upgrade links
            for l = 1:nLinks
                if upgrades(l) == 50
                    tempUp = upgrades;
                    tempUp(l) = 100;

                    if all(Loads(:,3) <= tempUp) && all(Loads(:,4) <= tempUp)

                        tempE = energy_consumption_v3(L,Loads,tempUp,nNodes);

                        if tempE < E
                            upgrades = tempUp;
                            E = tempE;
                            improved = true;
                        end
                    end
                end
            end
        end

        % Register cycle
        noCycles = noCycles + 1;
        auxW = auxW + W;

        % Update best solution
        if E < bE
            bE = E;
            bSol = sol;
            bUpgrades = upgrades;
            bObjective = W;
            bTime = toc(t);
        end
    end

    avObjective = auxW / noCycles;
end


function sol = GreedyRandomizedSelection(nNodes,Links,T,sP,nSP)

    nFlows = size(T,1);
    sol = zeros(1,nFlows);

    flowOrder = randperm(nFlows);

    % calcular o melhor path para cada um dos fluxos, pela ordem random gerada
    for idx = 1:nFlows
        f = flowOrder(idx);

        bestLoad = inf;
        bestPath = 0;

        for p = 1:nSP(f)
            tempSol = sol;
            tempSol(f) = p;

            % verificar se o pior Load melhora , se sim escolher path
            tempLoads = calcLinkLoads(nNodes,Links,T,sP,tempSol);
            tempLoadVal = max(max(tempLoads(:,3:4)));

            % capacity constraint (base capacity = 50)
            if tempLoadVal <= 50
                if tempLoadVal < bestLoad
                    bestLoad = tempLoadVal;
                    bestPath = p;
                end
            end
        end

        % garantir que vai ter sempre um caminho (1o)
        if bestPath == 0
            return;
        end

        % Atribui o melhor caminho encontrado, ao fluxo certo
        sol(f) = bestPath;
    end
end


function E = energy_consumption_v3(L, Loads, C, nNodes)
% C(i) = capacidade do link i (50 ou 100)
    E = 0;

    nLinks = size(Loads,1);
    routerLoad = zeros(nNodes,1);

    for i = 1:nLinks
        node1 = Loads(i,1);
        node2 = Loads(i,2);
        linkLoad = Loads(i,3) + Loads(i,4);

        % --- Link Energy ---

        if linkLoad > 0
            if C(i) == 50
                E = E + 6 + 0.2 * L(node1,node2);
            else % 100 Gbps
                E = E + 8 + 0.3 * L(node1,node2);
            end
        else
            % sleeping
            E = E + 2;
        end

        % --- Router Energy ---

        routerLoad(node1) = routerLoad(node1) + linkLoad;
        routerLoad(node2) = routerLoad(node2) + linkLoad;
    end

    for n = 1:nNodes
        t = routerLoad(n) / 500;   % capacity 500 Gbps
        En = 10 + 90 * t^2;
        E = E + En;
    end
end
