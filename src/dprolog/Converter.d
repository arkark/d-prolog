module dprolog.Converter;

// Converter: S => T

interface Converter(S, T) {

    void run(S src);
    T get();
    void clear();
    bool hasError() @property;
    dstring errorMessage() @property;

}
