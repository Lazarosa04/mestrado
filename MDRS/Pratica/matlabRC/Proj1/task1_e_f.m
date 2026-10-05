%% 1 e)

% Consider the case of 1.d modelled by an M/G/1 queueing model. 
% Develop a MATLAB script to determine the theoretical values of the average
% packet loss and average packet delay for all packets and for each of the 
% 3 special packet sizes

f = 1e6;
lambda = 1900;
C = 10;

P_size = [64, 110, 1518];
probs = [0.19, 0.23, 0.17];  % conforme a função GenerateDataPacketSize

P_others = [65:109, 111:1517];
probs_others = (1 - sum(probs)) / length(P_others);

% formula :
% (lambda * E[s^2]) / (2 * (1 - lambda * E[s]))

% E[s]   = mean_packet_size * 8 / C

mean_packet_size = sum(P_size .* probs) + sum(P_others .* probs_others);
E_s = mean_packet_size * 8 / (C * 1e6);

mean_packet_size2 = sum(P_size.^2 .* probs) + sum(P_others.^2 .* probs_others);
E_s2 = mean_packet_size2 * 8 * 8 / (C * 1e6)^2;

% Calculate the average packet delay
Wq = (lambda * E_s2) / (2 * (1 - lambda * E_s));    % espera média na fila (s)
Wq = Wq * 1000;                                     % (ms)
W = Wq + E_s;                                       % tempo total médio (ms)

W_64   = Wq + (64*8)/(C*1e6);
W_110  = Wq + (110*8)/(C*1e6);
W_1518 = Wq + (1518*8)/(C*1e6);

fprintf('Av. theoretical packet delay (ms) = %.4e\n', W);
fprintf('Av. packet delay (64 Bytes)       = %.4e\n', W_64);
fprintf('Av. packet delay (110 Bytes)      = %.4e\n', W_110);
fprintf('Av. packet delay (1518 Bytes)     = %.4e\n', W_1518);
fprintf('Packet loss (all)                 = 0%% (M/G/1 model)\n');


%%

% M/G/1 -> fila infinita (tem sempre espaço) -> no packet loss

% Av. Packet Delay são parecidos !!!
% Não são perfeitos, pq teoricos assume condições ideias
% No 'prático' é sujeita a flutuações de amostragem (valores 'random' nos simuladores).

% >> task_d
% PacketLoss_ALL              = 0.00e+00 +- 0.00e+00
% PacketLoss_64               = 0.00e+00 +- 0.00e+00
% PacketLoss_110              = 0.00e+00 +- 0.00e+00
% PacketLoss_1518             = 0.00e+00 +- 0.00e+00
% Av. Packet Delay (ms)_ALL   = 7.92e+00 +- 1.89e-01
% Av. Packet Delay (ms)_64    = 7.48e+00 +- 1.87e-01
% Av. Packet Delay (ms)_110   = 7.52e+00 +- 1.87e-01
% Av. Packet Delay (ms)_1518  = 8.63e+00 +- 1.95e-01 
% >> task_e
% Av. theoretical packet delay (ms) = 7.65e+00
% Av. packet delay (64 Bytes)       = 7.65e+00
% Av. packet delay (110 Bytes)      = 7.65e+00
% Av. packet delay (1518 Bytes)     = 7.65e+00
% Packet loss (all)                 = 0% (M/G/1 model)

%% 1 f)

% f = 1M Bytes
% PacketLoss_ALL              = 0.00e+00 +- 0.00e+00
% PacketLoss_64               = 0.00e+00 +- 0.00e+00
% PacketLoss_110              = 0.00e+00 +- 0.00e+00
% PacketLoss_1518             = 0.00e+00 +- 0.00e+00
% Av. Packet Delay (ms)_ALL   = 7.92e+00 +- 1.89e-01
% Av. Packet Delay (ms)_64    = 7.48e+00 +- 1.87e-01
% Av. Packet Delay (ms)_110   = 7.52e+00 +- 1.87e-01
% Av. Packet Delay (ms)_1518  = 8.63e+00 +- 1.95e-01 

% f = 10k Bytes
% PacketLoss_ALL              = 1.71e+00 +- 2.03e-02
% PacketLoss_64               = 1.22e-01 +- 7.11e-03
% PacketLoss_110              = 2.05e-01 +- 7.31e-03
% PacketLoss_1518             = 4.70e+00 +- 5.66e-02
% Av. Packet Delay (ms)_ALL   = 3.49e+00 +- 1.18e-02
% Av. Packet Delay (ms)_64    = 3.13e+00 +- 1.31e-02
% Av. Packet Delay (ms)_110   = 3.16e+00 +- 1.21e-02
% Av. Packet Delay (ms)_1518  = 4.07e+00 +- 1.10e-02

% f = 1M Bytes
% buffer é grande o suficiente para não encher -> packet loss 0
% o atraso é maior, porque todos os pacotes ficam à espera na fila (há espaço para todos)

% f = 1k Bytes
% o buffer é muito menor, então enche rapido o q provoca overflow
% só existe poucos pacotes na fila, então o tempo de espera médio é menor