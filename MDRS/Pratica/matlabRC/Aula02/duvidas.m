%% 2d

% probability of a data frame (of size 100 Bytes, 200 Bytes or 1000 Bytes) 
% being received without errors as a function of the ber (from 𝑝=1e−8 up to 𝑝=1e−2)

% Valores de BER de 1e-8 até 1e-2
ber = logspace(-8, -2);

% Tamanhos de frame em Bytes
frame_sizes = [100 200 1000];

figure; 
hold on;

for L = frame_sizes
    n = L * 8;                       % nº de bits
    P_noerror = (1 - ber).^n;
    semilogx(ber, P_noerror);
end

xlabel('BER (Bit Error Rate)');
ylabel('P(\it{frame sem erros})');
title('Probabilidade de um frame ser recebido sem erros vs BER');
grid on;
ylim([0 1.05]);
xlim([min(ber) max(ber)])

%% 2e

% probability of a data frame being received without errors (for 𝑝=1e−4, 1e−3 and 1e−2) 
% as a function of the packet size (all integer values from 64 Bytes up to 1518 Bytes)

ber_values = [1e-4, 1e-3, 1e-2];

pack_size = 64:1:1518;

figure;
hold on;

for p = ber_values
    P_noerror = (1 - p).^(pack_size * 8);  % probabilidade de não ter erros
    semilogy(pack_size, P_noerror);
end

xlabel('Packet size (Bytes)');
ylabel('P(\it{frame sem erros})');
title('Probabilidade de um frame ser recebido sem erros vs tamanho do pacote');
grid on;
ylim([1e-10 1.1]);
xlim([min(pack_size) max(pack_size)]);

%% 3g

% probability of the packet being received by the destination station with 
% at least one error as a function of the packet size (from 64 Bytes up to 1500 Bytes)

p = 1e-3;                   % BER do link
pack_size = 64:1500;        % tamanho do pacote em Bytes
n_bits = pack_size * 8;     % número de bits por pacote

% P_error = p
% P_noerror = (1 - p)
% para bit = (1-p)^n
% ter pelo menos 1 -> 1 - P_noerror = 1 - (1-p)^n

% Probabilidade de pelo menos 1 erro
P_error = 1 - (1 - p).^n_bits;


figure;
plot(pack_size, P_error);
grid on;
xlabel('Packet size (Bytes)');
ylabel('P(frame com pelo menos 1 erro)');
title('Probabilidade de frame com pelo menos 1 erro vs tamanho do pacote');
xlim([min(pack_size) max(pack_size)])