% function advance_clocks(varargin)
%     nargs = numel(varargin);
%     if nargs < 2
%         error('Usage: advance_clocks(clock1, ..., duration)');
%     end
% 
%     duration = varargin{end};
%     clocks = varargin(1:end-1);  % all but the last arg
% 
%     for k = 1:numel(clocks)
%         clocks{k}.tick(duration);
%     end
% end

function advance_clocks(varargin)
    nargs = numel(varargin);
    if nargs < 2
        error('Usage: advance_clocks(clock1, ..., total_duration)');
    end

    total_duration = varargin{end};
    clocks = varargin(1:end-1);

    % Assume all clocks use same tick resolution from frequency
    tick_period = 1 / clocks{1}.nominal_freq;
    N = round(total_duration / tick_period);

    for k = 1:numel(clocks)
        clk = clocks{k};

        % Effective dt vector
        dt_vec = tick_period * ones(1, N);

        % Advance total cycle count directly
        clk.cycle_count = clk.cycle_count + clk.frequency * sum(dt_vec);
        clk.frequency = clk.nominal_freq * (1 + clk.drift_ppb * 1e-9);
    end
end
