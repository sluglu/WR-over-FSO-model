% classdef SlaveNode
%     properties
%         clock SlaveClock
%         fsm SlaveFSM
%         old_time
%     end
% 
%     methods
%         function obj = SlaveNode(clock, fsm)
%             if nargin > 0
%                 obj.clock = clock;
%                 obj.fsm = fsm;
%             else
%                 obj.clock = SlaveClock();
%                 obj.fsm = SlaveFSM();
%             end
%             obj.old_time = 0;
%         end
% 
%         function [obj, msgs] = step(obj, sim_time, rx_freq)
%             dt = sim_time - obj.old_time;
%             obj.clock = obj.clock.syntonize(rx_freq);
%             if(obj.fsm.synced)
%                 obj.clock = obj.clock.correct_offset(obj.fsm.last_offset);
%             end
%             obj.clock = obj.clock.advance(dt);
%             ts = obj.clock.phi / (2*pi*obj.clock.f0);
%             [obj.fsm, msgs] = obj.fsm.step(ts);
%             obj.old_time = sim_time;
%         end
% 
%         function obj = receive(obj, msg)
%             ts = obj.clock.phi / (2*pi*obj.clock.f0);
%             obj.fsm = obj.fsm.receive(msg, ts);
%         end
% 
%         function obj = syntonize(obj, rx_freq)
%             obj.clock = obj.clock.syntonize(rx_freq);
%         end
%     end
% end
% 

classdef SlaveNode
    properties
        clock SlaveClock
        fsm SlaveFSM
        last_correction_time  % Track when we last applied correction
    end

    methods
        function obj = SlaveNode(clock, fsm)
            if nargin > 0
                obj.clock = clock;
                obj.fsm = fsm;
            else
                obj.clock = SlaveClock();
                obj.fsm = SlaveFSM();
            end
            obj.last_correction_time = -inf;  % Initialize to ensure first correction
        end

        function [obj, msgs] = step(obj, sim_time, rx_freq)
            % Advance clock to current simulation time
            obj = obj.advance_to_time(sim_time);
            
            % Apply syntonization if frequency is provided
            if nargin > 2 && ~isempty(rx_freq)
                obj.clock = obj.clock.syntonize(rx_freq);
            end
            
            % Apply offset correction only once per sync cycle
            if obj.fsm.synced && sim_time > obj.last_correction_time
                obj.clock = obj.clock.correct_offset(obj.fsm.last_offset);
                obj.last_correction_time = sim_time;
                obj.fsm.synced = false;  % Reset sync flag after correction
            end
            
            % Get current timestamp from clock
            ts = obj.clock.phi / (2*pi*obj.clock.f0);
            
            % Step FSM
            [obj.fsm, msgs] = obj.fsm.step(ts);
        end

        function obj = receive(obj, msg, sim_time)
            % Advance clock to message reception time
            obj = obj.advance_to_time(sim_time);
            
            % Get timestamp when message is received
            ts = obj.clock.phi / (2*pi*obj.clock.f0);
            
            % Pass message to FSM
            obj.fsm = obj.fsm.receive(msg, ts);
        end
        
        function obj = advance_to_time(obj, target_time)
            % Get current time from clock
            current_time = obj.clock.phi / (2*pi*obj.clock.f0);
            
            % Calculate time difference
            dt = target_time - current_time;
            
            % Only advance if we're moving forward in time
            if dt > 0
                obj.clock = obj.clock.advance(dt);
            end
        end
        
        function obj = syntonize(obj, rx_freq)
            obj.clock = obj.clock.syntonize(rx_freq);
        end
    end
end

