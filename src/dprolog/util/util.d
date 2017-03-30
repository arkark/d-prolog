module dprolog.util.util;

bool instanceOf(S, T)(const T obj) {
    return cast(S) obj !is null;
}
