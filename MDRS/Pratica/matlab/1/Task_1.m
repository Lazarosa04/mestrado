% Três estados possíveis:
% N, L e S
% que acontecem respetivamente:
% 95, 4.5 e 0.5 por cento das vezes
% com três probabilidades de os pacotes terem erros nos estados respetivos:
% 0.1, 0.5 e 4

% 1.a
% Qual a probabilidade de o pacote recebido conter erros e o estado ser o N

pN = 0.95;
pDadoN = 0.001;

pErroN = pN * pDadoN

% 1.b
% qual a probabilidade de dado um pacote recebido, conter erros

pL = 0.045;
pS = 0.005;

pDadoL = 0.005;
pDadoS = 0.04;

pErro = pN * pDadoN + pL * pDadoL + pS * pDadoS

% 1.c
% qual a probabilidade de estarmos no estado S sendo que o pacote recebido
% tem erros

pS_dadoErro = (pS * pDadoS) / pErro

% 1.d
% probabilidade de
% estarmos no estado L sendo que o pacote recebido não tem erros

pL_dadoNaoErro = (pL * (1 - pDadoL)) / (1 - pErro)


% 1.e
% desenha um grafico com a probabilidade de estarmos em cada um dos estados
% quando o pacote é recebido com e sem erros

pEstados_dadoErro = [pN*pDadoN, pL*pDadoL, pS*pDadoS] / pErro;
pEstados_dadoNaoErro = [pN*(1-pDadoN), pL*(1-pDadoL), pS*(1-pDadoS)] / (1-pErro);

bar([pEstados_dadoErro; pEstados_dadoNaoErro].')
set(gca, 'XTickLabel', {'N', 'L', 'S'})
legend('Com erros', 'Sem erros', 'Location', 'best')
ylabel('Probabilidade (%)')
ytickformat('percentage')
xlabel('Estado')
title('Probabilidade dos estados condicionada ao recebimento')
grid on


