classdef ProgressTracker < handle
    properties
        count = 0
        total
        h % waitbar handle
    end

    methods
        function obj = ProgressTracker(N)
            obj.total = N;
        end

        function start(obj)
            obj.h = waitbar(0, 'Processing...');
        end

        function update(obj)
            obj.count = obj.count + 1;
            if isvalid(obj.h)
                waitbar(obj.count / obj.total, obj.h, ...
                    sprintf('Progress: %d / %d', obj.count, obj.total));
            end
        end

        function finish(obj)
            if isvalid(obj.h)
                close(obj.h);
            end
        end
    end
end