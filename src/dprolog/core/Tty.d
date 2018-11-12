module dprolog.core.Tty;

import dprolog.util.Either;
import dprolog.util.Message;

import core.sys.posix.sys.ioctl;
import std.stdio;

Either!(Message, int) getColumns() {
  auto size = winsize();
  if (ioctl(stdout.fileno(), TIOCGWINSZ, &size) == -1) {
    return ErrorMessage("Cannot get column size").Left!(Message, int);
  }
  return Right!(Message, int)(size.ws_col);
}

Either!(Message, int) getRows() {
  auto size = winsize();
  if (ioctl(stdout.fileno(), TIOCGWINSZ, &size) == -1) {
    return ErrorMessage("Cannot get row size").Left!(Message, int);
  }
  return Right!(Message, int)(size.ws_row);
}
