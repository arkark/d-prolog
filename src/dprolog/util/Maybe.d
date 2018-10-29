module dprolog.util.Maybe;

import std.stdio;
import std.format;
import std.functional;
import std.traits;

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

  @property T get() in(isJust) do {
    return value;
  }

  Maybe!T opAssign(T value) in (!isNull(value)) do {
    this.value = value;
    this._isJust = true;
    return this;
  }

  bool opEquals(T2)(Maybe!T2 that) {
    alias T1 = T;
    if (this.isJust != that.isJust) return false;
    if (this.isJust) {
      return this.get == that.get;
    } else {
      return true;
    }
  }

  bool opEquals(S)(S that)
  if (!isInstanceOf!(TemplateOf!Maybe, S)) {
    static if (is(S : T)) {
      return isJust && this.get == value;
    } else {
      return false;
    }
  }

  string toString() {
    if (isJust) {
      return format!"Maybe!%s(%s)"(typeid(T), value);
    } else {
      return format!"Maybe!%s(None)"(typeid(T));
    }
  }

}

private struct Dummy {
  bool opEquals(O)(O o) {
    return false;
  }
}

private bool isNull(T)(T value) {
  static if (is(typeof(value is null))) {
    return (
      isPointer!T ||
      is(T == class) ||
      is(T == interface) ||
      is(T == function) ||
      is(T == delegate)
    ) && value is null;
  } else {
    return false;
  }
}

Maybe!T Just(T)(T value) in (!isNull(value)) do {
  return Maybe!T(value);
}

Maybe!T None(T)() {
  return Maybe!T();
}

Maybe!Dummy None() {
  return None!Dummy;
}

// fmap :: Maybe!T -> (T -> S) -> Maybe!S
template fmap(alias fun, T) {
  static if (!is(T == Dummy)) {
    static assert(is(typeof(unaryFun!fun(T.init))));
    alias S = typeof(unaryFun!fun(T.init));
  } else {
    alias S = T;
  }
  Maybe!S fmap(Maybe!T m) {
    if (m.isNone) {
      return None!S;
    } else {
      static if (!is(T == Dummy)) {
        return Just!S(unaryFun!fun(m.get));
      } else {
        assert(false);
      }
    }
  }
}

// fmap :: bool -> (lazy T) -> Maybe!T
Maybe!T fmap(T)(bool isTrue, lazy T value) {
  return isTrue ? Just(value) : None!T;
}

// fmap :: bool -> (() -> T) -> Maybe!T
template fmap(alias fun) {
  static if (is(typeof(fun()))) {
    alias T = typeof(fun());
    Maybe!T fmap(bool isTrue) {
      return isTrue ? Just(fun()) : None!T;
    }
  }
}

// bind :: Maybe!T -> (T -> Maybe!S) -> Maybe!S
template bind(alias fun, T) {
  static if (!is(T == Dummy)) {
    static assert(isInstanceOf!(Maybe, typeof(unaryFun!fun(T.init))));
    alias S = TemplateArgsOf!(typeof(unaryFun!fun(T.init)))[0];
  } else {
    alias S = T;
  }
  Maybe!S bind(Maybe!T m) {
    if (m.isNone) {
      return None!S;
    } else {
      static if (!is(T == Dummy)) {
        return unaryFun!fun(m.get);
      } else {
        assert(false);
      }
    }
  }
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
  assert(find(as, 3) == 3);
  assert(find(as, 4) == None);

  assert(find(as, 3).fmap!"a*a" == 3*3);
  assert(find(as, 4).fmap!"a*a" == None);

  assert(None.fmap!"a*a" == None);

  assert(
    as.Just.bind!(
      xs => find(xs, 3)
    ) == 3
  );
  assert(
    as.Just.bind!(
      xs => find(xs, 4)
    ) == None
  );
  assert(
    None.bind!(
      xs => find(xs, 3)
    ) == None
  );
}
