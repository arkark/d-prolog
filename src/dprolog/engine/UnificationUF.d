module dprolog.engine.UnificationUF;

import dprolog.data.Variant;
import dprolog.util.UnionFind;

alias UnificationUF = UnionFind!(
  Variant,
  (Variant a, Variant b) => !a.isVariable ? -1 : !b.isVariable ? 1 : 0
);
