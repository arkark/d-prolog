member(X, [X|Xs]).
member(X, [Y|Ys]) :- member(X, Ys).

append([], Xs, Xs).
append([X|Xs], Ys, [X|Zs]) :- append(Xs, Ys, Zs).

reverse(Xs, Ys) :- reverse2(Xs, [], Ys).
reverse2([], Ys, Ys).
reverse2([X|Xs], Ys, Zs) :- reverse2(Xs, [X|Ys], Zs).
