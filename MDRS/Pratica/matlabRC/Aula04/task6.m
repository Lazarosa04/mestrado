%% ex 6

% Develop a MATLAB script to run Simulator2 100 times with a stopping criterion of P =
% 10000 at each run and to compute the estimated values and the 90% confidence intervals
% of all performance parameters when lambda = 1800 pps, C = 10 Mbps, f = 1.000.000 Bytes and
% b = 10-6.

N = 100;
% alfa = 0.9;

lambda = 1800;
C = 10;

P = 1e5;
b = 1e-6;

per_pl= zeros(1,N);
per_apd= zeros(1,N);
per_mpd= zeros(1,N);
per_tt= zeros(1,N);

%% b)

f = 1e6;
for index = 1:N
    [per_pl(index), per_apd(index), per_mpd(index), per_tt(index)] = Simulator2(lambda, C, f, P, b);
end
%% c)

f = 1e4;
for index = 1:N
    [per_pl(index), per_apd(index), per_mpd(index), per_tt(index)] = Simulator2(lambda, C, f, P, b);
end

%% d)

f = 2e3;
for index = 1:N
    [per_pl(index), per_apd(index), per_mpd(index), per_tt(index)] = Simulator2(lambda, C, f, P, b);
end

%%
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

% 5 b) e 6 b) -> grande diferença no PL porque Simulator2 adiciona perdas por 
% erros no canal; delay e throughput pouco alterados porque BER=1e-6 é pequeno.

% 5 d) e 6 c) -> com f=10k as perdas por overflow dominam; BER adiciona uma pequena 
% parcela extra de perdas; APD pouco alterado porque os pacotes que passam têm 
% comportamento semelhante.

% 5 e) e 6 d) -> com f=2k perdas por overflow dominam -> APD cai porque pacotes 
% com espera longa são descartados e não entram na média; MPD também tende a cair 
% porque a fila não permite formar enfileiramentos grandes.