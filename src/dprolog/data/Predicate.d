module dprolog.data.Predicate;

import dprolog.data.Term;
import dprolog.data.Variant;
import dprolog.engine.UnificationUF;

interface Predicate {
  alias UnificateRecFun = bool delegate(Variant, UnificationUF);

  bool isMatch(const Term term);
  bool unificate(Variant variant, UnificationUF unionFind, UnificateRecFun unificateRecFun);
}
