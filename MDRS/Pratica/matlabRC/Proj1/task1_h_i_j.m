%% 1 h)

% Consider the case C = 10 Mbps, f = 1.000.000 Bytes and lambda =1900 pps. 
% Using Simulator1B, estimate by simulation the average packet loss and average
% packet delay, both performance parameters for all packets and for each of 
% the 3 special packet sizes

% f = 1e6;
f = 1e4;        % i)

lambda = 1900;
C = 10;
P = 1e5;

alfa = 0.1;

N = 50;
per_pl= zeros(1,N);
per_pl_64= zeros(1,N);
per_pl_110= zeros(1,N);
per_pl_1518= zeros(1,N);
per_apd= zeros(1,N);
per_apd_64= zeros(1,N);
per_apd_110= zeros(1,N);
per_apd_1518= zeros(1,N);
per_mpd= zeros(1,N);
per_tt= zeros(1,N);

for index = 1:N
    index
    [per_pl(index), per_pl_64(index), per_pl_110(index), per_pl_1518(index), per_apd(index), per_apd_64(index), per_apd_110(index), per_apd_1518(index), per_mpd(index), per_tt(index)] = Simulator1B(lambda, C, f, P);
end

% calcula as médias para pl e apd
media_pl = [mean(per_pl), mean(per_pl_64), mean(per_pl_110), mean(per_pl_1518)];
media_apd = [mean(per_apd), mean(per_apd_64), mean(per_apd_110), mean(per_apd_1518)];

% calcula os terms para pl e apd
term_pl_all = norminv(1-alfa/2)*sqrt(var(per_pl)/N);
term_pl_64 = norminv(1-alfa/2)*sqrt(var(per_pl_64)/N);
term_pl_110 = norminv(1-alfa/2)*sqrt(var(per_pl_110)/N);
term_pl_1518 = norminv(1-alfa/2)*sqrt(var(per_pl_1518)/N);

term_apd_all = norminv(1-alfa/2)*sqrt(var(per_apd)/N);
term_apd_64 = norminv(1-alfa/2)*sqrt(var(per_apd_64)/N);
term_apd_110 = norminv(1-alfa/2)*sqrt(var(per_apd_110)/N);
term_apd_1518 = norminv(1-alfa/2)*sqrt(var(per_apd_1518)/N);

% guarda num array -> graph
term_pl = [term_pl_all, term_pl_64, term_pl_110, term_pl_1518];
term_apd = [term_apd_all, term_apd_64, term_apd_110, term_apd_1518];

fprintf('PacketLoss_ALL              = %.2e +- %.2e\n',media_pl(1),term_pl(1));
fprintf('PacketLoss_64               = %.2e +- %.2e\n',media_pl(2),term_pl(2));
fprintf('PacketLoss_110              = %.2e +- %.2e\n',media_pl(3),term_pl(3));
fprintf('PacketLoss_1518             = %.2e +- %.2e\n',media_pl(4),term_pl(4));
fprintf('Av. Packet Delay (ms)_ALL   = %.2e +- %.2e\n',media_apd(1),term_apd(1));
fprintf('Av. Packet Delay (ms)_64    = %.2e +- %.2e\n',media_apd(2),term_apd(2));
fprintf('Av. Packet Delay (ms)_110   = %.2e +- %.2e\n',media_apd(3),term_apd(3));
fprintf('Av. Packet Delay (ms)_1518  = %.2e +- %.2e\n',media_apd(4),term_apd(4));

size_packet = ["All", 64, 110, 1518];

figure;
bar(size_packet, media_pl);
hold on;
er = errorbar(1:4, media_pl, term_pl);
er.Color = [0 0 0];                            
er.LineStyle = 'none'; 
xlabel('Size Packet (Bytes)');
ylabel('Packet Loss (%)');
title('Packet Loss for Different Packet Sizes');
grid on;
hold off;

figure;
bar(size_packet, media_apd);
hold on;
er = errorbar(1:4, media_apd, term_apd);
er.Color = [0 0 0];                            
er.LineStyle = 'none'; 
xlabel('Size Packet (Bytes)');
ylabel('Average Packet Delay (ms)');
title('Average Packet Delay for Different Packet Sizes');
grid on;
hold off;

% PacketLoss_ALL              = 0.00e+00 +- 0.00e+00
% PacketLoss_64               = 0.00e+00 +- 0.00e+00
% PacketLoss_110              = 0.00e+00 +- 0.00e+00
% PacketLoss_1518             = 0.00e+00 +- 0.00e+00
% Av. Packet Delay (ms)_ALL   = 1.68e+01 +- 5.06e-01
% Av. Packet Delay (ms)_64    = 2.33e+01 +- 7.36e-01
% Av. Packet Delay (ms)_110   = 2.33e+01 +- 7.36e-01
% Av. Packet Delay (ms)_1518  = 1.95e+00 +- 3.01e-03

% Nao há perdas porque o buffer é grande o suficiente

% Pacotes Maiores:
% tem mais prioridade sobre os restantes
% são transmitidos mal chegam (+-)

% Pacotes menores:
% tem menos prioridade
% sempre q chega um grande tem de esperar
% maiores ocupam mais espaço então aummenta mais o tempo de espera dos
% menores

%% 1 i)

% notar q se mudou a f de 1M para 10k

% PacketLoss_ALL              = 1.72e+00 +- 2.52e-02
% PacketLoss_64               = 1.68e-01 +- 8.34e-03
% PacketLoss_110              = 2.88e-01 +- 9.63e-03
% PacketLoss_1518             = 4.57e+00 +- 6.69e-02
% Av. Packet Delay (ms)_ALL   = 6.18e+00 +- 2.83e-02
% Av. Packet Delay (ms)_64    = 7.93e+00 +- 4.40e-02
% Av. Packet Delay (ms)_110   = 7.93e+00 +- 4.31e-02
% Av. Packet Delay (ms)_1518  = 1.86e+00 +- 1.71e-03

% o tamanho do buffer já não é grande o suficiente para evitar overflow

% então com uma quantidade menor de pacotes na fila de espera os pacotes
% não tem de esperar tanto e mantem se o facto de pacotes grandes esperarem
% menos por causa da prioridade

%% 1 j)

% Simulador1A -> FIFO ; Simulador1B -> Prioridade Pacotes Maiores

% f = 1M
% Simulador1A (1. d):
% Não há perdas de pacotes, todos os pacotes esperam na fila. Atraso médio 
% depende apenas do tamanho do pacote. Pacotes maiores demoram mais a 
% transmitir, logo seu atraso é maior.

% Simulador1B (1. h):
% Também sem perdas, mas pacotes grandes têm prioridade e são transmitidos imediatamente.
% por causa disso o atraso médio dos pacotes maiores é bem menor que dos
% outros tamanhos.


% f = 10k
% Simulador1A (1. f):
% então começa a haver perda de pacotes por overflow, buffer é demasiado
% pequeno. 
% Como é FIFO os pacotes mais pequenos tem um tempo de delay menor, maiores
% sofrem mais por causa do tempo de transmissão deles.

% Simulador1B (1. i):
% neste caso tb há overflow -> buffer pequeno
% mas neste caso por pacotes maiores terem mais prioridade, causa os
% menores a terem um delay médio muito maior que no Simulador1A, pq como
% grandes tem prioridade e ocupam mais espaço do link, os pequenos tem de
% esperar mais (maiores -> + tempo de trnsmissão, ocupam + espaço)