% consider a wireless link between multiple stations for data
% communications with states i = 0, 1, 2 e 3
% cujos comportamentos são dados pela seguinte CMTC
% 0->1 10       1->0 200
% 1->2 5        2->1 50
% 2->3 2        3->2 5

% a bit error rate
% introduzida pela ligação wireless em cada estado é 10^-6*10^i
% todas as estações detetam com uma probabilidade ed 100% quando os frames
% de data enviados por outra estação são recebidos com erros

% 4.a
% determina a probabilidade (em %) da ligação estar em cada estado

Q = [-10 10 0 0;
     200 -205 5 0;
     0 50 -52 2;
     0 0 5 -5];

A = [Q'; ones(1,4)];
b = [zeros(4,1); 1];
pi = A\b;

fprintf('Probabilidades dos estados (%%):\n');
fprintf('Estado %d: %.6f%%\n', [(0:3); 100*pi.']);

% 4.b determina a percentagem media de tempo que a ligação passa em cada
% estado

tempoMedioEstados = pi;
fprintf('\nPercentagem média de tempo em cada estado:\n');
fprintf('Estado %d: %.6f%%\n', [(0:3); 100*tempoMedioEstados.']);

% 4.c determina a media do ber da ligação

berEstados = 10.^(-6 + (0:3));
berMedio = pi.' * berEstados.'

% 4.d determina a media de
% holding time (em minutos) da ligação em cada estado

taxasSaida = -diag(Q);
holdingTimeMinutos = 60 ./ taxasSaida

% 4.e determina a pobabilidade (em %) de um frame de data de 1500 bytes ser
% recebido sem erros para cada estado

tamanhoFrameBits = 1500 * 8;
probabilidadeSemErro = (1 - berEstados).^tamanhoFrameBits

% 4.f determina a probabilidade de um frame de data de 1500 bytes ser
% recebido sem erros

probabilidadeMediaSemErro = pi.' * probabilidadeSemErro.';
fprintf('\nProbabilidade média de receção sem erros: %.6f%%\n', ...
    100 * probabilidadeMediaSemErro);

% 4.g determine a
% probabilidade da ligação estar em cada estado quando um frame de data de
% 1500 bytes é recebido sem erros

probabilidadeEstadoDadoSucesso = (pi .* probabilidadeSemErro.') / probabilidadeMediaSemErro;
fprintf('\nProbabilidade dos estados dado receção sem erros (%%):\n');
fprintf('Estado %d: %.6f%%\n', [(0:3); 100*probabilidadeEstadoDadoSucesso.']);

% 4.h determine a
% probabilidade da ligação estar em cada um dos estados quando um frame de
% data de 1500 bytes é recebido com pelo menos um erro

probabilidadeComErro = 1 - probabilidadeSemErro;
probabilidadeMediaComErro = pi.' * probabilidadeComErro.';
probabilidadeEstadoDadoErro = (pi .* probabilidadeComErro.') / probabilidadeMediaComErro

% 4.i desenha um gráfico da
% probabilidade de um pacote ser recebido com pelo menos um erro (em %) em
% função do tamanho do pacote desde 64 bytes até 1500

tamanhosBytes = 64:1500;
probabilidadeErro = 1 - pi.' * (1 - berEstados.').^(8 * tamanhosBytes);

figure;
plot(tamanhosBytes, 100 * probabilidadeErro);
linha = findobj(gca, 'Type', 'line');
linha.XData = [0, tamanhosBytes];
linha.YData = [0, 100 * probabilidadeErro];
xlim([0, 1500]);
grid on;
xlabel('Tamanho do pacote (bytes)');
ylabel('Probabilidade de erro (%)');
title('Probabilidade de receção com pelo menos um erro');
xticks(200:200:1400);