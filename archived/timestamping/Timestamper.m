classdef Timestamper
    methods
        function obj = Timestamper()
        end
        
        function ts = getTimestamp(obj, clk)
            ts = clk.phi / (2*pi*clk.f0);
        end
    end
end

