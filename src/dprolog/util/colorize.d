module dprolog.util.colorize;

import std.format;
import std.traits;

enum ForegroundColor {
  Black = 30,
  Red,
  Green,
  Yellow,
  Blue,
  Magenta,
  Cyan,
  White,
}

enum BackgroundColor {
  Black = 40,
  Red,
  Green,
  Yellow,
  Blue,
  Magenta,
  Cyan,
  White
}

T colorizeForeground(T)(T text, ForegroundColor color)
if (isNarrowString!T) {
  return format!"\033[%dm%s\033[0m"(color, text);
}

T colorizeBackground(T)(T text, BackgroundColor color)
if (isNarrowString!T) {
  return format!"\033[%dm%s\033[0m"(color, text);
}

import std.stdio;

unittest {
  writeln(__FILE__, ": test color print");
  foreach(bgColor; EnumMembers!BackgroundColor) {
    foreach(fgColor; EnumMembers!ForegroundColor) {
      writeln("backgroundColor: ", bgColor, ", foregroundColor: ", fgColor);
      "Hello world!".colorizeBackground(bgColor).colorizeForeground(fgColor).writeln;
    }
  }
}
