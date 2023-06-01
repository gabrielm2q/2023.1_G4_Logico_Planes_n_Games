:- use_module(library(thread)).
:- use_module(library(time)).
:- use_module(library(pce)).
:- use_module(library(random)).

:- consult('points.pl').

% Para executar, use o comando: 'swipl main.pl'

% Dynamic predicates
:- dynamic point/3.                 % X, Y, Raio
:- dynamic distance/5.              % X1, Y1, X2, Y2, Distancia
:- dynamic user_point_start/2.      % 
:- dynamic user_point_stop/2.       % 

% Predicado para desenhar círculos aleatórios espalhados
iterar_pontos(_, []).
iterar_pontos(D, [Predicado|Predicados]) :-
    arg(1, Predicado, X),

    arg(2, Predicado, Tail),
    arg(1, Tail, Y),

    
    arg(2, Tail, Raio),
    write('('),write(X),write(','),write(Y),writeln(')'),

    draw_circles(D, X,Y,Raio),

    iterar_pontos(D, Predicados).

% Predicado para desenhar os pontos
draw_circles(D, X, Y, Raio) :-

    new(C, circle(Raio)),

    send(C, center, point(X, Y)),
    send(C, fill_pattern, colour(red)),
    send(D, display, C).

% Predicado para gerar uma posição aleatória para o centro do círculo
random_position(MaxX, MaxY, Raio, X, Y) :-
    XMin is Raio,
    YMin is Raio,
    XMax is MaxX - Raio,
    YMax is MaxY - Raio,

    random_between(XMin, XMax, X),              % Define um posição aleatória para a coordenada x
    random_between(YMin, YMax, Y).              % Define um posição aleatória para a coordenada y

% Predicado para calcular a distância entre dois pontos.
% A distância entre dois pontos em um plano bidimensional 
% pode ser calculada utilizando a fórmula da distância euclidiana.
% distância = sqrt((x2 - x1)^2 + (y2 - y1)^2) 
calc_point_distance(X1, Y1, X2, Y2, Distance) :-
    Distance is sqrt((X2 - X1)^2 + (Y2 - Y1)^2).

% Predicado para iterar sobre uma lista de predicados e comparar cada elemento com todos os outros
calc_distance_between_all_pointers([]).
calc_distance_between_all_pointers([Predicado|PredicadosRestantes]) :-      % Cabeça e cauda da lista
    % Comparar o predicado atual com todos os outros predicados
    forall(member(OutroPredicado, PredicadosRestantes), handle_comparison(Predicado, OutroPredicado)),
    
    % Iterar recursivamente sobre a cauda da lista
    calc_distance_between_all_pointers(PredicadosRestantes).

% Predicado para comparar dois predicados
handle_comparison(Predicado1, Predicado2) :-
    % Código para comparar os predicados
    % writeln('Comparando:'),
    % writeln(Predicado1),
    % writeln(Predicado2),
    
    arg(1, Predicado1, X1),             % obtem o ponto X1

    arg(2, Predicado1, Tail1),          
    arg(1, Tail1, Y1),                  % obtem o ponto Y1

    arg(1, Predicado2, X2),             % obtem o ponto X2

    arg(2, Predicado2, Tail2), 
    arg(1, Tail2, Y2),                  % obtem o ponto Y2

    calc_point_distance(X1, Y1, X2, Y2, Distance),

    assert(distance(X1, Y1, X2, Y2, Distance)).

% Predicado que itera sobre os pontos e cria a linha
draw_line_connection([], _).            % Lista de pontos, instância da tela
draw_line_connection([Predicado|PredicadosRestantes], D) :-
    % Processar o predicado atual
    draw_line(Predicado, D),

    % Iterar recursivamente sobre a cauda da lista
    draw_line_connection(PredicadosRestantes, D).

% Predicado que desenha a linha
draw_line(Predicado, D) :-
    % Código para processar o predicado
    % writeln(Predicado),

    arg(1, Predicado, X1),              % obtem o ponto X1

    arg(2, Predicado, Tail1), 
    arg(1, Tail1, Y1),                  % obtem o ponto Y1

    arg(2, Tail1, Tail2), 
    arg(1, Tail2, X2),                  % obtem o ponto X2

    arg(2, Tail2, Tail3), 
    arg(1, Tail3, Y2),                  % obtem o ponto Y2

    arg(2, Tail3, Distance),            % obtem o a distância entre os pontos

    write('Linha entre: ('), write(X1), write(','), write(Y1), write(') e ('), write(X2), write(','), write(Y2), write(') com distância de: '), writeln(Distance),

    new(L, line(X1, Y1, X2, Y2)),

    send(D, display, L).

% Predicado que move o avião na tela
move_point(PointA, PointB, D) :-                % Ponto A e B e a instância da tela
    arg(1, PointA, X1), % obtem o ponto X1
    arg(2, PointA, Y1), % obtem o ponto Y1
    
    arg(1, PointB, X2), % obtem o ponto X2
    arg(2, PointB, Y2), % obtem o ponto Y2

    new(L, line(X1, Y1, X2, Y2)),

    send(D, display, L), 
    % Criação de um círculo que representa o avião
    new(C1, circle(10)), 

    send(C1, center, point(X1, Y1)),
    send(C1, fill_pattern, colour(blue)),
    send(D, display, C1),

    update_position(X1, Y1, X2, Y2, D, C1, 0).

% Condição de parada: Eixo X e Y coincidiram com o objetivo
update_position(_, _, _, _, _, _, T) :-
    % Quando um valor muito pequeno é utilizado para o incremento de T, maior é a dificuldade em se atingir exatamente o 
    % valor de (X2, Y2), por isso, ao invés de verificar se o ponto inicial já é igual ao ponto final,
    % optei por basear a condição de parada no valor do coeficiente T, o que atinge um certo valor ao chegar no ponto final
    T > 0.125.

% Atualiza a posição do ponto inicial para alcançar o ponto final
update_position(X1, Y1, X2, Y2, D, C1, T) :-
    % writeln('Atualizando o eixo X e Y'),
    % write('('),write(X1),write(','),write(Y1),write(')'),
    % write(' - ('),write(X2),write(','),write(Y2),writeln(')'),

    sleep(0.300),
    send(C1, center, point(X1, Y1)),
    send(D, display, C1),

    % Calculo dos pontos (x,y) que obedecem o percurso da reta e retorna o (a,b) que obedece a reta
    calc_stretching_point(X1, Y1, X2, Y2, T, LinePoint),
    
    % Coeficiente T que representa a posição relativa ao longo da linha (varia de 0 a 1)
    % O incremento da variação pode ser utilizado para determinar a velocidade com que o ponto se aproxima do seu objetivo
    % Quanto menor o incremento, menor é a valocidade com que o ponto se move
    NewT is T + 0.001,

    % Velocidade com que o avião se move
    arg(1, LinePoint, NewX1),
    arg(2, LinePoint, NewY1),

    update_position(NewX1, NewY1, X2, Y2, D, C1, NewT).

% Regra para calcular as coordenadas do ponto ao longo da linha entre A e B
% utilizando a equação paramétrica da reta
% x = x1 + t * (x2 - x1)
% y = y1 + t * (y2 - y1)
% onde t varia de 0 a 1 e representa a posição relativa ao longo da linha entre A e B.
calc_stretching_point(X1, Y1, X2, Y2, T, point(X, Y, _)) :-
    X is X1 + T * (X2 - X1),
    Y is Y1 + T * (Y2 - Y1).

% Regra para iterar sobre a lista de predicados
iterar_predicados([]).
iterar_predicados([Predicado|Predicados]) :-
    arg(1, Predicado, X),

    arg(2, Predicado, Tail),
    arg(1, Tail, Y),

    write('('),write(X),write(','),write(Y),writeln(')'),

    iterar_predicados(Predicados).

% Regra para obter um predicado aleatório da lista
% obter_predicado_aleatorio(ListaPredicados, Predicado) :-
%    length(ListaPredicados, Len), % Obter o comprimento da lista de predicados
%    random(0, Len, Indice), % Gerar um índice aleatório
%    nth0(Indice, ListaPredicados, Predicado). % Obter o predicado correspondente ao índice

% Obter e remover predicado aleatório
obter_predicado_aleatorio(Lista, Predicado, NovaLista) :-
    random_member(Predicado, Lista),
    select(Predicado, Lista, NovaLista).

% Removendo um predicado da lista
remover_predicado(Predicado) :-
    retract(Predicado).

% Exibe os botões para o usuário selecionar a origem e o destino
handle_buttons_on_interface([], D, _, _).
handle_buttons_on_interface([Predicado|Predicados], D, P1, P2) :-
    arg(1, Predicado, X),

    arg(2, Predicado, Tail),
    arg(1, Tail, Y),

    arg(2, Tail, Tail2),
    arg(2, Tail2, Nome),

    write('Ponto ('),write(X),write(','),write(Y),writeln(')'),

    handle_button_of_state(X, Y, Nome, D, P1, P2),

    NewP2 is P2 + 20,

    handle_buttons_on_interface(Predicados, D, P1, NewP2).

% Cria o botão na tela
handle_button_of_state(X, Y, Nome, D, P1, P2) :-      % Conjunto de pontos(X,Y), instância da tela, valores da posição de onde os pontos são exibidos (P1, P2)
    new(Botao, button(Nome)),
    send(Botao, message, message(@prolog, handle_click, X, Y, D)),
    send(Botao, position, point(P1, P2)),
    send(D, display, Botao).

% Trata o click do inicio
handle_click(X, Y, _) :-
    \+ user_point_start(_,_),           % Isso será verdade somente quando o a regra falhar para qualquer ponto X, Y. Isso indica que o usuário ainda não informou o ponto de origem
    assertz(user_point_start(X,Y)),
    write('Registrando inicio da localização: ('),write(X),write(','),write(Y),write(')'),nl.

% Trata o click
handle_click(X, Y, D) :-
    \+ user_point_stop(_,_),            % Isso será verdade somente quando o a regra falhar para qualquer ponto X, Y. Isso indica que o usuário ainda não informou o ponto de destino
    assertz(user_point_stop(X,Y)),
    write('Registrando fim da localização: ('),write(X),write(','),write(Y),write(')'),nl,

    % Com o ponto final, é possivel movimentar o avião
    user_point_start(Xi, Yi),

    thread_create(move_point(point(Xi, Yi, _), point(X, Y, _), D), ThreadId, []),

    % Limpo a base para os ponto incial e final para que o usuário possa escolher novamente
    retract(user_point_start(_,_)),
    retract(user_point_stop(_,_)).

main :-

    new(D, picture('Sistema de Controle de Trafego Aereo')),
    send(D, size, size(920, 800)),
    
    % Cria um objeto bitmap para a imagem
    new(B, bitmap('../assets/mapa.jpg')), % Substitua pelo caminho da sua imagem

    % Configure o tamanho e a posição do bitmap para cobrir a janela
    send(B, size, D?size),
    send(B, position, point(0, 0)),

    % Bitmap como background da janela
    send(D, display, B),
    send(D, open),
    

    findall((X, Y, Raio), point(X, Y, Raio, _), ListOfPointers),
    findall((X, Y, Raio, Nome), point(X, Y, Raio, Nome), ListOfPointers2),
    iterar_pontos(D, ListOfPointers),
    
    writeln('Predicados para os pontos:'),
    writeln(ListOfPointers),
    
    calc_distance_between_all_pointers(ListOfPointers),       % Adiciona o conhecimento da distância a base de dados
    findall((X1, Y1, X2, Y2, Distance), distance(X1, Y1, X2, Y2, Distance), ListOfPointersWithDistance),

    writeln('Predicado para a distância entre os pontos:'),
    writeln(ListOfPointersWithDistance),

    % intera sobre os pontos x1, y1, x2, y2 e desenha uma linha de conexão
    % draw_line_connection(ListOfPointersWithDistance, D),

    % Imprime os pontos para o usuário selecionar
    iterar_predicados(ListOfPointers),
    
    % Caso em que os pontos de partida são menores que os pontos de chegada
    % move_point(point(15,20,10), point(60,900,40), D).

    % Caso em que os pontos de partida são maiores que os pontos de chegada
    % move_point(point(50,90,40), point(15,20,10), D).

    obter_predicado_aleatorio(ListOfPointers, RandomPointer1, NewListOfPointers1),
    
    arg(1, RandomPointer1, A1),
    arg(2, RandomPointer1, Tail1),
    arg(1, Tail1, B1),

    % remover_predicado(point(A1, B1, _)),
    
    obter_predicado_aleatorio(NewListOfPointers1, RandomPointer2, NewListOfPointers2),

    arg(1, RandomPointer2, A2),
    arg(2, RandomPointer2, Tail2),
    arg(1, Tail2, B2),

    % remover_predicado(point(A2, B2, _)),

    obter_predicado_aleatorio(NewListOfPointers2, RandomPointer3, NewListOfPointers3),

    arg(1, RandomPointer3, A3),
    arg(2, RandomPointer3, Tail3),
    arg(1, Tail3, B3),

    % remover_predicado(point(A3, B3, _)),

    obter_predicado_aleatorio(NewListOfPointers3, RandomPointer4, _),

    arg(1, RandomPointer4, A4),
    arg(2, RandomPointer4, Tail4),
    arg(1, Tail4, B4),

    % remover_predicado(point(A4, B4, _)),

    write('Ponto aleatorio: '),writeln(RandomPointer1),
    write('Ponto aleatorio: '),writeln(RandomPointer2),
    write('Ponto aleatorio: '),writeln(RandomPointer3),
    write('Ponto aleatorio: '),writeln(RandomPointer4),

    % writeln('Px1:'),writeln(A1),writeln(B1),
    % writeln('Px2:'),writeln(A2),writeln(B2),
    % writeln('Px3:'),writeln(A3),writeln(B3),
    % writeln('Px4:'),writeln(A4),writeln(B4),

    handle_buttons_on_interface(ListOfPointers2, D, 10, 400),

    thread_create(move_point(point(A1, B1, _), point(A2, B2, _), D), ThreadId1, []),
    thread_create(move_point(point(A3, B3, _), point(A4, B4, _), D), ThreadId2, []),
    % thread_create(move_point(point(30,35,40), point(50,90,40), D), ThreadId2, []),

    thread_join(ThreadId1, _),
    thread_join(ThreadId2, _).

% Chamar o predicado para desenhar os círculos espalhados
:- initialization(main).