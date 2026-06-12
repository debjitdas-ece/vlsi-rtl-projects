// HDLBits Problem 56: Ring or vibrate
// Author: Debjit Das | JGEC ECE

module top_module (input ring, input vibrate_mode,
    output ringer, output motor);
    assign {ringer, motor} = {ring & ~vibrate_mode, ring & vibrate_mode};
endmodule
