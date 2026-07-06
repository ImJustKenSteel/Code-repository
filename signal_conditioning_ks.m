%% Optimized Script for Processing OEP .continuous Files

% Set directory and file format
dir = "C:\OpenEphys\tmpFolder\2025-11-27_15-54-26\Record Node 104\";
file_prefix = '100_RhythmData_';  % Amend this to match the format of your files
file_suffix = '';
nChs = 64;  % Number of channels

%% Get TTLs
disp("Loading TTLs from events file...");
TTLs_all = load_OpenEphys_TTLs('100_RhythmData.events', 'channelNumbers', 0, 'transition', 'up');
TTLs = TTLs_all.timestamp+0.005*30000;  % Adjust for a small offset if needed

%% Preview TTLs for an example channel (optional)
% disp("Previewing TTLs...");
% fn_ = file_prefix + "CH1" + file_postfix + ".continuous";
% [data_ex, ts_ex, ~] = load_open_ephys_data(dir + fn_);
% figure; hold on;
% plot(ts_ex, data_ex);
% plot([TTLs, TTLs], [-200, 200], 'r');
% plot(TTLs, zeros(size(TTLs)), 'o');

%% Set up filters
filter_freqs = [300, 6000];  % Bandpass filter frequencies
fs = 30000;  % Sampling rate
[b, a] = butter(4, filter_freqs / (fs / 2));  % 4th order Butterworth filter

%% Define artifact removal window
  % Time window for artifact removal (in samples)

%% Prepare output directory
output_dir = dir + "post_conditioning";
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

%% Processing each channel with parallel loop
disp("Entering conditioning loop...");

for ch = 1:nChs  % Use parfor for parallel processing of each channel
    % Load raw data from .continuous file
    fn_raw = file_prefix + "CH" + num2str(ch) + ".continuous";
    [data, ts, ~] = load_open_ephys_data(fn_raw);
    disp("ChannelNo: " + ch);
    % Apply zero-phase filtering using filtfilt for bidirectional filtering
    filtered = filtfilt(b, a, data);

    % Remove artifacts around TTLs
    edited_file = blank_artefact_ea(filtered, ts, TTLs, removal_window);
    %     new_blank_ts = findpeaks(abs(edited_file),'MinPeakHeight',2000);
    %     edited_file = blank_artefact_ea(edited_file,ts,ts(new_blank_ts),removal_window);

    % Save the processed data to .mat file
    fn_edited = file_prefix + "CH" + num2str(ch) + ".mat";
    save(output_dir + "\" + fn_edited, "edited_file", '-v7.3');
    if (ch == 1)
        %         figure
        %         hold on
        %         plot(data(100000:900000));
        %         plot(filtered(100000:900000));
        %         plot(edited_file(100000:900000));
        %         hold off
        %         return
        %     end
    end
end
    %% Save metadata in the same folder
    [~, ts_raw, info] = load_open_ephys_data(dir + fn_raw);  % Load raw timestamps and metadata
    OEPinfo.info = info;
    OEPinfo.t_first = ts_raw(1);
    OEPinfo.artifact_removal_win = removal_window;
    save(output_dir + "\OEPInfo.mat", 'OEPinfo');

