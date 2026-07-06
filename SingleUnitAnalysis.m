function [spikeCounts] = SingleUnitAnalysis(directory,stimType, doPlot)
%SingleUnitAnalysis
%Input 1 = directory of data. Needs to contain events_sorted_ks.mat which
%contains curated TTLs for fourHz, ramp, MUA and mech. Also needds
%spike_clusters.npy, spike_times.npy, cluster_info.tsv, OEPinfo.

if nargin < 3
    doPlot = true;   % default = plot everything
end


%loads in clustering data and events
cd(directory);

load("OEPInfo.mat");
Fs=30000;
ts = 0:1/Fs:(1/Fs) * sum(OEPinfo.info.nsamples);
t_first=OEPinfo.t_first;
load("events_sorted_ks.mat");
mech_events=readtable("samples.xlsx");
clusterID = readNPY('spike_clusters.npy');
samples = readNPY('spike_times.npy');
clusterInfo = readtable('cluster_info.tsv',"FileType","delimitedtext","Delimiter",'tab', "TextType","string");
clusterInfo.group = categorical(clusterInfo.group);
clusterInfo.KSLabel = categorical(clusterInfo.KSLabel);
clusterInfo.cluster_id = clusterInfo.cluster_id;
clusterList = unique(clusterInfo.cluster_id(clusterInfo.KSLabel == 'good'));

%makes directory for Figures
if ~exist(fullfile(pwd,'Figures'), 'dir'), mkdir(fullfile(pwd,'Figures')); end

if stimType == "fourHz"
    N = size(events.fourHz, 2);

    switch N
        case 3
            rows = 1; cols = 3;
        case 6
            rows = 2; cols = 3;
        case 16
            rows = 4; cols = 4;
        otherwise
            % fallback: square layout
            rows = ceil(sqrt(N));
            cols = ceil(N / rows);
    end
    bins_fourHz = -0.05:.01:.25;
    spikeCounts=zeros(length(clusterList),width(events.fourHz), size(bins_fourHz,2)-1,length (events.fourHz));
    % spikeTimes = cell(length(clusterList), width(events.fourHz), length(events.fourHz));
    for n=1:length(clusterList)
        tmp_clusterID = clusterList(n);
        tmp_samples = samples(clusterID == tmp_clusterID);
        if doPlot
            figure
            figName = ("Unit " + tmp_clusterID + " " + stimType + " responses");
            set(gcf, 'Name', figName);
        end

        for binNo= 1:width(events.fourHz)
            subplot(rows,cols,binNo);
            stimulationType="4Hz ";
            tmp_events= events.fourHz(:,binNo);
            for eventNo=1:length(tmp_events)

                spikesInRange = ts(tmp_samples)-tmp_events(eventNo);
                spikesInRange = spikesInRange(spikesInRange >= bins_fourHz(1) & spikesInRange <= bins_fourHz(end));
                % spikeTimes{n, binNo, eventNo} =spikesInRange;
                spikeCounts(n,binNo,:,eventNo) = histcounts(spikesInRange,bins_fourHz);
                if eventNo==1
                    figName= ("Unit " + tmp_clusterID + " " + stimType + " Rasterplot");
                    set(gcf, 'Name', figName); % Set the name of the current figure
                    set(gca, 'YDir', 'reverse');
                end
                if doPlot
                rasterplot(spikesInRange,[eventNo eventNo-1], 'k')
                hold on
                end
            end
            if doPlot
            xlim([-0.01 0.1])
            ylim([0 height(events.fourHz)])
            xlabel("Time/ seconds")
            ylabel("Trials")
            end
        end

        sgtitle("Unit" + tmp_clusterID + " " + stimulationType + "Rasterplot")
        meanSpikeCounts = mean(spikeCounts, 4);  % Mean across events
        if doPlot
        cd(pwd +"\Figures");
        savefig(figName);
        close(figName);
        cd(directory)
        end
    end
    save("spikeCounts_4Hz", "spikeCounts", "meanSpikeCounts");

elseif stimType =="ramp"
    N = size(events.ramp, 2);
    rampCurrent = [50 100 200 400 800 1600 3200 3200];   % Stimulus current (μA)
    switch N
        case 3
            rows = 1; cols = 3;
        case 6
            rows = 2; cols = 3;
        case 16
            rows = 4; cols = 4;
        otherwise
            % fallback: square layout
            rows = ceil(sqrt(N));
            cols = ceil(N / rows);
    end
    bins_ramp = -0.1:.01:1;
    spikeCounts=zeros(length(clusterList),width(events.ramp), size(bins_ramp,2)-1,8);
    % spikeTimes = cell(length(clusterList), width(events.ramp), length(events.ramp));

    meanSpikeCounts=zeros(length(clusterList), width(events.ramp), size(bins_ramp,2)-1, 8);
    for n=1:length(clusterList)
        tmp_clusterID = clusterList(n);
        tmp_samples = samples(clusterID == tmp_clusterID);

        if doPlot
            figure
            figName = ("Unit " + tmp_clusterID + " " + stimType + " responses");
            set(gcf, 'Name', figName);
        end

        for binNo= 1:width(events.ramp)
            subplot(rows,cols,binNo);
            for intensity= 1:length(events.ramp)

                spikesInRange = ts(tmp_samples)-events.ramp(intensity,binNo);
                spikesInRange = spikesInRange(spikesInRange >= bins_ramp(1) & spikesInRange <= bins_ramp(end));
                if doPlot
                rasterplot(spikesInRange,[intensity intensity-1], 'k')
                hold on
                end
                spikeCounts(n,binNo,:,intensity) = histcounts(spikesInRange,bins_ramp);
                % spikeTimes{n, binNo, intensity} =spikesInRange;


            end
            if binNo==1
                set(gca, 'YDir', 'reverse');
            end
            if doPlot
            xlabel("Time/ seconds")
            ylabel("Trials")
            xlim([-0.1 0.5])
            ylim([0 height(events.ramp)])
            yticklabels(rampCurrent)
            end
        end

        if doPlot
        sgtitle("Unit" + tmp_clusterID + " " + stimType + "Rasterplot")
        cd(pwd +"\Figures");
        savefig(figName);
        close(figName);
        cd(directory)
        end
    end
    for x=1:length(rampCurrent)
        meanSpikeCounts(:,:,:,x)= mean(spikeCounts(:,:,:,x:8:end),4);
    end

    save("spikeCounts_ramp", "spikeCounts", "meanSpikeCounts");

elseif stimType == "mech"
    N = size(events.mech, 2);

    switch N
        case 3
            rows = 1; cols = 3;
        case 6
            rows = 2; cols = 3;
        case 16
            rows = 4; cols = 4;
        otherwise
            % fallback: square layout
            rows = ceil(sqrt(N));
            cols = ceil(N / rows);
    end
    bins_mech =-2:.2:5;
    spikeCounts= zeros(length(clusterList), width(events.mech),size(bins_mech,2)-1, height(events.mech));
    % spikeTimes = cell(length(clusterList), width(events.mech), length(events.mech));

    mech_period = reshape(mech_events.Var2(:),height(events.mech),width(events.mech));
    mech_titles=reshape(mech_events.Var3(:),height(events.mech),width(events.mech));

    for n=1:length(clusterList)

        tmp_clusterID = clusterList(n);
        tmp_samples = samples(clusterID == tmp_clusterID);
        if doPlot
        figure
        figName= ("Unit " + tmp_clusterID + " " + stimType + " Rasterplot");
        set(gcf, 'Name', figName); % Set the name of the current figure
        set(gca, 'YDir', 'reverse');
        end
        for binNo= 1:width(events.mech)
            subplot(rows,cols,binNo)
            tmp_events= events.mech(:,binNo);
            for eventNo=1:length(tmp_events)
                spikesInRange = ts(tmp_samples)-tmp_events(eventNo);
                spikesInRange = spikesInRange(spikesInRange >= bins_mech(1) & spikesInRange <= bins_mech(end));
                if eventNo==1
                    figName= ("Unit " + tmp_clusterID + " " + stimType + " rasterplot");
                    set(gcf, 'Name', figName); % Set the name of the current figure
                    set(gca, 'YDir', 'reverse');
                end
                if doPlot
                rasterplot(spikesInRange,[eventNo eventNo-1], 'k')
                hold on
                spikeCounts(n,binNo,:,eventNo) = histcounts(spikesInRange,bins_mech);
                % spikeTimes{n, binNo, eventNo} =spikesInRange;
                end
            end
            if doPlot
            title(mech_period(1,binNo));
            xlabel("Time/ seconds");
            ylim([0 height(events.mech)]);
            xlim([-2 5]);
            yticks(0:1:height(events.mech));
            yticklabels(mech_titles(:,binNo));
            ylabel("Trials")
            end
        end
        if doPlot
        cd(pwd +"\Figures");
        savefig(figName);
        close(figName);
        cd(directory)
        end
    end
    save("spikeCounts_mech.mat", "spikeCounts");
elseif stimType=="MUA"


    N = size(events.MUA, 2);

    switch N
        case 3
            rows = 1; cols = 3;
        case 6
            rows = 2; cols = 3;
        case 16
            rows = 4; cols = 4;
        otherwise
            % fallback: square layout
            rows = ceil(sqrt(N));
            cols = ceil(N / rows);
    end

    events.MUA=(events.MUA-(t_first/30000));
    bins_MUA =0:.2:120;
    spikeCounts= zeros(length(clusterList), width(events.MUA),size(bins_MUA,2)-1);
    figure
    figName= ("All single units MUA");
    set(gcf, 'Name', figName); % Set the name of the current figure
    for n=1:length(clusterList)
        colour_codes = rand(n,3);   % each row = [R G B] between 0–1

        tmp_clusterID = clusterList(n);
        tmp_samples = samples(clusterID == tmp_clusterID);
        tmp_ch= clusterInfo.ch(clusterInfo.cluster_id==tmp_clusterID);
        for binNo= 1:width(events.MUA)
            subplot(rows,cols,binNo)
            tmp_events= events.MUA(:,binNo);
            spikesInRange = ts(tmp_samples)-tmp_events;
            spikesInRange = spikesInRange(spikesInRange >= bins_MUA(1) & spikesInRange <= bins_MUA(end));

            rasterplot(spikesInRange,[tmp_ch tmp_ch-1], colour_codes(n,:));

            set(gca, 'YDir', 'reverse');

            hold on
            spikeCounts(n,binNo,:) = histcounts(spikesInRange,bins_MUA);
            xticks(0:20:120);
            xticklabels(events.MUA(binNo):10:events.MUA(binNo)+120);
            xlabel("Time/ seconds");
            ylim([0 63]);
            ylabel("Channels")
        end

    end
    save(figName);
end