module dprolog.data.Predicate;

import dprolog.data.Term;
import dprolog.data.Variant;
import dprolog.engine.Executor;
import dprolog.engine.UnificationUF;

interface Predicate {
  alias UnificateRecFun = UnificateResult delegate(Variant, UnificationUF);

  bool isMatch(const Term term);
  UnificateResult unificate(Variant variant, UnificationUF unionFind, UnificateRecFun unificateRecFun);
}
