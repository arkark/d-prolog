module dprolog.sl.SL;

import dprolog.core.Shell;
import dprolog.core.Linenoise;
import dprolog.engine.Messenger;
import dprolog.util.Message;
import dprolog.util.Either;

import std.conv;
import std.algorithm;
import std.range;
import std.array;
import std.typecons;
import std.concurrency : Generator, yield;
import core.thread;

@property SL_ SL() {
  static SL_ instance;
  if (!instance) {
    instance = new SL_();
  }
  return instance;
}

private class SL_ {
  void run() {
    getSLGenerator().apply!(
      msg => Messenger.writeln(msg),
      (gen) {
        while(!gen.empty) {
          auto sl = gen.front;
          gen.popFront;
          Linenoise.clearScreen;
          foreach(line; sl) {
            Messenger.add(InfoMessage(line));
          }
          Messenger.showAll();
          Thread.sleep(20.msecs);
        }
        Linenoise.clearScreen;
      }
    );
  }

private:
  Either!(Message, Generator!(string[])) getSLGenerator() {
    return Shell.getColumns.bind!(
      columns => Shell.getLines.fmap!(
        lines => tuple!("columns", "lines")(columns, lines)
      )
    ).fmap!(
      size => new Generator!(string[])({
        int columns = size.columns;
        int lines = size.lines;
        int slWidth = getSLWidth;
        int slHeight = getSLHeight;
        string[] spaceLines = "".repeat(max(0, lines - slHeight) / 2).array;
        foreach(i; 0..columns+slWidth) {
          int diff = columns - i - 1;
          string padding = ' '.repeat(max(0, diff)).array;
          auto sl = makeSL(i).map!(
            str => padding ~ str
          ).map!(
            str => str[clamp(-diff, 0, $)..$]
          ).map!(
            str => str[0..min(columns, $)]
          ).array;
          yield(spaceLines ~ sl);
        }
      })
    );
  }

  int getSLWidth() {
    auto sl = makeSL(0);
    return sl.map!"a.length".reduce!max.to!int;
  }

  int getSLHeight() {
    auto sl = makeSL(0);
    return sl.length.to!int;
  }

  string[] makeSL(int frame) in(frame >= 0) do {
    string[] head = headGen[frame%$];
    string[] tail = tailGen[frame%$];
    string[] smoke = smokeGen[frame/2%$];
    return smoke ~ zip(head, tail).map!"a[0] ~ a[1]".array;
  }

  enum string[][] headGen = [
    [
      `      ====        ________                ___________ `,
      `  _D _|  |_______/        \__I_I_____===__|_________| `,
      `   |(_)---  |   H\________/ |   |        =|___ ___|   `,
      `   /     |  |   H  |  |     |   |         ||_| |_||   `,
      `  |      |  |   H  |__--------------------| [___] |   `,
      `  | ________|___H__/__|_____/[][]~\_______|       |   `,
      `  |/ |   |-----------I_____I [][] []  D   |=======|__ `,
      `__/ =| o |=-~~\  /~~\  /~~\  /~~\ ____Y___________|__ `,
      ` |/-=|___|=    ||    ||    ||    |_____/~\___/        `,
      `  \_/      \O=====O=====O=====O_/      \_/            `,
    ], [
      `      ====        ________                ___________ `,
      `  _D _|  |_______/        \__I_I_____===__|_________| `,
      `   |(_)---  |   H\________/ |   |        =|___ ___|   `,
      `   /     |  |   H  |  |     |   |         ||_| |_||   `,
      `  |      |  |   H  |__--------------------| [___] |   `,
      `  | ________|___H__/__|_____/[][]~\_______|       |   `,
      `  |/ |   |-----------I_____I [][] []  D   |=======|__ `,
      `__/ =| o |=-~~\  /~~\  /~~\  /~~\ ____Y___________|__ `,
      ` |/-=|___|=O=====O=====O=====O   |_____/~\___/        `,
      `  \_/      \__/  \__/  \__/  \__/      \_/            `,
    ], [
      `      ====        ________                ___________ `,
      `  _D _|  |_______/        \__I_I_____===__|_________| `,
      `   |(_)---  |   H\________/ |   |        =|___ ___|   `,
      `   /     |  |   H  |  |     |   |         ||_| |_||   `,
      `  |      |  |   H  |__--------------------| [___] |   `,
      `  | ________|___H__/__|_____/[][]~\_______|       |   `,
      `  |/ |   |-----------I_____I [][] []  D   |=======|__ `,
      `__/ =| o |=-O=====O=====O=====O \ ____Y___________|__ `,
      ` |/-=|___|=    ||    ||    ||    |_____/~\___/        `,
      `  \_/      \__/  \__/  \__/  \__/      \_/            `,
    ], [
      `      ====        ________                ___________ `,
      `  _D _|  |_______/        \__I_I_____===__|_________| `,
      `   |(_)---  |   H\________/ |   |        =|___ ___|   `,
      `   /     |  |   H  |  |     |   |         ||_| |_||   `,
      `  |      |  |   H  |__--------------------| [___] |   `,
      `  | ________|___H__/__|_____/[][]~\_______|       |   `,
      `  |/ |   |-----------I_____I [][] []  D   |=======|__ `,
      `__/ =| o |=-~O=====O=====O=====O\ ____Y___________|__ `,
      ` |/-=|___|=    ||    ||    ||    |_____/~\___/        `,
      `  \_/      \__/  \__/  \__/  \__/      \_/            `,
    ], [
      `      ====        ________                ___________ `,
      `  _D _|  |_______/        \__I_I_____===__|_________| `,
      `   |(_)---  |   H\________/ |   |        =|___ ___|   `,
      `   /     |  |   H  |  |     |   |         ||_| |_||   `,
      `  |      |  |   H  |__--------------------| [___] |   `,
      `  | ________|___H__/__|_____/[][]~\_______|       |   `,
      `  |/ |   |-----------I_____I [][] []  D   |=======|__ `,
      `__/ =| o |=-~~\  /~~\  /~~\  /~~\ ____Y___________|__ `,
      ` |/-=|___|=   O=====O=====O=====O|_____/~\___/        `,
      `  \_/      \__/  \__/  \__/  \__/      \_/            `,
    ], [
      `      ====        ________                ___________ `,
      `  _D _|  |_______/        \__I_I_____===__|_________| `,
      `   |(_)---  |   H\________/ |   |        =|___ ___|   `,
      `   /     |  |   H  |  |     |   |         ||_| |_||   `,
      `  |      |  |   H  |__--------------------| [___] |   `,
      `  | ________|___H__/__|_____/[][]~\_______|       |   `,
      `  |/ |   |-----------I_____I [][] []  D   |=======|__ `,
      `__/ =| o |=-~~\  /~~\  /~~\  /~~\ ____Y___________|__ `,
      ` |/-=|___|=    ||    ||    ||    |_____/~\___/        `,
      `  \_/      \_O=====O=====O=====O/      \_/            `,
    ],
  ];

  enum string[][] tailGen = [
    [
      `                              `,
      `                              `,
      `    _________________         `,
      `   _|                \_____A  `,
      ` =|                        |  `,
      ` -|                        |  `,
      `__|________________________|_ `,
      `|__________________________|_ `,
      `   |_D__D__D_|  |_D__D__D_|   `,
      `    \_/   \_/    \_/   \_/    `,
    ],
  ];

  enum string[][] smokeGen = [
    [
      `                    (  ) (@@) ( )  (@)  ()    @@    O     @     O     @      O`,
      `               (@@@)`,
      `           (    )`,
      `        (@@@@)`,
      `      (   )`,
    ], [
      `                      (  ) (@@) ( )  (@)  ()    @@    O     @     O     @      O`,
      `                 (@@@)`,
      `            (    )`,
      `         (@@@@)`,
      `      (   )`,
    ], [
      `                        (  ) (@@) ( )  (@)  ()    @@    O     @     O     @`,
      `                  (@@@)`,
      `             (    )`,
      `         (@@@@)`,
      `      (   )`,
    ], [
      `                    (@@) (  ) (@)  ( )  @@    ()    @     O     @     O      @`,
      `               (   )`,
      `           (@@@@)`,
      `        (    )`,
      `      (@@@)`,
    ], [
      `                      (@@) (  ) (@)  ( )  @@    ()    @     O     @     O      @`,
      `                 (   )`,
      `            (@@@@)`,
      `         (    )`,
      `      (@@@)`,
    ], [
      `                        (@@) (  ) (@)  ( )  @@    ()    @     O     @     O`,
      `                  (   )`,
      `             (@@@@)`,
      `         (    )`,
      `      (@@@)`,
    ],
  ];
}
