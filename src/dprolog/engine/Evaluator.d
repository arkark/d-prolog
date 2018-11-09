module dprolog.engine.Evaluator;

import dprolog.data.token;
import dprolog.data.Variant;
import dprolog.util.Message;
import dprolog.util.Either;
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
      (Object _) => Left!(Message, Number)(WarningMessage("Warning: Evaluation Fault"))
    );
  }

}
