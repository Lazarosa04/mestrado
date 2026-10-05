%% 5a -> 10 +=- 5b -> 100

% script to run Simulator1 10 times with a stopping criterion of P = 10000 
% at each run and to compute the estimated values and the 90% confidence 
% intervals of all performance parameters when lambda = 1800 pps, C = 10 Mbps 
% and f = 1.000.000 Bytes

lambda = 1800;
C = 10e6;
f = 1e6;
P = 1e4;
confidence = 0.9;

N = 100;
per_pl= zeros(1,N);
per_apd= zeros(1,N);
per_mpd= zeros(1,N);
per_tt= zeros(1,N);

alfa= 0.1; %90% confidence interval%

for index = 1:N
    [per_pl(index), per_apd(index), per_mpd(index), per_tt(index)] = Simulator1(lambda, C, f, P);
end

media = mean(per_pl);
term = norminv(1-alfa/2)*sqrt(var(per_pl)/N);
fprintf('PacketLoss             = %.2e +- %.2e\n',media,term);
media = mean(per_apd);
term = norminv(1-alfa/2)*sqrt(var(per_apd)/N);
fprintf('Av. Packet Delay (ms)  = %.2e +- %.2e\n',media,term);
media = mean(per_mpd);
term = norminv(1-alfa/2)*sqrt(var(per_mpd)/N);
fprintf('Max. Packet Delay (ms) = %.2e +- %.2e\n',media,term);
media = mean(per_tt);
term = norminv(1-alfa/2)*sqrt(var(per_tt)/N);
fprintf('Throughput (Mbps)      = %.2e +- %.2e\n',media,term);

%% 5c

% Consider system modelled by an M/G/1 queueing model1. Determine the theoretical values 
% of the packet loss, average packet delay and total throughput using the M/G/1 model 
% for the parameters considered in experiments 5.a and 5.b. 
% Compare these values with the simulation results of experiments 5.a and 5.b 
% and take conclusions.

% Probabilidades de cada tamanho de pacote
size_fixed = [64, 110, 1518];
prob_fixed = [0.19, 0.23, 0.17];

size_others = [65:109, 111:1517];
prob_others = (1 - sum(prob_fixed)) / length(size_others);

% Média do tamanho do pacote
mean_packet_size = sum(size_fixed .* prob_fixed) + sum(size_others .* prob_others);

mean_packet_size2 = sum(size_fixed.^2 .* prob_fixed) + sum(size_others.^2 .* prob_others);

% tempo médio de transmissão de um pacote
S_bar = mean_packet_size * 8 / C;

% tempo médio de transmissão de um pacote ** 2
S2_bar = (8^2 * mean_packet_size2) / C^2;

rho = lambda * S_bar;

% Atraso médio na fila (M/G/1)
Wq = (lambda * S2_bar) / (2 * (1 - rho));

% atraso total = tempo de espera + o tempo de serviço
W = Wq + S_bar;

% Throughput teórico (em Mbps)
TT_teorico = min(lambda * mean_packet_size * 8 * 1e-6, C*1e-6);

% Packet loss (teórico M/G/1) = 0%
PL_teorico = 0;

fprintf("\n---- Resultados Teóricos (M/G/1) ----\n");
fprintf("Packet Loss (%%)        = %.4f\n", PL_teorico);
fprintf("Av. Packet Delay (ms)  = %.4f\n", W*1000);
fprintf("Throughput (Mbps)      = %.4f\n", TT_teorico);

%% 5d

% new frequency = 1e4
new_f =1e4;

for index = 1:N
    [per_pl(index), per_apd(index), per_mpd(index), per_tt(index)] = Simulator1(lambda, C, new_f, P);
end

media = mean(per_pl);
term = norminv(1-alfa/2)*sqrt(var(per_pl)/N);
fprintf('PacketLoss             = %.2e +- %.2e\n',media,term);
media = mean(per_apd);
term = norminv(1-alfa/2)*sqrt(var(per_apd)/N);
fprintf('Av. Packet Delay (ms)  = %.2e +- %.2e\n',media,term);
media = mean(per_mpd);
term = norminv(1-alfa/2)*sqrt(var(per_mpd)/N);
fprintf('Max. Packet Delay (ms) = %.2e +- %.2e\n',media,term);
media = mean(per_tt);
term = norminv(1-alfa/2)*sqrt(var(per_tt)/N);
fprintf('Throughput (Mbps)      = %.2e +- %.2e\n',media,term);

