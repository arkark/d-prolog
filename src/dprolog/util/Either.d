module dprolog.util.Either;

import std.stdio;
import std.format;
import std.functional;
import std.traits;

struct Either(L, R) {

private:
  L _left = L.init;
  R _right = R.init;

  bool _isLeft;

package:
  this(L left) {
    _left = left;
    _isLeft = true;
  }

  this(R right) {
    _right = right;
    _isLeft = false;
  }

public:
  @property bool isLeft() {
    return _isLeft;
  }

  @property bool isRight() {
    return !_isLeft;
  }

  @property L left() in(isLeft) do {
    return _left;
  }

  @property R right() in(isRight) do {
    return _right;
  }

  Either!(L, R) opAssign(L left) in {
    static if (is(typeof(left is null))) {
      assert(left !is null);
    }
  } do {
    _left = left;
    _isLeft = true;
    return this;
  }

  Either!(L, R) opAssign(R right) in {
    static if (is(typeof(right is null))) {
      assert(right !is null);
    }
  } do {
    _right = right;
    _isLeft = false;
    return this;
  }

  bool opEquals(L2, R2)(Either!(L2, R2) that) {
    alias L1 = L, R1 = R;
    if (this.isLeft != that.isLeft) return false;
    if (this.isLeft) {
      return this.left == that.left;
    } else {
      return this.right == that.right;
    }
  }

  bool opEquals(T)(T that)
  if (!isInstanceOf!(TemplateOf!Either, T)) {
    static if (is(T : L)) {
      return isLeft && left == that;
    } else if (is(T : R)) {
      return isRight && right == that;
    } else {
      return false;
    }
  }

  string toString() {
    if (isLeft) {
      return format!"Left!(%s)(%s)"(typeid(L), left);
    } else {
      return format!"Right!(%s)(%s)"(typeid(R), right);
    }
  }

}

Either!(L, Dummy) Left(L)(L left) in {
  static if (is(typeof(left is null))) {
    assert(left !is null);
  }
} do {
  return Either!(L, Dummy)(left);
}

Either!(L, R) Left(L, R)(L left) in {
  static if (is(typeof(left is null))) {
    assert(left !is null);
  }
} do {
  return Either!(L, R)(left);
}

private struct Dummy {
  bool opEquals(O)(O o) {
    return false;
  }
}

Either!(Dummy, R) Right(R)(R right) in {
  static if (is(typeof(right is null))) {
    assert(right !is null);
  }
} do {
  return Either!(Dummy, R)(right);
}

Either!(L, R) Right(L, R)(R right) in {
  static if (is(typeof(right is null))) {
    assert(right !is null);
  }
} do {
  return Either!(L, R)(right);
}


// fmap :: Either!(L, R1) -> (R1 -> R2) -> Either!(L, R2)
template fmap(alias fun, L, R1) {
  static if(!is(R1 == Dummy)) {
    static assert(is(typeof(unaryFun!fun(R1.init))));
    alias R2 = typeof(unaryFun!fun(R1.init));
  } else {
    alias R2 = R1;
  }
  Either!(L, R2) fmap(Either!(L, R1) e) {
    if (e.isLeft) {
      return Left!(L, R2)(e.left);
    } else {
      static if (!is(R1 == Dummy)) {
        return Right!(L, R2)(unaryFun!fun(e.right));
      } else {
        assert(false);
      }
    }
  }
}

// bind :: Either!(L, R1) -> (R1 -> Either!(L, R2)) -> Either!(L, R2)
template bind(alias fun, L, R1) {
  static if (!is(R1 == Dummy)) {
    static assert(isInstanceOf!(Either, typeof(unaryFun!fun(R1.init))));
    alias E2 = typeof(unaryFun!fun(R1.init));
    alias L2 = TemplateArgsOf!E2[0];
    alias R2 = TemplateArgsOf!E2[1];
    static assert(is(L == L2) || is(L == Dummy));
  } else {
    alias R2 = R1;
    alias L2 = L;
    static assert(!is(L == Dummy));
  }
  Either!(L2, R2) bind(Either!(L, R1) e) {
    if (e.isLeft) {
      static if (!is(L == Dummy)) {
        return Left!(L, R2)(e.left);
      } else {
        assert(false);
      }
    } else {
      static if (!is(R1 == Dummy)) {
        return unaryFun!fun(e.right);
      } else {
        assert(false);
      }
    }
  }
}

unittest {
  writeln(__FILE__, ": test Either");

  Either!(string, T) find(T)(T[] xs, T value) {
    import std.algorithm : find;
    import std.range;
    auto res = xs.find(value);
    if (res.empty) return Left!(string, int)(format!"%s is not found"(value));
    return Right!(string, int)(res.front);
  }

  int[] as = [1, 2, 3];
  assert(find(as, 3) == 3);
  assert(find(as, 4) == format!"%s is not found"(4));

  assert(find(as, 3).fmap!"a*a" == 3*3);
  assert(find(as, 4).fmap!"a*a" == format!"%s is not found"(4));

  assert(Left("nothing").fmap!"a*a" == "nothing");

  assert(
    as.Right.bind!(
      xs => find(xs, 3)
    ) == 3
  );
  assert(
    as.Right.bind!(
      xs => find(xs, 4)
    ) == format!"%s is not found"(4)
  );
  assert(
    Left("nothing").bind!(
      xs => find(xs, 3)
    ) == "nothing"
  );
}
