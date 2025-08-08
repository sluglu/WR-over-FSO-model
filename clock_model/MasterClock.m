classdef MasterClock < WRClock
    methods
        function obj = MasterClock(f0, t0, noise_profile)
            if nargin > 0
                args = {f0, t0, noise_profile};
            else
                args = {};
            end
            obj@WRClock(args{:});
        end
    end
end