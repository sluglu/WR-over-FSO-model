classdef SlaveClock < WRClock
    methods
        function obj = SlaveClock(f0, phi0, noise_profile)
            if nargin > 0
                args = {f0, phi0, noise_profile};
            else
                args = {};
            end
            obj@WRClock(args{:});
        end

        function obj = syntonize(obj, f_new)
            obj.noise_profile = obj.noise_profile.reset();
            obj.f = f_new;
        end
    end
end