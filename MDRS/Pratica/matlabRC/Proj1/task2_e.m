%% 2 d)

% Develop a MATLAB script to determine the theoretical value
% of the total throughput for each of the cases defined in 2.b.

% M/G/1 + bit error

f = 1e6;
lambda = 1500;     % pps (data)
C = 10;            % Mbps
b = 1e-5;
nFlows = [10, 20, 30, 40];

% Data packet sizes
P_size = [64, 110, 1518];
probs = [0.19, 0.23, 0.17];

P_others = [65:109, 111:1517];
probs_others = (1 - sum(probs)) / length(P_others);

sizes_data = [P_size, P_others];
% repmat repete prob_other length(P_other) vezes -> para o tamanho do
% sizes_data bater com o do probs_data
probs_data = [probs, repmat(probs_others, 1, length(P_others))];

% VoIP packet sizes
sizes_voip = 110:130;
% cria vetor de 1's / numero de pacotes = prob de cada 1 em cada celula
probs_voip = ones(1, length(sizes_voip)) / length(sizes_voip);

% Mean packet sizes
% mean_packet_size_data = sum(sizes_data .* probs_data);
% mean_packet_size_voip = sum(sizes_voip .* probs_voip);

% Prob of successful transmission por packet size
succ_data = (1 - b).^(8 .* sizes_data);
succ_voip = (1 - b).^(8 .* sizes_voip);

% Expected successful por packet size
mean_packet_size_succ_data = sum(sizes_data .* probs_data .* succ_data);
mean_packet_size_succ_voip = sum(sizes_voip .* probs_voip .* succ_voip);

% VoIP per-flow packet rate
% 0.016 + 0.008 × rand(0,1) = 0.016 + 0.008 × 0.5 = 0.02
% lambda = 1 / tempo de envio médio
lambda_voip_per_flow = 1 / 0.02;  % = 50 pps (média do simulador)

TT_teorico = zeros(size(nFlows));

for i = 1:length(nFlows)
    n = nFlows(i);
    lambda_voip = n * lambda_voip_per_flow;
    
    % Total throughput in Mbps
    TT_Mbps = (lambda * mean_packet_size_succ_data * 8 + lambda_voip * mean_packet_size_succ_voip * 8) / 1e6;
    
    % Limit by link capacity
    TT_teorico(i) = min(TT_Mbps, C);
end

fprintf('nFlows   TT_theoretical (Mbps)\n');
for i = 1:length(nFlows)
    fprintf('%5d       %12.6f\n', nFlows(i), TT_teorico(i));
end