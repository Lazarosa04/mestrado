%% 2a

% Determine the probability of a data frame of 100 Bytes to be received
% without errors when 𝑝= 1e-2

n = 100*8;          % nº de ensaios
k = 0;              % valores possíveis de sucessos
p = 1e-2;       

P = binopdf(k, n, p);

fprintf('1e-2 : %.2e\n', P);

%% 2b

% Determine the probability of a data frame of 1000 Bytes to be received
% with exactly one error when 𝑝=1e-3

n = 1000*8;          % nº de ensaios
k = 1;              % valores possíveis de sucessos
p = 1e-3;       

P = binopdf(k, n, p);

fprintf('1e-3 : %.2e\n', P);

%% 2c

% Determine the probability of a data frame of 200 Bytes to be received
% with one or more errors when 𝑝=1e-4

n = 200*8;          % nº de ensaios
k = 0;              % valores possíveis de sucessos
p = 1e-4;       

P = binopdf(k, n, p);

fprintf('1e-4 : %.2e\n', 1 - P);

%% 2d

% probability of a data frame (of size 100 Bytes, 200 Bytes or 1000 Bytes) 
% being received without errors as a function of the ber (from 𝑝=1e−8 up to 𝑝=1e−2)

% Valores de BER de 1e-8 até 1e-2
ber = logspace(-8, -2);

% Tamanhos de frame em Bytes
frame_sizes = [100 200 1000];

figure; 
L = frame_sizes(1);
n = L * 8;                      
P_noerror = (1 - ber).^n;
semilogx(ber, P_noerror);
hold on;

for L = frame_sizes(2:3)
    n = L * 8;                       % nº de bits
    P_noerror = (1 - ber).^n;
    semilogx(ber, P_noerror);
end

xlabel('BER (Bit Error Rate)');
ylabel('P(\it{frame sem erros})');
title('Probabilidade de um frame ser recebido sem erros vs BER');
grid on;



%% 2e

% probability of a data frame being received without errors (for 𝑝=1e−4, 1e−3 and 1e−2) 
% as a function of the packet size (all integer values from 64 Bytes up to 1518 Bytes)

ber_values = [1e-4, 1e-3, 1e-2];

pack_size = 64:1:1518;

figure;
p = ber_values(1);
P_noerror = (1 - p).^(pack_size * 8);
semilogy(pack_size, P_noerror);
hold on;

for p = ber_values(2:3)
    P_noerror = (1 - p).^(pack_size * 8);  % probabilidade de não ter erros
    semilogy(pack_size, P_noerror);
end

xlabel('Packet size (Bytes)');
ylabel('P(\it{frame sem erros})');
title('Probabilidade de um frame ser recebido sem erros vs tamanho do pacote');
grid on;
