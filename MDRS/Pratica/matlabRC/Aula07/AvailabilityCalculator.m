function availabity = AvailabilityCalculator(shortestPath, A)
    comp = length(shortestPath);
    availabity = 1;
    % para noo penultimo pq o ultimo nao tem par
    for index = 1:comp - 1
        availabity = availabity * A(shortestPath(index), shortestPath(index + 1));
    end
end