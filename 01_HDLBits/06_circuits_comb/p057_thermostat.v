// HDLBits Problem 57: Thermostat
// Author: Debjit Das | JGEC ECE

module top_module (input too_cold, too_hot, mode, fan_on,
    output heater, aircon, fan);
    assign {heater, aircon} = {mode & too_cold, ~mode & too_hot};
    assign fan = heater | aircon | fan_on;
endmodule
