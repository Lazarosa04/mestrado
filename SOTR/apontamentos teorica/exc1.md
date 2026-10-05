
T1  Ci = 1  Ti = 4      -> intervalo de tempo alocado de 4, duração 1
T2  Ci = 1  Ti = 5      -> intervalo de tempo alocado de 5, duração 1
T3  Ci = 3  Ti = 10     -> intervalo de tempo alocado de 10, duração 3
i.e, a cada 4, a t1 tem de ser executada uma vez
a cada 5, a t2 tem de ser executada uma vez
a cada 10, a t3 tem de ser executada uma vez


para Pr = t1>t2>t3


T1  |-              |-              |-
T2  |   -               |-                  |
T3  |       -   -           -               |
    0   1   2   3   4   5   6   7   8   9   10

    Não podemos ter a certeza se é fazível porque não observamos um padrão claro no intervalo de tempo simulado
    Este schedule está a organizar as prioridades pela ordem de frequência das tasks, i.e, a task com frequência mais alta (que tem de ser executada mais vezes)
    é a mais prioritária, e segue esse padrão A este tipo de scheduling chamamos Rate-monotonic schedule.
    https://en.wikipedia.org/wiki/Rate-monotonic_scheduling


para Pr = t3>t2>t1

T1  |               |-               | 
T2  |           -       |                   |
T3  |-  -   -                               |
    0   1   2   3   4   5   6   7   8   9   10

    Schedule não fazível, a task 1 não pode ser completada no espaço de tempo alocado


    


