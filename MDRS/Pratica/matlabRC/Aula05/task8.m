% Ex 8

% for f = 1:randperm(nFlows) -> random de for f=1:nFlows -> IMPORTANTE !!!

% Consider the MPLS (Multi-Protocol Label Switching) network of an ISP (Internet Service
% Provider) with a topology defined over a rectangle with 600 Km by 300 Km as follows:
% Consider that all links of the network have a capacity of 10 Gbps:
% • The coordinates of the nodes are provided by matrix Nodes with the number of rows equal
% to the number of nodes and 2 columns (column 1 with the horizontal coordinate and column
% 2 with the vertical coordinate).
% • The list of links is provided by matrix Links with the number of rows equal to the number
% of links and 2 columns (with the end nodes of each link).
% • The capacity of the links is provided by square matrix C, where C(i,j) is either the capacity
% of arc (i,j) if it exists or is 0 if arc (i,j) does not exist.
% • The length of the links is provided by the square matrix L, where L(i,j) is either the length
% (in Km) of arc (i,j) if it exists or is +∞ if arc (i,j) does not exist.
% The network supports a unicast service with the following traffic flows (throughput values bt
% and bt in Gbps):
% t ot dt bt bt
% 1 1 3 1.0 1.0
% 2 1 4 0.7 0.5
% 3 2 7 3.4 2.5
% 4 3 4 2.4 2.1
% 5 4 9 2.0 1.4
% 6 5 6 1.2 1.5
% 7 5 8 2.1 2.7
% 8 5 9 2.6 1.9
% The provided matrix T contains the information of all traffic flows: row t defines traffic flow t
% with origin node 𝑜𝑡 given by T(t,1), destination node 𝑑𝑡 given by T(k,2), average throughput
% from origin to destination 𝑏𝑘 (in Gbps) given by T(k,3) and average throughput from destination
% to origin 𝑏𝑡
% (in Gbps) given by T(t,4).
% To load the input matrices, run on your MATLAB script: load('InputData.mat')

%% a)
% Determine the shortest path provided by the network to each traffic flow. Present the
% length and the sequence of nodes of each path.

load("C:\Users\Ruben\Documents\MATLAB\MATLABcodes1\InputData.mat")
nNodes= size(Nodes,1);
nLinks= size(Links,1);
nFlows= size(T,1);
addpath('C:\Users\Ruben\Documents\MATLAB\MATLABcodes1')

% shortest path -> k=1
k= 1;
for f = 1:nFlows
    [shortestPath, totalCost] = kShortestPath(L,T(f,1),T(f,2),k);
    last = length(shortestPath{1});
    fprintf('Flow %d (%d -> %d): length= %.1f, Path = %s  \n\n',f,shortestPath{1}(1), shortestPath{1}(last),totalCost(1), num2str(shortestPath{1}));
end

%% b)
% Determine the worst link load and the link loads of all links when all traffic flows are
% routed through the shortest path provided by the network.

k= 1;
sP= cell(1,nFlows);
nSP= zeros(1,nFlows);
for f=1:nFlows
    [shortestPath, totalCost] = kShortestPath(L,T(f,1),T(f,2),k);
    sP{f}= shortestPath;
    nSP(f)= length(totalCost);
end
% sP{f}{i} is the i-th path of flow f
% nSP(f) is the number of paths of flow f

% Compute the link loads using the first (shortest) path of each flow:
sol= ones(1,nFlows);
Loads= calcLinkLoads(nNodes,Links,T,sP,sol);
% Determine the worst link load:
maxLoad= max(max(Loads(:,3:4)));
fprintf("Worst link load = %.2f \n", maxLoad);

% Visualizing Loads (nó chegada - saida : custo)
nLoads = size(Loads,1);
for f = 1:nLoads
    fprintf("{%d -> %d}:  %.2f  %.2f \n", Loads(f,1), Loads(f,2), Loads(f,3), Loads(f,4));
end

%% c)
% Determine the k = 4 shortest paths provided by the network for traffic flow 1. Present the
% length and the sequence of nodes of each path.

k = 4;
f = 1;
[shortestPath, totalCost] = kShortestPath(L, T(f, 1), T(f, 2), k);
for f = 1:length(shortestPath)
    fprintf("Path %d = %s (length = %d) \n", f, num2str(shortestPath{f}), totalCost(f));
end

%% d)
% Consider the determination of a symmetrical single routing path solution with minimum
% worst link load. Run the provided optimization algorithm based on the random strategy.
% Consider a runtime limit of 5 seconds and all possible routing paths for each flow. Present
% the assigned routing paths, the resulting link loads, and the performance parameters of the
% algorithm. Compare the worst link load values of this solution and the solution of 8.b.

% rever q isto ta mal muito prob
timeLimit= 5;
k= inf;
sP= cell(1,nFlows);
nSP= zeros(1,nFlows);
for f=1:nFlows
    [shortestPath, totalCost] = kShortestPath(L,T(f,1),T(f,2),k);
    sP{f}= shortestPath;
    nSP(f)= length(totalCost);
end
[bestSol,bestLoad,noCycles,avObjective,bestTime] = RandomAlgorithm(nNodes,Links,T,sP,nSP,timeLimit);

%Output of routing solution:
fprintf('\nRouting paths of the solution:\n')
for f= 1:nFlows
    selectedPath= bestSol(f);
    fprintf('Flow %d - Path %d:  %s\n',f,selectedPath,num2str(sP{f}{selectedPath}));
end
bestLoads= calcLinkLoads(nNodes,Links,T,sP,bestSol);
%Output of link loads of the routing solution:
fprintf('Worst link load of the best solution = %.2f\n',bestLoad);
fprintf('Link loads of the best solution:\n')
for i= 1:nLinks
    fprintf('{%d-%d}:\t%.2f\t%.2f\n',bestLoads(i,1),bestLoads(i,2),bestLoads(i,3),bestLoads(i,4))
end

%Output of performace values:
fprintf('No. of generated solutions = %d\n',noCycles);
fprintf('Avg. worst link load among all solutions= %.2f\n',avObjective);
fprintf('Running time of the best solution= %.2f\n',bestTime);

% então nesta alínea em vez de só usar 1 caminho, são usados vários, assim
% evita sobrecarregar o caminho 5 -> 7, o q faz o worst link diminuir
% drasticamente

%% e) 
% Repeat task 8.d but now considering only the 6 shortest routing paths as candidate paths
%for each flow. Compare the worst link load values of this solution and the solution of 8.d.

timeLimit= 5;
k= 6;
sP= cell(1,nFlows);
nSP= zeros(1,nFlows);
for f=1:nFlows
    [shortestPath, totalCost] = kShortestPath(L,T(f,1),T(f,2),k);
    sP{f}= shortestPath;
    nSP(f)= length(totalCost);
end
[bestSol,bestLoad,noCycles,avObjective,bestTime] = RandomAlgorithm(nNodes,Links,T,sP,nSP,timeLimit);

%Output of routing solution:
fprintf('\nRouting paths of the solution:\n')
for f= 1:nFlows
    selectedPath= bestSol(f);
    fprintf('Flow %d - Path %d:  %s\n',f,selectedPath,num2str(sP{f}{selectedPath}));
end
bestLoads= calcLinkLoads(nNodes,Links,T,sP,bestSol);
%Output of link loads of the routing solution:
fprintf('Worst link load of the best solution = %.2f\n',bestLoad);
fprintf('Link loads of the best solution:\n')
for i= 1:nLinks
    fprintf('{%d-%d}:\t%.2f\t%.2f\n',bestLoads(i,1),bestLoads(i,2),bestLoads(i,3),bestLoads(i,4))
end

%Output of performace values:
fprintf('No. of generated solutions = %d\n',noCycles);
fprintf('Avg. worst link load among all solutions= %.2f\n',avObjective);
fprintf('Running time of the best solution= %.2f\n',bestTime);

% entao fica melhor ter 6 do q ter todos os caminhos possiveis, pq nesse
% caso, ele encontra caminhos curtos, mas tb caminhos longos que usam os mesmos
% links, então acaba a causar mais congestionamento que no caso de só ter
% os melhores 6

%% g )
% Run the optimization algorithm developed in 8.f with a runtime limit of 5 seconds and
% considering all possible routing paths for each flow. Compare these results with the ones
% obtained in tasks 8.d and 8.e.

timeLimit= 5;
k= inf;
sP= cell(1,nFlows);
nSP= zeros(1,nFlows);
for f=1:nFlows
    [shortestPath, totalCost] = kShortestPath(L,T(f,1),T(f,2),k);
    sP{f}= shortestPath;
    nSP(f)= length(totalCost);
end
[bestSol,bestLoad,noCycles,avObjective,bestTime] = GreedyRandomizedAlgorithm(nNodes,Links,T,sP,nSP,timeLimit);

%Output of routing solution:
fprintf('\nRouting paths of the solution:\n')
for f= 1:nFlows
    selectedPath= bestSol(f);
    fprintf('Flow %d - Path %d:  %s\n',f,selectedPath,num2str(sP{f}{selectedPath}));
end
bestLoads= calcLinkLoads(nNodes,Links,T,sP,bestSol);
%Output of link loads of the routing solution:
fprintf('Worst link load of the best solution = %.2f\n',bestLoad);
fprintf('Link loads of the best solution:\n')
for i= 1:nLinks
    fprintf('{%d-%d}:\t%.2f\t%.2f\n',bestLoads(i,1),bestLoads(i,2),bestLoads(i,3),bestLoads(i,4))
end

%Output of performace values:
fprintf('No. of generated solutions = %d\n',noCycles);
fprintf('Avg. worst link load among all solutions= %.2f\n',avObjective);
fprintf('Running time of the best solution= %.2f\n',bestTime);

% entao average wort link ficou melhor, em relaçao as alineas anteriores
% o worst tava igual a alinea anterior

%% h )
% Repeat task 8.g but now considering only the 6 shortest paths as candidate paths for each
% flow. Compare these results with the ones obtained in tasks 8.d, 8.e and 8.g. 

timeLimit= 5;
k= 6;
sP= cell(1,nFlows);
nSP= zeros(1,nFlows);
for f=1:nFlows
    [shortestPath, totalCost] = kShortestPath(L,T(f,1),T(f,2),k);
    sP{f}= shortestPath;
    nSP(f)= length(totalCost);
end
[bestSol,bestLoad,noCycles,avObjective,bestTime] = GreedyRandomizedAlgorithm(nNodes,Links,T,sP,nSP,timeLimit);

%Output of routing solution:
fprintf('\nRouting paths of the solution:\n')
for f= 1:nFlows
    selectedPath= bestSol(f);
    fprintf('Flow %d - Path %d:  %s\n',f,selectedPath,num2str(sP{f}{selectedPath}));
end
bestLoads= calcLinkLoads(nNodes,Links,T,sP,bestSol);
%Output of link loads of the routing solution:
fprintf('Worst link load of the best solution = %.2f\n',bestLoad);
fprintf('Link loads of the best solution:\n')
for i= 1:nLinks
    fprintf('{%d-%d}:\t%.2f\t%.2f\n',bestLoads(i,1),bestLoads(i,2),bestLoads(i,3),bestLoads(i,4))
end

%Output of performace values:
fprintf('No. of generated solutions = %d\n',noCycles);
fprintf('Avg. worst link load among all solutions= %.2f\n',avObjective);
fprintf('Running time of the best solution= %.2f\n',bestTime);

% resultado parecido a alinea anterior

% mais facil encontrar melhor soluçao em greedy e melhor avg link load, com
% menores soluçoes geradas, pois greedy tenta melhorar a soluçao inicial

% já o random tenta valores random até conseguir algo satisfatorio, nem
% sempre é o valor melhor, muitas vezes são soluçoes piores, como se pode
% ver pelo avg link load

% quanto menos caminhos, mais rapido se acha soluçao, pq só são mostrados
% os melhores caminhos em cada caso

% alinea h) -> (greedy 6)
% Worst link load of the best solution = 5.10
% No. of generated solutions = 23068
% Avg. worst link load among all solutions= 6.08
% Running time of the best solution= 0.00

% alinea g) -> (greedy inf)
% Worst link load of the best solution = 5.10
% No. of generated solutions = 11025
% Avg. worst link load among all solutions= 6.01
% Running time of the best solution= 0.02

% aliena e) -> (random 6)
% Worst link load of the best solution = 5.10
% No. of generated solutions = 637269
% Avg. worst link load among all solutions= 9.26
% Running time of the best solution= 0.53

% alinea d) -> (random inf)
% Worst link load of the best solution = 5.40
% No. of generated solutions = 597449
% Avg. worst link load among all solutions= 10.19
% Running time of the best solution= 0.59