% considera uma ligação ideal
% ponto a ponto (i.e com ber de 0) de um router para outro router com
% capacidade C Mbps para comunicaçãoes ip
% há uma fila muito grande no
% port output da ligação, a
% ligação tem um delay de propagação de 10 micro segundos

% a ligação suporta um fluxo de pacotes ip cujos tamanhos estão entre 64 e
% 1518 bytes com as probabilidades sendo 19% para 64bytes, 23% 110 bytes,
% 17% para 1518 bytes e uma probabilidade igual para todos os outros
% valores. as chegadas dos
% pacotes de ip são um processo de poisson com uma frequencia x pps

% Considera que x = 1500 pps (pacotes por segundo) e C = 10 Mbps

% 5.a
% determina o tamanho medio de um pacote em bytes e o tempo de transmissão
% medio de um pacote em milisegundos

x = 1500;          % pacotes por segundo
C = 10e6;          % capacidade da ligação, em bits por segundo

tamanhos = 64:1518;
probabilidades = ones(size(tamanhos)) * (1 - 0.19 - 0.23 - 0.17) / (numel(tamanhos) - 3);

probabilidades(tamanhos == 64) = 0.19;
probabilidades(tamanhos == 110) = 0.23;
probabilidades(tamanhos == 1518) = 0.17;

tamanho_medio = sum(tamanhos .* probabilidades);
tempo_transmissao_medio = tamanho_medio * 8 / C;
tempo_transmissao_medio_ms = tempo_transmissao_medio * 1e3;
fprintf('Tempo de transmissao medio: %.2f milissegundos\n', ...
    tempo_transmissao_medio_ms);
fprintf('Tamanho medio do pacote: %.2f bytes\n', tamanho_medio);

% 5.b
% determina o throughput em Mbps da ligação

throughput_Mbps = min(x * tamanho_medio * 8 / 1e6, C / 1e6);
fprintf('Throughput da ligacao: %.2f Mbps\n', throughput_Mbps);

% 5.c
% determina a capacidade da ligação em pacotes por segundo

capacidade_pps = C / (tamanho_medio * 8);
fprintf('Capacidade da ligacao: %.2f pacotes por segundo\n', capacidade_pps);

% 5.d 
% determine o queuing delay medio de um pacote e o packet system delay
% medio do fluxo IP (o system delay é o queuing delay + tempo de 
% transmissão + delay de propagação)
% usando o queuing model M/G/1

rho = x / capacidade_pps;
variancia_tamanho = sum((tamanhos - tamanho_medio).^2 .* probabilidades);
segundo_momento_servico = (variancia_tamanho + tamanho_medio^2) * (8 / C)^2;
queuing_delay_ms = (x * segundo_momento_servico / (2 * (1 - rho))) * 1e3;
system_delay_ms = queuing_delay_ms + tempo_transmissao_medio_ms + 0.01;
fprintf('Queuing delay medio: %.4f ms\nSystem delay medio: %.4f ms\n', ...
    queuing_delay_ms, system_delay_ms);

% 5.e
% igual à alínea anterior mas com o modelo M/M/1

tempo_servico_exponencial = tempo_transmissao_medio;
queuing_delay_mm1_ms = (rho * tempo_servico_exponencial / (1 - rho)) * 1e3;
system_delay_mm1_ms = queuing_delay_mm1_ms + tempo_transmissao_medio_ms + 0.01;
fprintf('Queuing delay M/M/1: %.4f ms\nSystem delay M/M/1: %.4f ms\n', ...
    queuing_delay_mm1_ms, system_delay_mm1_ms);

% 5.f
% usando o modelo M/M/1 determina a probabilidade da ocupação da queue ser
% maior que P pacotes para P = 10, 20 e 30

P = [10 20 30];
probabilidade_queue_maior = rho .^ (P + 2);

fprintf('Probabilidade da ocupacao da queue ser maior que %d pacotes: %.3f%%\n', ...
    [P; 100 * probabilidade_queue_maior]);

% 5.g 
% desenha um grafico com a média do delay de sistema usando o modelo M/G/1
% (de 10 em 10 milisegundos)
% em função da arrival rate dos pacotes desde 500pps até 2000pps.

taxas = 500:10:2000;
rho_taxas = taxas / capacidade_pps;
queuing_delay_taxas_ms = ...
    (taxas * segundo_momento_servico ./ (2 * (1 - rho_taxas))) * 1e3;
system_delay_taxas_ms = queuing_delay_taxas_ms + ...
    tempo_transmissao_medio_ms + 0.01;

figure;
plot(taxas, system_delay_taxas_ms, 'LineWidth', 1.5);
grid on;
xlabel('Taxa de chegada (pacotes por segundo)');
ylabel('Delay médio do sistema (ms)');
title('Delay médio do sistema - Modelo M/G/1');