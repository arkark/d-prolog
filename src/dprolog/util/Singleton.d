module dprolog.util.Singleton;

import std.format;

static class Singleton(T) {
  private static T instance;
  static auto opDispatch(string name, Args...)(auto ref Args args) {
    if (!instance) {
      instance = new T();
    }
    return mixin(format!"instance.%s(args)"(name));
  }
}
