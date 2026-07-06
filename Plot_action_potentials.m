%in .continuous directory
unitNo=235;
unitChNo=51;
load("CorrectMap.mat");
[data,ts]= load_open_ephys_data_faster("100_RhythmData_CH" + mapping.CorrectMap(unitChNo) + ".continuous");
filter_freqs = [300, 6000];  % Bandpass filter frequencies
fs = 30000;  % Sampling rate
[b, a] = butter(4, filter_freqs / (fs / 2));  % 4th order Butterworth filter
filtered=filtfilt(b,a,data*-1);

%in Kilosort4 directory
load("OEPInfo.mat");
Fs=30000;
t_first=OEPinfo.t_first;
ts=ts-t_first/30000;
load("events_sorted_ks.mat");
mech_events=readtable("samples.xlsx");
clusterID = readNPY('spike_clusters.npy');
samples = readNPY('spike_times.npy');
clusterInfo = readtable('cluster_info.tsv',"FileType","delimitedtext","Delimiter",'tab', "TextType","string");
clusterInfo.group = categorical(clusterInfo.group);
clusterInfo.KSLabel = categorical(clusterInfo.KSLabel);
clusterInfo.cluster_id = clusterInfo.cluster_id;
clusterList = unique(clusterInfo.cluster_id(clusterInfo.KSLabel == 'good'));
unitSamples = double(samples(clusterID == unitNo));


startTimes=events.mech(1,:);
endTimes=events.mech(25,:);
startSamples=round(startTimes*fs)-90000;
endSamples=round(endTimes*fs)-90000;
%plotting spikes
mechLabels=["Brush", "0.6g vF", "1g vF", "2g vF", "4g vF", "8g vF", "15g vF", "26g vF", "Pinch"];
spikeShapes = figure;
mechSpikes  = figure;

clf(spikeShapes)
clf(mechSpikes)

for period = 1:3

    tmpfiltered = filtered(startTimes(period)*30000-90000 : endTimes(period)*30000+180000, 1);
    tmpts = ts(startTimes(period)*30000-90000 : endTimes(period)*30000+180000, 1);

    [spikeData, spikeDatats] = multi_trial_matrix( ...
        tmpfiltered, tmpts, ...
        unitSamples(unitSamples > startSamples(period) & unitSamples < endSamples(period)) / 30000, ...
        30000, [0.001 0.001]);

    %% ---- Figure 1: Spike shapes ----
    figure(spikeShapes)
    subplot(1,3,period)
    plot(spikeDatats, spikeData)
    ylim([-200 300])
    title(['Period ' num2str(period)])

    %% ---- Figure 2: Mechanical signal + spikes ----
    figure(mechSpikes)
    subplot(3,1,period)
    plot(tmpts, tmpfiltered)
    hold on

    for spikeSample = unitSamples'
        spikeIndex = round(spikeSample - startSamples(period) + 1);

        if spikeIndex > 0 && spikeIndex <= length(tmpfiltered)
            window = -30:30;
            spikeWindow = spikeIndex + window;
            validIdx = spikeWindow > 0 & spikeWindow <= length(tmpfiltered);
            spikeWindow = spikeWindow(validIdx);

            plot(tmpts(spikeWindow), tmpfiltered(spikeWindow), 'r')
        end
    end

    xlim([tmpts(1) tmpts(end)])
    set(gca,'XAxisLocation','top')
    xticks(events.mech(1:3:end, period))
    xticklabels(mechLabels)
    hold off

end
