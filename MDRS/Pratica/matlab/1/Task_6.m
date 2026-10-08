% considera uma ligação ponto a ponto com um ber de 10^-5 a partir de um
% router para outro router com uma capacidade de C Mbps para comunicações
% IP. há uma fila muito grande no porto de output desta ligação. a ligação
% tem um delay de propagação de 10 microsegundos

% a ligação suporta um fluxo
% de pacotes IP cujos tamanhos variam entre 64 e 1518 bytes com
% probabilidades de 19% para 64 bytes, 23% para 110 bytes e 17% para 1518
% bytes e iguais probabilidades para todos os outros tamanhos.
% as chegadas dos pacotes são um processo de poisson com frequencia x pps

% considera que x = 18000 pps e C = 100 Mbps

% 6.a 
% determine o tamanho médio de um pacote do fluxo em bytes

packetSizes = 64:1518;
probabilities = ones(size(packetSizes)) * (0.41 / (numel(packetSizes) - 3));
probabilities(ismember(packetSizes, [64, 110, 1518])) = [0.19, 0.23, 0.17];
meanPacketSize = sum(packetSizes .* probabilities)

% 6.b 
% determina a packet loss rate em % da ligação

ber = 1e-5;
x = 18000;
C = 100e6;

packetErrorProbabilities = 1 - (1 - ber).^(8 * packetSizes);
packetLossRate = 100 * sum(probabilities .* packetErrorProbabilities)

% 6.c 
% determina a packet loss rate em percentagem da ligação considerando
% apenas o tamanho medio de pacote determinado em 6.a

meanPacketErrorProbability = 1 - (1 - ber)^(8 * meanPacketSize);
meanPacketLossRate = 100 * meanPacketErrorProbability

% 6.d 
% determina o throughput e o goodput da ligação em Mbps

throughput = x * sum(probabilities .* packetSizes) * 8 / 1e6
goodput = x * sum(probabilities .* packetSizes .* ...
    (1 - packetErrorProbabilities)) * 8 / 1e6

% 6.e 
% determina o system delay medio de um pacote no fluxo de IP em
% milisegundos

propagationDelay = 10e-6;
serviceRate = C ./ (8 * packetSizes);
meanServiceTime = sum(probabilities ./ serviceRate);
arrivalRate = x;
utilization = arrivalRate * meanServiceTime;
queueingDelay = arrivalRate * sum(probabilities .* (1 ./ serviceRate).^2) / (2 * (1 - utilization));
systemDelay = 1000 * (propagationDelay + meanServiceTime + queueingDelay)

