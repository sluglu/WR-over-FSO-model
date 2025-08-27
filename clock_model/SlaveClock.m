classdef SlaveClock < WRClock
    methods
        function obj = SlaveClock(f0, t0, noise_profile)
            if nargin > 0
                args = {f0, t0, noise_profile};
            else
                args = {};
            end
            obj@WRClock(args{:});
        end

        % function obj = syntonize(obj, f_new)
        %     obj.noise_profile = obj.noise_profile.reset();
        %     obj.t_accum = 0;
        %     obj.f = f_new;
        % end

        function obj = correct_offset(obj, time_offset)
            phase_offset = time_offset * (2*pi*obj.f0);
            obj.phi = obj.phi - phase_offset;
        end
    end
end