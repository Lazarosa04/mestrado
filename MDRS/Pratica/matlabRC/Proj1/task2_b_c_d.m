%% 2 b)

% Consider the cases C = 10 Mbps, f = 1.000.000 Bytes and lambda = 1500 pps, 
% b = 10-5 and n = 10, 20, 30 and 40 VoIP flows. For each case and using
% Simulator3A, estimate by simulation the average packet loss of each 
% service (data and VoIP)

C = 10;
f = 1e6;
lambda = 1500;
P = 1e5;
b = 1e-5;
nFlows = [10, 20, 30, 40];
N = 50;

alfa= 0.1; %90% confidence interval%

per_pl= zeros(length(nFlows),N);
per_apd= zeros(length(nFlows),N);
per_mpd= zeros(length(nFlows),N);
per_tt= zeros(length(nFlows),N);

per_pl_v  = zeros(length(nFlows),N);
per_apd_v = zeros(length(nFlows),N);
per_mpd_v = zeros(length(nFlows),N);

% Calculo pl pros graficos
pl_media_data = zeros(1, length(nFlows));
pl_term_data  = zeros(1, length(nFlows));
pl_media_voip = zeros(1, length(nFlows));
pl_term_voip  = zeros(1, length(nFlows));

% Calculo apd pros graficos
apd_media_data = zeros(1, length(nFlows));
apd_term_data  = zeros(1, length(nFlows));
apd_media_voip = zeros(1, length(nFlows));
apd_term_voip  = zeros(1, length(nFlows));

% Calculo TT pros graficos
tt_media = zeros(1, length(nFlows));
tt_term = zeros(1, length(nFlows));

for n = 1:length(nFlows) 
    %n
    for index = 1:N
        %index
        [per_pl(n,index), per_pl_v(n,index), per_apd(n,index), per_apd_v(n,index), per_mpd(n,index), per_mpd_v(n,index), per_tt(n,index)] = Simulator3A(lambda, C, f, P, nFlows(n), b);
    end
    % Data PL
    pl_media_data(n) = mean(per_pl(n, :));
    pl_term_data(n)  = norminv(1-alfa/2) * sqrt(var(per_pl(n,:))/N);
    fprintf('PacketLoss  DATA           = %.2e +- %.2e\n',pl_media_data(n),pl_term_data(n));
    % VoIP PL
    pl_media_voip(n) = mean(per_pl_v(n, :));
    pl_term_voip(n)  = norminv(1-alfa/2) * sqrt(var(per_pl_v(n,:))/N);
    fprintf('PacketLoss  Voip           = %.2e +- %.2e\n',pl_media_voip(n),pl_term_voip(n));

    % Data APD
    apd_media_data(n) = mean(per_apd(n, :));
    apd_term_data(n)  = norminv(1-alfa/2) * sqrt(var(per_apd(n,:))/N);
    fprintf('PacketDelay DATA           = %.2e +- %.2e\n',apd_media_data(n),apd_term_data(n));
    % VoIP APD
    apd_media_voip(n) = mean(per_apd_v(n, :));
    apd_term_voip(n)  = norminv(1-alfa/2) * sqrt(var(per_apd_v(n,:))/N);
    fprintf('PacketDelay Voip           = %.2e +- %.2e\n',apd_media_voip(n),apd_term_voip(n));

    % Calculate TT for data and VoIP
    tt_media(n) = mean(per_tt(n, :));
    tt_term(n)  = norminv(1-alfa/2) * sqrt(var(per_tt(n,:))/N);
    fprintf('Throughput (Mbps)          = %.2e +- %.2e\n',tt_media(n),tt_term(n));
end

% Packet Loss

figure;
bar(nFlows,pl_media_data)                
hold on
er = errorbar(nFlows, pl_media_data, pl_term_data);
er.Color = [0 0 0];                            
er.LineStyle = 'none'; 
xlabel('Number of VoIP Flows');
ylabel('Average Data Packet Loss (%)');
title('Average Data Packet Loss with 90% Confidence Interval');
grid on;
hold off;

figure;
bar(nFlows,pl_media_voip)                
hold on
er = errorbar(nFlows, pl_media_voip, pl_term_voip);
er.Color = [0 0 0];                            
er.LineStyle = 'none'; 
xlabel('Number of VoIP Flows');
ylabel('Average VoIP Packet Loss (%)');
title('Average VoIP Packet Loss with 90% Confidence Interval');
grid on;
hold off;

% Average Packet Delay

figure;
bar(nFlows,apd_media_data)                
hold on
er = errorbar(nFlows, apd_media_data, apd_term_data);
er.Color = [0 0 0];                            
er.LineStyle = 'none'; 
xlabel('Number of VoIP Flows');
ylabel('Average Data Packet Delay (ms)');
title('Average Data Packet Delay with 90% Confidence Interval');
grid on;
hold off;

figure;
bar(nFlows,apd_media_voip)                
hold on
er = errorbar(nFlows, apd_media_voip, apd_term_voip);
er.Color = [0 0 0];                            
er.LineStyle = 'none'; 
xlabel('Number of VoIP Flows');
ylabel('Average VoIP Packet Delay (ms)');
title('Average VoIP Packet Delay with 90% Confidence Interval');
grid on;
hold off;

% Throughput
figure;
bar(nFlows,tt_media)                
hold on
er = errorbar(nFlows, tt_media, tt_term);
er.Color = [0 0 0];                            
er.LineStyle = 'none'; 
xlabel('Number of VoIP Flows');
ylabel('Throughput (Mbps)');
title('Throughput with 90% Confidence Interval');
grid on;
hold off;

% PacketLoss             = 4.74e+00 +- 2.01e-02
% PacketLoss             = 9.66e-01 +- 1.43e-02
% PacketLoss             = 4.75e+00 +- 1.82e-02
% PacketLoss             = 9.60e-01 +- 1.20e-02
% PacketLoss             = 4.73e+00 +- 2.11e-02
% PacketLoss             = 9.55e-01 +- 9.80e-03
% PacketLoss             = 4.74e+00 +- 2.22e-02
% PacketLoss             = 9.51e-01 +- 7.59e-03

% Pacotes Voip tem tamanhos mais pequenos que Data
% ou seja ocupam menos espaço no buffer -> menos chance de serem descartados
% os Voip são enviados seguidos, em espaço regulares e curtos, já os Data meio
% aleatórios (lambda) -> maior prob de overflow


% dividido em 2 PL, 2 APD, 2 PL, 2APD, ...

% PacketLoss  DATA           = 4.75e+00 +- 4.86e-02
% PacketLoss  Voip           = 9.32e-01 +- 5.20e-02
% PacketDelay DATA           = 2.17e+00 +- 3.97e-02
% PacketDelay Voip           = 1.77e+00 +- 3.53e-02
% PacketLoss  DATA           = 4.72e+00 +- 7.13e-02
% PacketLoss  Voip           = 9.67e-01 +- 3.97e-02
% PacketDelay DATA           = 2.67e+00 +- 8.05e-02
% PacketDelay Voip           = 2.27e+00 +- 7.56e-02
% PacketLoss  DATA           = 4.74e+00 +- 6.65e-02
% PacketLoss  Voip           = 9.74e-01 +- 3.31e-02
% PacketDelay DATA           = 3.50e+00 +- 1.57e-01
% PacketDelay Voip           = 3.10e+00 +- 1.53e-01
% PacketLoss  DATA           = 4.70e+00 +- 6.97e-02
% PacketLoss  Voip           = 9.03e-01 +- 2.62e-02
% PacketDelay DATA           = 5.66e+00 +- 4.14e-01
% PacketDelay Voip           = 5.24e+00 +- 4.02e-01

% entao os valores de APD da DATA e Voip são parecidos (apd)
% os valores de data são piores q voip, pois voip como ocupam menos espaço
% no link, 'mais facilidade em entrar'
% os valores pioram com aumento como fluxos, tem mais pacotes (q vem seguidos)
% ou seja fila fica mais cheia -> gera maiores atrasos
% mais pacotes tarnsmitidos -> maior chance de congestionamento -> maiores
% perdas