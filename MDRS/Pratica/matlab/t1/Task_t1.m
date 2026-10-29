% Considera uma ligação wireless para communicações com os estados i = 0, 1, 2,
% 3 e 4

% o ber introduzido pela ligação em cada estado é (10^-6)*(10^i)
% todas as ligações detetam com 100% de certeza quando os frames de data
% contêm erros

% 1 a) determina a probabilidade da ligação estar no estado 2

Q = [-10 10 0 0 0;
     100 -104 4 0 0;
     0 50 -54 4 0;
     0 0 10 -11 1;
     0 0 0 2 -2];

A = [Q'; ones(1,5)];
b = [zeros(5,1); 1];
probabilidadesEstados = A\b;

fprintf('Probabilidade da ligação estar no estado 2: %.6f%%\n', ...
    100 * probabilidadesEstados(3));

% 1 b) determina o holding time médio em segundos do estado 1


holdingTimeMedioEstado1 = 3600 / -Q(2,2);

fprintf('Holding time médio do estado 1: %.6f segundos\n', ...
    holdingTimeMedioEstado1);

% 1 c) determina a probabilidade de um frame de data de 750 Bytes ser
% recevido com pelo menos um bit errado

berEstados = 10.^(-6 + (0:4));
tamanhoFrameBits = 750 * 8;
probabilidadeErroPorEstado = 1 - (1 - berEstados).^tamanhoFrameBits;
probabilidadeMediaErro = probabilidadesEstados.' * probabilidadeErroPorEstado.';

fprintf('Probabilidade de um frame de 750 bytes ser recebido com pelo menos um bit errado: %.6f%%\n', ...
    100 * probabilidadeMediaErro);

% 1 d) determina a probabilidade da ligação estar no estado 2 sendo que um
% frame de data de 1500 bytes foi recebido sem erros

tamanhoFrameBitsD = 1500 * 8;
probabilidadeSemErroPorEstado = (1 - berEstados).^tamanhoFrameBitsD;
probabilidadeMediaSemErro = probabilidadesEstados.' * probabilidadeSemErroPorEstado.';
probabilidadeEstado2DadoSemErro = ...
    probabilidadesEstados(3) * probabilidadeSemErroPorEstado(3) / ...
    probabilidadeMediaSemErro;

fprintf('Probabilidade da ligação estar no estado 2 dado que um frame de 1500 bytes foi recebido sem erros: %.6f%%\n', ...
    100 * probabilidadeEstado2DadoSemErro);


% 1 e) grafico da probabilidade do frame de data ser
% recebido sem erros em função do tamanho do frame de data 

tamanhosBytes = 100:1500;
probabilidadeSemErroPorTamanho = ...
    (1 - berEstados.').^(8 * tamanhosBytes);
probabilidadeMediaSemErroPorTamanho = ...
    probabilidadesEstados.' * probabilidadeSemErroPorTamanho;

figure;
plot(tamanhosBytes, 100 * probabilidadeMediaSemErroPorTamanho, ...
    'LineWidth', 1.5);
grid on;
xlim([100 1500]);
xticks([100 300:200:1500]);
xlabel('Tamanho do frame (bytes)');
ylabel('Probabilidade de receção sem erros (%)');
title('Probabilidade de receção sem erros em função do tamanho do frame');
