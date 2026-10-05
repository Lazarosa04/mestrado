%% 1a

% When 𝑝=60% and 𝑛=4, determine the probability of the student to select the right answer

% P(r) = P(r|e)*P(e) + P(r|ne)*P(ne) 
Pr = 1 * 0.6 + 1/4 * (1-0.6)

%% 1b

% P(e | r) = P(r|e)*P(e) / P(r)

P_er = 1 * 0.7 / (1 * 0.7 + 1/5 * (1-0.7))

%% 1c
% Probability of the student to select the right answer as a function of the probability 𝑝
% n = 3, 4 e 5

p = 0:0.01:1;  % valores de p (0% a 100%)

n_values = [3 4 5]; % número de opções múltiplas

figure;
hold on;

for n = n_values
    P_acerto = p + (1-p)/n;   % P(r) = P(r|e)*P(e) + P(r|ne)*P(ne) = 1*p + 1/n * (1-p)
    plot(p, P_acerto);
end

xlabel('p (probabilidade de conhecer o conteúdo)');
ylabel('P(acertar)');
title('Probabilidade de acertar vs p (n = 3,4,5)');
grid on;
ylim([0 1.05]);
xlim([0 1]);

%% 1d

% probability of the student to know the answer when he selects the right answer as a function of the probability 𝑝

p = 0:0.01:1;  % valores de p (0% a 100%)

n_values = [3 4 5]; % número de opções múltiplas

figure;
hold on;

for n = n_values
    P_acerto = p + (1-p)/n;   % P(e | r) = P(r|e)*P(e) / P(r) = 1 * p / (expressao anterior)
    P_sabe_acerto = p ./ P_acerto;
    plot(p, P_sabe_acerto);
end

xlabel('p (probabilidade de conhecer o conteúdo)');
ylabel('P(acertar)');
title('Probabilidade de acertar vs p (n = 3,4,5)');
grid on;
ylim([0 1.05]);
xlim([0 1]);