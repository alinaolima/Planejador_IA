
%------------------------------------------------------------------------------------
% PLANEJADOR COM LIMITE DE PROFUNDIDADE - EVITA LOOP INFINITO
%------------------------------------------------------------------------------------

:- discontiguous estado_inicial/2.
:- discontiguous estado_meta/2.

% ------------------ DOMÍNIO ------------------
block(a). block(b). block(c). block(d).
place(1). place(2). place(3). place(4). place(5). place(6).
object(X) :- block(X); place(X).

size(a, 1). size(b, 1). size(c, 2). size(d, 3).

seguro_de_empilhar(Baixo, Cima) :-
    size(Baixo, SB), size(Cima, SC),
    SB =< SC.

% ------------------ AÇÕES ------------------
can(move(Block, From, To), [clear(Block), clear(To), on(Block, From), seguro_de_empilhar(Block, To)]) :-
    block(Block),
    object(From),
    object(To),
    From \== To,
    Block \== To.

adds(move(X, From, To), [on(X, To), clear(From)]).
deletes(move(X, From, To), [on(X, From), clear(To)]).

% ------------------ PLANEJAMENTO LIMITADO ------------------
plan_limitado(_, Goals, [], _) :- satisfied(_, Goals).
plan_limitado(State, Goals, [], _) :- satisfied(State, Goals).
plan_limitado(State, Goals, Plan, Limite) :-
    Limite > 0,
    append(PrePlan, [Action], Plan),
    select(State, Goals, Goal),
    achieves(Action, Goal),
    can(Action, _),
    preserves(Action, Goals),
    can(Action, Cond),
    regress(Goals, Action, Cond, RegressedGoals),
    NovoLimite is Limite - 1,
    plan_limitado(State, RegressedGoals, PrePlan, NovoLimite).

% ------------------ SUPORTE ------------------
satisfied(State, Goals) :- delete_all(Goals, State, []).

select(_, Goals, Goal) :- member(Goal, Goals).

achieves(Action, Goal) :- adds(Action, Goals), member(Goal, Goals).

preserves(Action, Goals) :-
    deletes(Action, Relations),
    \+ (member(Goal, Relations), member(Goal, Goals)).

regress(Goals, Action, Condition, RegressedGoals) :-
    adds(Action, AddList),
    delete_all(Goals, AddList, RestGoals),
    addnew(Condition, RestGoals, RegressedGoals).

addnew([], L, L).
addnew([Goal | _], Goals, _) :- impossible(Goal, Goals), !, fail.
addnew([X | L1], L2, L3) :- member(X, L2), !, addnew(L1, L2, L3).
addnew([X | L1], L2, [X | L3]) :- addnew(L1, L2, L3).

delete_all([], _, []).
delete_all([X | L1], L2, Diff) :- member(X, L2), !, delete_all(L1, L2, Diff).
delete_all([X | L1], L2, [X | Diff]) :- delete_all(L1, L2, Diff).

impossible(on(X, X), _) :- !.

% ------------------ IMPRESSÃO ------------------
print_result([]).
print_result([Action | Rest]) :-
    write(Action), nl,
    print_result(Rest).

% ------------------ ESTADOS ------------------
estado_inicial(1, [on(a,3), on(b,3), on(c,2), on(d,1), clear(a), clear(b), clear(c), clear(6)]).
estado_meta(1,    [on(a,1), on(b,3), on(c,2), on(d,4), clear(b), clear(c), clear(d), clear(6)]).

estado_inicial(2, [on(a,1), on(b,3), on(c,2), on(d,4), clear(b), clear(c), clear(d), clear(6)]).
estado_meta(2,    [on(d,4), on(c,d), on(b,c), on(a,b), clear(a), clear(6)]).

estado_inicial(3, [on(a,1), on(b,3), on(c,2), on(d,4), clear(b), clear(c), clear(d), clear(6)]).
estado_meta(3,    [on(a,3), on(b,3), on(c,2), on(d,1), clear(a), clear(b), clear(c), clear(6)]).

estado_inicial(4, [on(d,4), on(c,d), on(b,c), on(a,b), clear(a), clear(6)]).
estado_meta(4,    [on(a,1), on(b,3), on(c,2), on(d,4), clear(b), clear(c), clear(d), clear(6)]).

% ------------------ TESTES ------------------
testar_situacao(N) :-
    estado_inicial(N, Estado),
    estado_meta(N, Meta),
    plan_limitado(Estado, Meta, Plano, 20),  % Limite de 20 passos
    format('Plano encontrado para situação ~w:~n', [N]),
    maplist(writeln, Plano).

