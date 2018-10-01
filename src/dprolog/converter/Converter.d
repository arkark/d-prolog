module dprolog.converter.Converter;

import dprolog.engine.Messenger;

// Converter: S => T

interface Converter(S, T) {

  void run(S src);
  T get();
  void clear();
  bool hasError() @property;
  Message errorMessage() @property;

}
