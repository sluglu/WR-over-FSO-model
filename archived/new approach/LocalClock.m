classdef LocalClock < handle
    properties
        f             % Current frequency (Hz)
        phi           % Current phase (radians)
    end

    methods
        function obj = LocalClock(f)
            obj.f = f;
            obj.phi = 0;
        end

        function obj = advance(obj, dt)
            obj.phi = obj.phi + 2 * pi * obj.f * dt;
        end

        function obj = reset(obj)
            obj.phi = 0;
        end
    end
end
