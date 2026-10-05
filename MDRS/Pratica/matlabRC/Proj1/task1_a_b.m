%% 1 a)

% Consider the event driven simulator Simulator1 used in Task 5 of the Practical Guide. In all
% experiments requesting simulation results, compute always the estimated values and 90%
% confidence intervals based in 50 runs of the requested simulator with a stopping criterion of
% P = 100.000 each run. Then, present the estimated values in bar charts and the 90% confidence
% intervals in error bars on the same plot

% Consider the cases C = 10 Mbps, f = 1.000.000 Bytes and
% lambda = 1100, 1300, 1500, 1700 and 1900 pps. For each case, estimate by simulation the packet
% average loss and the average packet delay. Present the average packet loss results in one
% figure and the average packet delay results in another figure. Justify these results and draw
% all relevant conclusions. 

% f = 1e6;

f = 1e4;      % para 1 b)


lambda = [1100, 1300, 1500, 1700, 1900];
C = 10;
P = 1e5;

N = 50;
per_pl= zeros(length(lambda),N);
per_apd= zeros(length(lambda),N);
per_mpd= zeros(length(lambda),N);
per_tt= zeros(length(lambda),N);

alfa= 0.1; %90% confidence interval%

pl_media = zeros(1, length(lambda));
pl_term = zeros(1, length(lambda));
apd_media = zeros(1, length(lambda));
apd_term = zeros(1, length(lambda));

for l = 1:length(lambda)
    l
    for index = 1:N
        index
        [per_pl(l, index), per_apd(l, index), per_mpd(l, index), per_tt(l, index)] = Simulator1(lambda(l), C, f, P);
    end

    pl_media(l) = mean(per_pl(l, :));
    pl_term(l) = norminv(1-alfa/2)*sqrt(var(per_pl(l, :))/N);
    fprintf('PacketLoss             = %.2e +- %.2e\n',pl_media(l),pl_term(l));
    apd_media(l) = mean(per_apd(l, :));
    apd_term(l) = norminv(1-alfa/2)*sqrt(var(per_apd(l, :))/N);
    fprintf('Av. Packet Delay (ms)  = %.2e +- %.2e\n',apd_media(l),apd_term(l));
end

figure;
bar(lambda, pl_media);
hold on;
er = errorbar(lambda, pl_media, pl_term);
er.Color = [0 0 0];                            
er.LineStyle = 'none'; 
xlabel('\lambda (packets/s)');
ylabel('Packet Loss (%)');
title('Average Packet Loss with 90% Confidence Interval');
grid on;
hold off;

figure;
bar(lambda, apd_media);
hold on;
er = errorbar(lambda, apd_media, apd_term);
er.Color = [0 0 0];                            
er.LineStyle = 'none'; 
xlabel('\lambda (packets/s)');
ylabel('Average Packet Delay (ms)');
title('Average Packet Delay with 90% Confidence Interval');
grid on;
hold off;

%% a)
% Neste primeiro caso (f = 1e6 Bytes), não há perdas de pacotes, pois o 
% buffer é suficientemente grande. O atraso médio aumenta com λ, porque 
% o aumento da taxa de chegada faz a fila encher mais rapidamente. Mesmo 
% sem perdas, o sistema mostra maior tempo de espera à medida que a carga 
% cresce.


% PacketLoss             = 0.00e+00 +- 0.00e+00
% Av. Packet Delay (ms)  = 1.06e+00 +- 2.25e-03
% PacketLoss             = 0.00e+00 +- 0.00e+00
% Av. Packet Delay (ms)  = 1.35e+00 +- 3.88e-03
% PacketLoss             = 0.00e+00 +- 0.00e+00
% Av. Packet Delay (ms)  = 1.86e+00 +- 9.28e-03
% PacketLoss             = 0.00e+00 +- 0.00e+00
% Av. Packet Delay (ms)  = 3.00e+00 +- 2.30e-02
% PacketLoss             = 0.00e+00 +- 0.00e+00
% Av. Packet Delay (ms)  = 7.86e+00 +- 1.57e-01

%% b)
% Ao reduzir o tamanho da fila, o buffer enche mais depressa e ocorrem 
% perdas por overflow. Observa-se aumento da perda de pacotes e, apesar 
% de o atraso continuar a crescer com λ, ele é menor que no caso anterior,
% pois há menos pacotes a esperar na fila. Verifica-se um trade-off entre 
% atraso e perda: buffer grande → menos perdas, mais atraso; buffer 
% pequeno → mais perdas, menos atraso.

% PacketLoss = 2.60e-03 +- 1.31e-03 
% Av. Packet Delay (ms) = 1.05e+00 +- 5.63e-03 
% PacketLoss = 2.48e-02 +- 5.62e-03 
% Av. Packet Delay (ms) = 1.33e+00 +- 1.17e-02 
% PacketLoss = 1.27e-01 +- 1.16e-02 
% Av. Packet Delay (ms) = 1.78e+00 +- 1.60e-02 
% PacketLoss = 5.33e-01 +- 3.00e-02 
% Av. Packet Delay (ms) = 2.49e+00 +- 2.69e-02 
% PacketLoss = 1.61e+00 +- 7.07e-02 
% Av. Packet Delay (ms) = 3.44e+00 +- 4.19e-02

