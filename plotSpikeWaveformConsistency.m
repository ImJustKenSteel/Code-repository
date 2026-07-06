function plotSpikeWaveformConsistency(expID, unitID, stimType, binNo, mechWindow)

%% Parameters
Fs = 30000;
spikeWin = 30;
filter_freqs = [300 6000];

parentDir = pwd;

%% Load Kilosort data
outPath = getExperimentPath(expID, "kilosort4", true, parentDir);
cd(outPath);

clusterID   = readNPY('spike_clusters.npy');
samples     = readNPY('spike_times.npy');
clusterInfo = readtable('cluster_info.tsv',"FileType","delimitedtext","Delimiter",'tab',"TextType","string");

unitSamples = double(samples(clusterID == unitID));
unitChNo    = clusterInfo.ch(clusterInfo.cluster_id == unitID);

load("events_sorted_ks.mat");

%% Load raw data
outPath = getExperimentPath(expID, "recordnode", true, parentDir);
cd(outPath);

load("CorrectMap.mat");
[data, ~] = load_open_ephys_data_faster( ...
    "100_RhythmData_CH" + mapping.CorrectMap(unitChNo) + ".continuous");

[b,a] = butter(4, filter_freqs/(Fs/2));
filtered = filtfilt(b,a,data*-1);
%% Collect spikes
selectedSpikeMask = false(size(unitSamples));

switch stimType
    case "fourHz"

        for b = binNo
            trialOnsets = events.fourHz(:,b);
            trialOnsets_samp = round(trialOnsets * Fs);

            winStart = round(0.05 * Fs);
            winEnd   = round(0.10 * Fs);

            for tr = 1:numel(trialOnsets_samp)
                selectedSpikeMask = selectedSpikeMask | ...
                    (unitSamples >= trialOnsets_samp(tr)-winStart & ...
                     unitSamples <= trialOnsets_samp(tr)+winEnd);
            end
        end

    case "mech"

        % Which mech EVENTS to include
        nEvents = size(events.mech,1);

        if isempty(mechWindow)
            eventIdx = 1:nEvents;
        elseif size(mechWindow,2) == 2
            eventIdx = [];
            for r = 1:size(mechWindow,1)
                eventIdx = [eventIdx mechWindow(r,1):mechWindow(r,2)];
            end
        else
            eventIdx = mechWindow(:)';
        end

        eventIdx(eventIdx < 1 | eventIdx > nEvents) = [];

        for b = binNo
            trialOnsets = events.mech(eventIdx,b);
            trialOnsets_samp = round(trialOnsets * Fs);

            % Full mech response window (unchanged)
            winStart = round(1 * Fs);
            winEnd   = round(3 * Fs);

            for tr = 1:numel(trialOnsets_samp)
                selectedSpikeMask = selectedSpikeMask | ...
                    (unitSamples >= trialOnsets_samp(tr)-winStart & ...
                     unitSamples <= trialOnsets_samp(tr)+winEnd);
            end
        end
end

selectedSpikes = unitSamples(selectedSpikeMask);

%% Extract waveforms
wfMat = nan(length(selectedSpikes), 2*spikeWin+1);

for s = 1:length(selectedSpikes)
    idx = (selectedSpikes(s)-spikeWin):(selectedSpikes(s)+spikeWin);
    if idx(1) < 1 || idx(end) > length(filtered)
        continue
    end
    wfMat(s,:) = filtered(idx);
end

wfMat = wfMat(~any(isnan(wfMat),2), :);

%% Plot
t = (-spikeWin:spikeWin)/Fs * 1000;

figure; hold on
plot(t, wfMat', 'Color', [0.30 0.65 0.65]);
plot(t, mean(wfMat,1), 'k', 'LineWidth', 2);

xlabel('Time (ms)')
ylabel('Voltage (a.u.)')
title(sprintf('Spike waveform consistency | %s | Unit %d', stimType, unitID))
box off

cd(parentDir)
end
