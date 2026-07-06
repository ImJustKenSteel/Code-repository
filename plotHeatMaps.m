function fig = plotHeatMaps(resultsTable, animalNo, bins_baseline, bins_drug, bins_reversal, stimType, intensity)

% Time vectors
trialAve_ts      = linspace(-0.1,0.2,9000);
trialAve_ts_ramp = linspace(-0.1,0.3,12000);

deadChannels = 15;
yCoords = 12.5:12.5:800;

% Put bins into one list
bins_all = {bins_baseline, bins_drug, bins_reversal};

% -------------------------------------------------------
% Precompute color ranges (faster & correct)
% -------------------------------------------------------
if stimType == 1
    dataFull = resultsTable.timeCourse_4Hz(animalNo,:,:,:);
else
    dataFull = resultsTable.timeCourse_InnNox(animalNo,:,intensity,:,:);
end
colormapRange = [min(dataFull,[],'all')  max(dataFull,[],'all')];

% -------------------------------------------------------
%  MAIN PLOTTING
% -------------------------------------------------------
fig = figure("Name", "Heatmap for AnimalNo: " + animalNo);

if stimType == 1

    for period = 1:3
        bins = bins_all{period};

        tmpData = squeeze(mean(resultsTable.timeCourse_4Hz(animalNo,:,:,bins),4));
        tmpData(deadChannels,:) = [];

        subplot(3,1,period);
        colormap("turbo")
        imagesc(trialAve_ts*1000, yCoords, tmpData);
        set(gca,'CLim', colormapRange)

        applyFormatting(yCoords, [-10 50]);   % <-- stimType 1 always uses [-10 90]
    end


elseif stimType == 2

    subIdx = 1;

    for period = 1:3
        bins = bins_all{period};

        tmpData = squeeze(mean(resultsTable.timeCourse_InnNox(animalNo,:,intensity,:,bins),5));
        tmpData(deadChannels,:) = [];

        for latency = 1:2
            subplot(3,2,subIdx);
            imagesc(trialAve_ts_ramp*1000, yCoords, tmpData);

            if latency == 1
                set(gca, 'CLim', colormapRange)
                tWindow = [-10 90];
            else
                clim([0 300]);
                tWindow = [100 200];
            end

            applyFormatting(yCoords, tWindow);
            subIdx = subIdx + 1;
        end
    end

end

end


% -------------------------------------------------------
% Helper formatting function (UPDATED)
% -------------------------------------------------------
function applyFormatting(yCoords, timeWindow)

    colormap jet

    % Apply consistent plot settings
    makePlotsConsistant(timeWindow, [0 max(yCoords) + diff(yCoords(1:2))/2],"Time (ms)", "Depth (μm)", []);
    yticks(0:100:800)

    % Adjust Y label
    ylh = ylabel('Depth (μm)', 'FontWeight','bold');
    ylh.Position(1) = ylh.Position(1) - 2;

    % Colorbar
    h_bar = colorbar;
    ylabel(h_bar, "Amplitude (μV)", 'FontWeight','bold','FontSize',12);

end
