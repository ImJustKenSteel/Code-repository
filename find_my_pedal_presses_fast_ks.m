function [sample_times_of_pedal_presses] = find_my_pedal_presses_fast_ks(continuous_file)
    %% PARAMS
    % continuous_file = .continuous filename (full path if not running in the same
    %                   folder) for the pedal input
    % sample_rate = the sample rate of recordings, usually 30,000

    %% CONSTANTS
    threshold = 1.4;       % voltage level for detecting pedal presses
    min_duration = 1;      % minimum duration above threshold (in seconds)
    reset_duration = 0.5;    % duration below threshold to allow a new press detection

    %% LOAD AND PREPROCESS DATA
    % Load data and timestamps from the continuous file
    [data_raw, ts_raw, ~] = load_open_ephys_data(continuous_file);
%     data_raw=data_raw+4.5;
    sample_rate = 1 / (ts_raw(2) - ts_raw(1));  % calculate sample rate from timestamps
    min_samples = round(min_duration * sample_rate);
    reset_samples = round(reset_duration * sample_rate);

    %% DETECT SUSTAINED THRESHOLD CROSSES
    sustained_above_threshold = true;  % track if in a sustained period above threshold
    last_press_end = -Inf;              % timestamp of the last detected press end
    sample_times_of_pedal_presses = []; % store pedal press timestamps

    for i = 1:length(data_raw)
        % Check if voltage is above or below threshold
        if data_raw(i) > threshold
            % If sustained_above_threshold is not active, check if this block is sustained
            if ~sustained_above_threshold
                % Look forward to see if this period is sustained
                if i + min_samples - 1 <= length(data_raw) && all(data_raw(i:i + min_samples - 1) > threshold)
                    % Mark the beginning of a sustained period above threshold
                    sustained_above_threshold = true;
                    % Record the timestamp if the last press ended more than reset duration ago
                    if ts_raw(i) > last_press_end + reset_duration
                        sample_times_of_pedal_presses = [sample_times_of_pedal_presses; ts_raw(i)];
                    end
                end
            end
        else
            % Reset sustained_above_threshold when voltage goes below threshold for reset duration
            if sustained_above_threshold && i + reset_samples - 1 <= length(data_raw) && all(data_raw(i:i + reset_samples - 1) < threshold)
                sustained_above_threshold = false;
                last_press_end = ts_raw(i); % update last press end timestamp
            end
        end
    end
end
