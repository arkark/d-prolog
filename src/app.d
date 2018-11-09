import dprolog.engine.Engine;
import dprolog.util.GetOpt;

void main(string[] args) {
  GetOpt.run(args);
  if (GetOpt.shouldExit()) return;

  while(!Engine.isHalt) {
    Engine.next();
  }
}
