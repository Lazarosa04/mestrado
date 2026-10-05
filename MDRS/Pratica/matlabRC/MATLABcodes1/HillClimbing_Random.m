function [bSol,bObjective,noCycles,avObjective,bTime] = HillClimbing_Random(nNodes,Links,T,sP,nSP,timeLimit)

    t = tic;
    nFlows = size(T,1);
    noCycles = 0;
    aux = 0;
    bObjective = inf;

    while toc(t) < timeLimit
        
        % random algorithm
        sol = RandomSelection(nFlows, nSP);
        Loads = calcLinkLoads(nNodes, Links, T, sP, sol);
        solObj = max(max(Loads(:,3:4)));

        % Hill Climbing
        improved = true;
        while improved && toc(t) < timeLimit
            improved = false;
            
            % para cada um dos fluxos
            for f = 1:nFlows
                % ve para cada um dos seus caminhos
                for p = 1:nSP(f)
                    % verifica se é um caminho diferente
                    if p ~= sol(f)
                        % assume como possivel solução
                        tempSol = sol;
                        tempSol(f) = p;
                        
                        tempLoads = calcLinkLoads(nNodes, Links, T, sP, tempSol);
                        tempObj = max(max(tempLoads(:,3:4)));
                        
                        % verifica se melhorou se sim, aceita
                        if tempObj < solObj
                            sol = tempSol;
                            solObj = tempObj;
                            improved = true;
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
        end
    end

    avObjective = aux / noCycles;
end

function sol= RandomSelection(nFlows,nSP)
    sol= zeros(1,nFlows);
    for f= 1:nFlows
        % for flow f, a candidate routing path is selected at random:
        sol(f)= randi(nSP(f));
    end
end