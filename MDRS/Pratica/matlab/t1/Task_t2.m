% ligação ideal ponto a
% ponto a partir de um router para outrocom uma capacidade de 10 Mbps para
% comunicações IP a ligação tem um delay de propagação de 4 microsegundos
% há uma fila no porto de output da ligação cujo tamanho é de X pacotes
% a ligação suporta um
% fluxo de pacotes IP cujos tamanhos estão distribuidos exponencialmente
% com uma media de 650bytes. A chegada dos pacotes é um processo
% poisson a 1800 pps

% 2 a)
% determina o throughput em Mbps da ligação para X = 14 pacotes

C = 10e6;                 
taxaChegada = 1800;       
tamanhoMedioBytes = 650;  
X = 14;                   

taxaServico = C / (tamanhoMedioBytes * 8);
rho = taxaChegada / taxaServico;
capacidadeSistema = X + 1;
probabilidadesOcupacao = rho.^(0:capacidadeSistema) / ...
    sum(rho.^(0:capacidadeSistema));
probabilidadeBloqueio = probabilidadesOcupacao(end);
throughputMbps = taxaChegada * (1 - probabilidadeBloqueio) * ...
    tamanhoMedioBytes * 8 / 1e6;

fprintf('Throughput da ligacao para X = %d lugares na queue: %.6f Mbps\n', ...
    X, throughputMbps);


% 2 b) determina o queuing delay médio dos pacotes para X =
% 6 pacotes

X = 6;
capacidadeSistema = X + 1;
probabilidadesOcupacao = rho.^(0:capacidadeSistema) / ...
    sum(rho.^(0:capacidadeSistema));
probabilidadeBloqueio = probabilidadesOcupacao(end);
taxaChegadaEfetiva = taxaChegada * (1 - probabilidadeBloqueio);
numeroMedioPacotesFila = sum((0:capacidadeSistema) .* probabilidadesOcupacao) - ...
    (1 - probabilidadesOcupacao(1));
queuingDelayMs = numeroMedioPacotesFila / taxaChegadaEfetiva * 1e3;

fprintf('Queuing delay medio para X = %d lugares na queue: %.6f ms\n', ...
    X, queuingDelayMs);

% 2 c) determina o delay de sistema medio para X = 15 pacotes

X = 15;
capacidadeSistema = X + 1;
probabilidadesOcupacao = rho.^(0:capacidadeSistema) / ...
    sum(rho.^(0:capacidadeSistema));
probabilidadeBloqueio = probabilidadesOcupacao(end);
taxaChegadaEfetiva = taxaChegada * (1 - probabilidadeBloqueio);
numeroMedioPacotesFila = sum((0:capacidadeSistema) .* probabilidadesOcupacao) - ...
    (1 - probabilidadesOcupacao(1));
queuingDelayMs = numeroMedioPacotesFila / taxaChegadaEfetiva * 1e3;
tempoTransmissaoMs = 1 / taxaServico * 1e3;
delayPropagacaoMs = 4e-3;
delaySistemaMedioMs = queuingDelayMs + tempoTransmissaoMs + delayPropagacaoMs;

fprintf(['Delay de sistema medio para X = %d lugares na queue: %.6f ms ' ...
    '(fila: %.6f ms, transmissao: %.6f ms, propagacao: %.6f ms)\n'], ...
    X, delaySistemaMedioMs, queuingDelayMs, tempoTransmissaoMs, ...
    delayPropagacaoMs);

% 2 d) determina o tamanho minimo da queue para que a chance de perda de
% pacotes seja inferior a 0.01%

probabilidadePerdaMaxima = 0.01 / 100;
tamanhoFila = 0;
capacidadeSistema = tamanhoFila + 1;
probabilidadePerda = rho^capacidadeSistema / ...
    sum(rho.^(0:capacidadeSistema));

while probabilidadePerda >= probabilidadePerdaMaxima
    tamanhoFila = tamanhoFila + 1;
    capacidadeSistema = tamanhoFila + 1;
    probabilidadePerda = rho^capacidadeSistema / ...
        sum(rho.^(0:capacidadeSistema));
end

fprintf(['Tamanho minimo da queue: %d pacotes; ' ...
    'probabilidade de perda: %.6f%%\n'], ...
    tamanhoFila, 100 * probabilidadePerda);

% 2 e) determina a probabilidade em percentagem da fila estar vazia para 
% X = 20 pacotes

X = 20;
capacidadeSistema = X + 1;
probabilidadesOcupacao = rho.^(0:capacidadeSistema) / ...
    sum(rho.^(0:capacidadeSistema));
probabilidadeFilaVazia = sum(probabilidadesOcupacao(1:2));

fprintf('Probabilidade da fila estar vazia para X = %d lugares: %.6f%%\n', ...
    X, 100 * probabilidadeFilaVazia);