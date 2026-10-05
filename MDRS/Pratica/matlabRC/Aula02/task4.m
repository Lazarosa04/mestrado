%% 4a

% M/G/1 -> chegadas Markovianas (Poisson) ;
%          tempos de serviço com distribuição Geral (porque os tamanhos dos pacotes variam, não é fixo).
%          um único servidor (o link de 10 Mbps).
%          queue infinito.

% the average packet size (in Bytes) and the average packet transmission
% time of the IP flow ?

lambda = 1000;
C = 10*1e6;

% 19% for 64 bytes, 23% for 110 bytes, 17% for 1518 bytes and an equal 
% probability for all other values (i.e., from 65 to 109 and from 111 to 1517)
size_fixed = [64, 110, 1518];
prob_fixed = [0.19, 0.23, 0.17];

size_others = [65:109, 111:1517];
prob_others = (1 - sum(prob_fixed)) / length(size_others);

% the average packet size (in Bytes)
mean_packet_size = sum(size_fixed .* prob_fixed) + sum(size_others .* prob_others);

% average packet transmission time of the IP flow
mean_transmission_time = (mean_packet_size * 8)/C;

fprintf('Tamanho médio do pacote: %.2f Bytes\n', mean_packet_size);
fprintf('Tempo médio de transmissao: %.2e s\n', mean_transmission_time);

%% 4b

% the average throughput (in Mbps) of the IP flow

% taxa média de bits efetivamente transmitidos pelo link por segundo
% lambda -> taxa média de pacotes por segundo
throughput_bps = lambda * mean_packet_size * 8;

fprintf('Throughput medio do fluxo: %.2f Mbps\n', throughput_bps/1e6);

%% 4c

% the capacity of the link, in packets/second

link_capacity_pps = C / (mean_packet_size * 8);

fprintf('Capacidade do link: %.2f pacotes/segundo\n', link_capacity_pps);

%% 4d

% the average packet queuing delay and average packet system delay of the IP flow
% (the system delay is the queuing delay + transmission time + propagation delay) 
% using the M/G/1 queuing model

% lambda * E[S^2] / 2 * (1 - lambda*E[S])

mean_packet_size2 = sum(size_fixed.^2 .* prob_fixed) + sum(size_others.^2 .* prob_others);

% Tempo médio de serviço
S_bar = mean_packet_size * 8 / C;

% Segunda momento do tempo de serviço
S2_bar = 8*8 * mean_packet_size2 / C^2;

% Utilização
rho = lambda * S_bar;

% Atraso médio na fila (M/G/1)
Wq = (lambda * S2_bar) / (2 * (1 - rho));

% Atraso médio no sistema
t_prop = 10e-6;
W = Wq + S_bar + t_prop;

% Resultados
fprintf('Atraso medio na fila: %.2e s\n', Wq);
fprintf('Atraso medio no sistema: %.2e s\n', W);


%% 4e

% draw a plot with the same look as the plot below with the average packet 
% system delay as a function of the packet arrival rate lambda
% (from y = 100 pps up to y = 2000 pps)

lambda_vec = 100:100:2000; % pps

% Inicializa vetor de atrasos
W_system = zeros(size(lambda_vec));

% Calcula W para cada lambda
for i = 1:length(lambda_vec)
    rho = lambda_vec(i) * S_bar;
    Wq = (lambda_vec(i) * S2_bar) / (2 * (1 - rho));
    W_system(i) = Wq + S_bar + t_prop;
end

% Plot
figure;
plot(lambda_vec, W_system*1e3); % Convertendo para ms
grid on;
xlabel('Taxa de chegada de pacotes \lambda (pps)');
ylabel('Atraso médio do sistema W (ms)');
title('Atraso médio do sistema vs taxa de chegada de pacotes');