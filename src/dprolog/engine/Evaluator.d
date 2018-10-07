module dprolog.engine.Evaluator;

import dprolog.data.token;
import dprolog.data.Term;
import dprolog.data.Variant;
import dprolog.data.Message;
import dprolog.util.functions;
import dprolog.util.UnionFind;
import dprolog.util.Either;
import dprolog.engine.Executor;
import dprolog.engine.UnificationUF;

import std.range;
import std.algorithm;

class Evaluator {

public:
  Either!(Message, Number) calc(Variant variant, UnificationUF unionFind) {
    Variant root = unionFind.root(variant);
    return root.term.token.castSwitch!(
      (BinaryOperator op) => calc(root.children.front, unionFind).bind!(
        x => calc(root.children.back, unionFind).fmap!(
          y => op.calc(x, y)
        )
      ),
      (UnaryOperator op) => calc(root.children.front, unionFind).fmap!(
        x => op.calc(x)
      ),
      (Number num) => Right!(Message, Number)(num),
      (Object _) => Left!(Message, Number)(Message("Warning: Evaluation Fault"))
    );
  }

}
