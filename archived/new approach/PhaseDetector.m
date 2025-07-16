classdef PhaseDetector < handle
    properties
    clk LocalClock
    phy PHY
    end
    methods
        function obj = PhaseDetector(clk, phy)
            obj.clk = clk;
            obj.phy = phy;
        end

        function phase_d = getPhaseDiff(obj)
            phase_d = obj.clk.phi - obj.phy.rx_phi;
        end
    end
end

