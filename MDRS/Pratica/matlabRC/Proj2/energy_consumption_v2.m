function E = energy_consumption_v2(L, Loads, C, nNodes)
    E = 0;

    nLinks = size(Loads,1);
    routerLoad = zeros(nNodes, 1);
    
    for i = 1:nLinks
        % verificar se está operacional (>0)
        node1 = Loads(i,1);
        node2 = Loads(i,2);
        linkLoad = Loads(i,3) + Loads(i,4);

        % --- Link Energy ---
        
        if linkLoad > 0
            % Se operacional
            if C == 50
                % 50 Gbps
                E = E + 6 + 0.2 * L(node1, node2);
            else
                % 100 Gbps
                E = E + 8 + 0.3 * L(node1, node2);
            end
        else
            % else -> 2
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

