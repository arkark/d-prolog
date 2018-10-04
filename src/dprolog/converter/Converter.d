module dprolog.converter.Converter;

import dprolog.data.Message;

// Converter: S => T

interface Converter(S, T) {

  void run(S src);
  T get();
  void clear();
  @property bool hasError();
  @property Message errorMessage();

}
