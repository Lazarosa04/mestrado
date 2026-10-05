%% 1 d)
% Consider the case C = 10 Mbps, f = 1.000.000 Bytes and lambda = 1900 pps.
% Using Simulator1A, estimate by simulation the average packet loss and 
% average packet delay, both performance parameters for all packets and
% for each of the 3 special packet sizes. Present the average packet loss
% results in one figure and the average packet delay results in another
% figure. Justify these results and draw all relevant conclusions.

% f = 1e6;
 f = 1e4;      % 1 f)
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
    [per_pl(index), per_pl_64(index), per_pl_110(index), per_pl_1518(index), per_apd(index), per_apd_64(index), per_apd_110(index), per_apd_1518(index), per_mpd(index), per_tt(index)] = Simulator1A(lambda, C, f, P);
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

% categorical

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
er = errorbar(1:4, media_apd, term_apd, 'o-', 'LineWidth', 1.5);
er.Color = [0 0 0];                            
er.LineStyle = 'none'; 
xlabel('Size Packet (Bytes)');
ylabel('Average Packet Delay (ms)');
title('Average Packet Delay for Different Packet Sizes');
grid on;
hold off;

%%
% Neste caso (f = 1e6 Bytes, λ = 1900 pps), o buffer é suficientemente grande
% para que não ocorram perdas de pacotes, mesmo para pacotes grandes. 
% Portanto, o Packet Loss é praticamente zero para todos os tipos de pacotes.

% Observa-se que o atraso médio depende diretamente do tamanho do pacote:
% - Pacotes pequenos (64 Bytes) têm atraso médio menor, porque ocupam menos
%   tempo de transmissão e passam rapidamente pelo link.
% - Pacotes médios (110 Bytes) apresentam atraso ligeiramente maior.
% - Pacotes grandes (1518 Bytes) apresentam atraso significativamente maior,
%   pois a transmissão demora mais tempo, aumentando o tempo de espera na fila.

% Assim, mesmo sem perdas, há uma clara relação entre tamanho do pacote e atraso.
% O gráfico de Average Packet Delay forma um "U", no meu caso pq começo por imprimir
% a media de todos e só depois a dos pequenos, dps médios e por fim grandes.
% Este comportamento é consistente com a lógica do sistema: o tempo de transmissão cresce
% com o tamanho do pacote, enquanto o Packet Loss permanece zero devido ao buffer grande.
