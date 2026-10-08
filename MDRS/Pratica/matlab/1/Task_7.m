% considera uma ligação
% ponto a ponto ideal de um router para outro com uma capacidade de C Gbps
% para comunicação IP
% há uma fila muito grande no porto de output da ligação
% a ligação tem um delay de propagação de 1 microsegundo

% a ligação suporta 2 fluxos de pacotes IP
% os tamanhos dos pacotes do fluxo 1 variam entre 64 e 200 bytes
% os tamanhos dos pacotes do fluxo 2 variam entre 100 e 1500 bytes
% processo de poisson com frequencia x para o fluxo 1 e y para o fluxo 2

% considera que x = 4*10^4 pps
% y = 1.4*10^5 pps
% C = 1 Gbps

% 7.a
% considera a variavel aleatoria S que representa o tempo de transmissão
% agregado dos dois fluxos de IP
% determina a media E[S] e o segundo momento E[S^2]

x = 4e4;
y = 1.4e5;
C = 1e9;

L1 = 64:200;
L2 = 100:1500;

p1 = x / (x + y);
p2 = y / (x + y);

E_L  = p1 * mean(L1) + p2 * mean(L2);
E_L2 = p1 * mean(L1.^2) + p2 * mean(L2.^2);

E_S  = 8 * E_L / C
E_S2 = (8 / C)^2 * E_L2

% 7.b
% determina o delay de sistema medio de um pacote no fluxo 1 quando ambos
% os fluxos estão estatisticamente multiplexados na ligação

lambda = x + y;
rho = lambda * E_S;

Wq = lambda * E_S2 / (2 * (1 - rho));
E_S1 = 8 * mean(L1) / C;
D1 = Wq + E_S1 + 1e-6

D1_us = D1 * 1e6

% 7.c
% determina o delay de sistema medio de um pacote do fluxo 1 quando 50 Mbps
% da ligação estão a ser usados no fluxo 1

C1 = 50e6;
ES_queue = mean(L1) * 8 / C1;
rho1_50 = x * ES_queue;
Wq1_50 = (rho1_50 / (1 - rho1_50)) * ES_queue;
transmission_time_wire = mean(L1) * 8 / C;
D1_50 = Wq1_50 + transmission_time_wire + 1e-6;
D1_50_us = D1_50 * 1e6

% 7.d
% determina o delay de sistema medio de um pacote do fluxo 1 quando 100
% Mbps da ligação estão a ser usados no fluxo 1

C1 = 100e6;
ES_queue = mean(L1) * 8 / C1;
rho1_50 = x * ES_queue;
Wq1_50 = (rho1_50 / (1 - rho1_50)) * ES_queue;
transmission_time_wire = mean(L1) * 8 / C;
D1_50 = Wq1_50 + transmission_time_wire + 1e-6;
D1_50_us = D1_50 * 1e6

% 7.e
% desenha um grafico com o delay de sistema medio de um pacote do fluxo 1
% quando são nele utilizados 50, 75, 100, 125 e 150 Mbps

C1_values = (50:25:150) * 1e6;
ES_queue = mean(L1) * 8 ./ C1_values;
rho1 = x .* ES_queue;
Wq1 = rho1 ./ (1 - rho1) .* ES_queue;
D1_values = (Wq1 + mean(L1) * 8 / C + 1e-6) * 1e6;

figure;
bar(C1_values / 1e6, D1_values/1000);
xlabel('Capacidade atribuída ao fluxo 1 (Mbps)');
ylabel('Delay médio de sistema (\mus)');
title('Delay médio do fluxo 1');
grid on;