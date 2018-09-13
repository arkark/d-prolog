module dprolog.data.Pattern;

import dprolog.data.Term;

interface Pattern {
  bool isMatch(Term term);
  void execute(Term term);
}
