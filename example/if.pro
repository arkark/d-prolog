
% conditional expressions:
%
%   ?- if (1 < 2, X = 1, X = 2).
%   X = 1.
%
%   ?- if (1 > 2, X = 1, X = 2).
%   X = 2.

if(Cond, Then, _) :- Cond, !, Then.
if(_, _, Else) :- Else.
