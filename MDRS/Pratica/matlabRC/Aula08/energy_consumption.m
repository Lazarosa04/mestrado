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
