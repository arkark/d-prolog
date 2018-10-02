module dprolog.util.Maybe;

import std.stdio;
import std.format;
import std.functional;

struct Maybe(T) {

private:
  T value = T.init;
  bool _isJust = false;

package:
  this(T value) {
    this.value = value;
    this._isJust = true;
  }

public:
  @property bool isJust() {
    return _isJust;
  }

  @property bool isNone() {
    return !_isJust;
  }

  @property T get() in {
    assert(isJust);
  } do {
    return value;
  }

  Maybe!T opAssign(T value) in {
    static if (is(typeof(value is null))) {
      assert(value !is null);
    }
  } do {
    this.value = value;
    this._isJust = true;
    return this;
  }

  string toString() {
    if (isJust) {
      return format!"Maybe!%s(%s)"(typeid(T), value);
    } else {
      return format!"Maybe!%s(None)"(typeid(T));
    }
  }

}

Maybe!T Just(T)(T value) in {
  static if (is(typeof(value is null))) {
    assert(value !is null);
  }
} do {
  return Maybe!T(value);
}

Maybe!T None(T)() {
  return Maybe!T();
}

// fmap :: Maybe!T -> (T -> S) -> Maybe!S
Maybe!S fmap(alias fun, T, S = typeof(unaryFun!fun(T.init)))(Maybe!T m)
if(is(typeof(unaryFun!fun(T.init)) : S)) {
  return m.isNone ? None!S : Just!S(unaryFun!fun(m.get));
}

// fmap :: bool -> (lazy T) -> Maybe!T
Maybe!T fmap(T)(bool isTrue, lazy T value) {
  return isTrue ? Just(value) : None!T;
}

// bind :: Maybe!T -> (T -> Maybe!S) -> Maybe!S
Maybe!S bind(alias fun, T, _ : Maybe!S = typeof(unaryFun!fun(T.init)), S)(Maybe!T m)
if(is(typeof(unaryFun!fun(T.init)) == Maybe!S)) {
  return m.isNone ? None!S : unaryFun!fun(m.get);
}

void apply(alias fun, bool enforce = false, T)(Maybe!T m)
if(is(typeof(unaryFun!fun(T.init)))) {
  if (m.isNone) {
    assert(!enforce, "`m` is None, but should be Just because the enforce option is true.");
  } else {
    fun(m.get);
  }
}

unittest {
  writeln(__FILE__, ": test Maybe");

  Maybe!T find(T)(T[] xs, T value) {
    import std.algorithm : find;
    import std.range;
    auto res = xs.find(value);
    if (res.empty) return None!T;
    return Just(res.front);
  }

  int[] as = [1, 2, 3];
  assert(find(as, 3) == Just(3));
  assert(find(as, 4) == None!int);

  assert(find(as, 3).fmap!"a*a" == Just(3*3));
  assert(find(as, 4).fmap!"a*a" == None!int);

  assert(
    as.Just.bind!(
      xs => find(xs, 3)
    ) == Just(3)
  );
  assert(
    as.Just.bind!(
      xs => find(xs, 4)
    ) == None!int
  );
  assert(
    None!(int[]).bind!(
      xs => find(xs, 3)
    ) == None!int
  );
}
