// Minimal Verilator main that runs the timing testbench AND writes the coverage file
// (Verilator 5.x --binary's built-in main does not write coverage.dat).
#include "verilated.h"
#include "verilated_cov.h"
#include "Vtb_top.h"
int main(int argc, char** argv) {
  VerilatedContext* ctx = new VerilatedContext;
  ctx->commandArgs(argc, argv);
  Vtb_top* top = new Vtb_top{ctx};
  while (!ctx->gotFinish()) {
    top->eval();
    if (!top->eventsPending()) break;
    ctx->time(top->nextTimeSlot());
  }
  top->final();
  ctx->coveragep()->write("build/cov/coverage.dat");
  delete top; delete ctx;
  return 0;
}
