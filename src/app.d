
import dprolog.engine.Engine;
import dprolog.util.GetOpt;

void main(string[] args) {
  Engine engine = new Engine;

  GetOpt.run(engine, args);
  if (GetOpt.shouldExit()) return;

  while(!engine.isHalt) {
    engine.next();
  }
}
