module dprolog.util;

bool instanceOf(T)(const Object obj) {
    return cast(T) obj !is null;
}
