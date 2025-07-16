classdef TSU < handle
    properties
    clk LocalClock
    phase_detector PhaseDetector
    end
    methods
        function obj = TSU(clk, phase_detector)
            obj.clk = clk;
            obj.phase_detector = phase_detector;
        end

        function tsp = getTimestamp(obj)
            ts = floor(obj.clk.phi / (2*pi*obj.clk.f));
            tsp = ts + obj.phase_detector.getPhaseDiff();
            disp(ts)
        end
    end
end
