module dprolog.util;

bool instanceOf(T)(Object obj) {
    return cast(T) obj !is null;
}
