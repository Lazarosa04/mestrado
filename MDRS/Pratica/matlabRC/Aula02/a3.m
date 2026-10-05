%% 3a == 3b

% the probability of the link being in each of the five states
% the average percentage of time the link is in each of the five states

s = [1e-6, 1e-5, 1e-4, 1e-3, 1e-2];

p0 = 1 / (1 + 8/600 + 8/600 * 5/100 + 8/600 * 5/100 * 2/20 + 8/600 * 5/100 * 2/20 * 1/5);

p1 = p0 * 8/600;

p2 = p1 * 5/100;

p3 = p2 * 2/20;

p4 = p3 * 1/5;

p = [p0, p1, p2, p3, p4];

fprintf(' 1e-6: %.2e\n 1e-5: %.2e\n 1e-4: %.2e\n 1e-3: %.2e\n 1e-2: %.2e\n', p)

%% 3c

% the average ber of the link
result = s * p';
disp(result)


%% 3d

% the average holding time (in minutes) of the link in each of the five states

t0 = 1 / 8;

t1 = 1 / (5 + 600);

t2 = 1 / (2 + 100);

t3 = 1 / (1 + 20);

t4 = 1 / 5;

pt = [t0, t1, t2, t3, t4] * 60;

fprintf(' 1e-6: %.2f\n 1e-5: %.2f\n 1e-4: %.2f\n 1e-3: %.2f\n 1e-2: %.2f\n', pt)


%% 3e

% the probability of the link being in the normal state and in interference state

P_normal = p0 + p1 + p2;

P_interference = p3 + p4;

fprintf('Probabilidade normal: %.6f\n', P_normal)
fprintf('Probabilidade interferência: %.6e\n', P_interference)

%% 3f

% the average ber of the link when it is in the normal state and when it is
%  in the interference state

s_normal = s(1:3);  % prob BER
p_normal = p(1:3);  % prob do link estar nos 1os 3 estados
Ber_normal = sum(s_normal .* p_normal) / sum(p_normal);

s_interf = s(4:5);
p_interf = p(4:5);
Ber_interf = sum(s_interf .* p_interf) / sum(p_interf);

fprintf('Average BER (normal): %.2e\n', Ber_normal)
fprintf('Average BER (interference): %.2e\n', Ber_interf)

%% 3g

% probability of the packet being received by the destination station with 
% at least one error as a function of the packet size (from 64 Bytes up to 1500 Bytes)

p = 1e-3;                   % BER do link
pack_size = 64:1500;        % tamanho do pacote em Bytes
n_bits = pack_size * 8;     % número de bits por pacote

% Probabilidade de pelo menos 1 erro
P_error = 1 - (1 - p).^n_bits;


figure;
plot(pack_size, P_error);
grid on;
xlabel('Packet size (Bytes)');
ylabel('P(frame com pelo menos 1 erro)');
title('Probabilidade de frame com pelo menos 1 erro vs tamanho do pacote');
xlim([min(pack_size) max(pack_size)])