classdef ClockAdjustment < handle
    properties
        clk LocalClock
        ptp SlaveFSM
        phy PHY
    end
    methods
        function obj = ClockAdjustment(clk, ptp, phy)
            obj.clk = clk;
            obj.ptp = ptp;
            obj.phy = phy;
        end

        function syntonize(obj)
            obj.clk.f = obj.phy.f_rx;
        end

        function offset(obj)
            obj.clk.phi = obj.clk.phi + (obj.ptp.last_offset * (2*pi*obj.clk.f));
        end

    end
end