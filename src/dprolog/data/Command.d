module dprolog.data.Command;

import dprolog.data.Term;

interface Command {
  bool isMatch(Term term);
  void execute(Term term);
}
