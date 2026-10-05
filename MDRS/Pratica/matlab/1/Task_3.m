% considera uma ligação de
% data com uma capacidade C que suporta a transmissão de pacotes de data
% cujos tamanhos variam entre 64 bytes e 1518 bytes com as seguintes
% probabilidades: 19% para 64, 23% para 110, 17% para 1518, e
% probabilidades iguais para todos os outros valores
% considere a variavel aleatória X como representando o tempo de
% transmissão dos pacotes

% 3.a
% determine a média, o segundo momento, a variação e o standard de desvio
% da variável aleatória X quando a capacidade da ligação é C = 10Mbps

C = 10e6;
tamanho = 64:1518;
probabilidade = ones(size(tamanho)) * (1 - 0.19 - 0.23 - 0.17) / (numel(tamanho) - 3);
probabilidade(tamanho == 64) = 0.19;
probabilidade(tamanho == 110) = 0.23;
probabilidade(tamanho == 1518) = 0.17;

X = tamanho * 8 / C;
media = sum(probabilidade .* X);
segundo_momento = sum(probabilidade .* X.^2);
variancia = segundo_momento - media^2;
desvio_padrao = sqrt(variancia);

fprintf('Média: %.6g s\n', media);
fprintf('Segundo momento: %.6g s^2\n', segundo_momento);
fprintf('Variância: %.6g s^2\n', variancia);
fprintf('Desvio padrão: %.6g s\n', desvio_padrao);

% 3.b
% a probabilidade de X ser maior que um milisegundo para C = 10Mbps

probabilidade_maior_1ms = sum(probabilidade(X > 1e-3));
fprintf('P(X > 1 ms): %.6g\n', probabilidade_maior_1ms);

% 3.c
% repete 3.a mas desta vez considerando que a capacidade C = 100Mbps

C = 100e6;
X = tamanho * 8 / C;
media = sum(probabilidade .* X);
segundo_momento = sum(probabilidade .* X.^2);
variancia = segundo_momento - media^2;
desvio_padrao = sqrt(variancia);

fprintf('Média: %.6g s\n', media);
fprintf('Segundo momento: %.6g s^2\n', segundo_momento);
fprintf('Variância: %.6g s^2\n', variancia);
fprintf('Desvio padrão: %.6g s\n', desvio_padrao);

% 3.d
% probabilidade de X ser maior que 1 milisegundo quando C = 100Mbps

probabilidade_maior_1ms = sum(probabilidade(X > 1e-3));
fprintf('P(X > 1 ms): %.6g\n', probabilidade_maior_1ms);

% 3.e
% desenha um gráfico com a média de tempo por transmissão de pacote para
% quando C = 10, 20, 50, 100, 200, 500 e 1000 Mbps

capacidadesMbps = [10 20 50 100 200 500 1000];
capacidades = capacidadesMbps * 1e6;
medias = (probabilidade * tamanho') * 8 ./ capacidades * 1000;

figure;
bar(1:numel(capacidadesMbps), medias * 1e3);
set(gca, 'XTick', 1:numel(capacidadesMbps), ...
    'XTickLabel', string(capacidadesMbps));
xlabel('Capacidade (Mbps)');
ylabel('Tempo médio de transmissão (ms)');
grid on;