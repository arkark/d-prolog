
% Result is the factorial of N.
factorial(N, Result) :- factorial2(N, 1, Result).

factorial2(0, Result, Result).
factorial2(N, Acc, Result) :-
    N > 0,
    Acc1 is N * Acc,
    N1 is N - 1,
    factorial2(N1, Acc1, Result).
