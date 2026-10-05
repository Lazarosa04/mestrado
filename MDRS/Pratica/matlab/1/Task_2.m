% considera uma ligação
% wireles para comunicações com uma rate de bit errors de p
% Assume que a transmissão
% de erros nos diferentes
% bits de um frame de data são estatisticamente independentes

% 2.a
% probabilidade de se receber um frame de data com 500 bytes sem erros se
% p = 10^-3

p = 1e-3;
frameBytes = 500;
pSemErros = (1 - p)^(frameBytes * 8)

% 2.b probabilidade de um frame
% de data de 100 bytes ter exatamente só um erro quando p = 10^-4

p = 1e-4;
frameBytes = 1000;
p1Erro = (frameBytes * 8) * p * (1 - p)^(frameBytes * 8 - 1)

% 2.c probabilidade de um frame de data de 1500 bytes ter um ou mais erros
% quando p = 10^-5

p = 1e-5;
frameBytes = 1500;
pUmOuMaisErros = 1 - (1 - p)^(frameBytes * 8)

% 2.d
% quando p = 10^-5 qual é o tamanho máximo de um frame de data de forma a
% que a percentagem de erros seja inferior a 1%

p = 1e-5;
frameBytes = 0;
pSemErros = 1;

while pSemErros * (1 - p)^8 >= 0.99
    frameBytes = frameBytes + 1;
    pSemErros = pSemErros * (1 - p)^8;
end

frameBytes
percentagemErros = 1 - pSemErros

% 2.e
% desenha um gráfico usando
% uma escala logaritmica para o eixo x com a probabilidade de um frame de
% data de tamanhos de 100, 500 e 1500 bytes sere recevidos sem erros em
% função de p desde p = 10^-8 até p = 10^-2

pValores = logspace(-8, -2, 200);
tamanhos = [100, 500, 1500];

probSemErros = (1 - pValores(:)).^(tamanhos * 8) * 100;

figure
semilogx(pValores, probSemErros, 'LineWidth', 1.5)
grid on
xlabel('Probabilidade de erro por bit, p')
ylabel('Probabilidade de receber o frame sem erros')
legend('100 bytes', '500 bytes', '1500 bytes', 'Location', 'best', location='southwest')
