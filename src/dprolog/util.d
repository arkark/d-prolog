module dprolog.util;

bool instanceOf(S, T)(const T obj) {
    return cast(S) obj !is null;
}
