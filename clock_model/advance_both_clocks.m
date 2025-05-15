function [clock1, clock2] = advance_both_clocks(clock1, clock2, delay_s)
    clock1 = clock1.wait(delay_s);
    clock2 = clock2.wait(delay_s);
end