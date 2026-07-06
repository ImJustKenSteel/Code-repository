figure
mechintensities=([1,4,6,8,9]);
mechlabels=(["Brush", "2g von Frey", "8g von Frey", "26g von Frey", "Pinch"]);
% subplot(3,4,1)
% bar(squeeze(mean(WDR_fourHz(:,1,:,1))));
count =1;
for n =1:3
    for i =1:5
        subplot(3,5,count);
        bar(squeeze(mean(meanSpikeCounts_mech(:,n,:,mechintensities(i)))));
        xticks(1:5:36);
        xticklabels(-2:1:5);
        ylim([0 25]);
        ylabel("Action potentials")
        xlabel("Time/ Seconds")
        subtitle(mechlabels(i));
        count=count+1;
    end
end

figure
rampintensities=([3,4,6,7,8]);
ramplabels=(["0.2mA", "0.4mA", "1.6mA", "3.2mA", "3.2mA 2ms"]);
subplot(3,4,1)
count =1;
for n =1:3
    for i =1:5
        subplot(3,5,count);
        bar(squeeze(mean(WDR_ramp(:,n,:,rampintensities(i)))));
        xticks(1:10:41);
        xticklabels(-0.1:0.1:0.3);
        ylim([0 1.5]);
        ylabel("Action potentials")
        xlabel("Time/ Seconds")
        subtitle(ramplabels(i));
        count=count+1;
    end
end


figure
mechintensities=([1,4,6,8,9]);
mechlabels=(["Brush", "2g von Frey", "8g von Frey", "26g von Frey", "Pinch"]);
subplot(3,4,1)
bar(squeeze(mean(WDR_fourHz(:,1,:,1))));
count =1;
for n =1:3
    for i =1:5
        subplot(3,5,count);
        bar(squeeze(mean(LTMR_mech(:,n,:,mechintensities(i)))));
        xticks(1:5:36);
        xticklabels(-2:1:5);
        ylim([0 25]);
        ylabel("Action potentials")
        xlabel("Time/ Seconds")
        subtitle(mechlabels(i));
        count=count+1;
    end
end

figure
rampintensities=([3,4,6,7,8]);
ramplabels=(["0.2mA", "0.4mA", "1.6mA", "3.2mA", "3.2mA 2ms"]);
subplot(3,4,1)
count =1;
for n =1:3
    for i =1:5
        subplot(3,5,count);
        bar(squeeze(mean(LTMR_ramp(:,n,:,rampintensities(i)))));
        xticks(1:10:41);
        xticklabels(-0.1:0.1:0.3);
        ylim([0 1.5]);
        ylabel("Action potentials")
        xlabel("Time/ Seconds")
        subtitle(ramplabels(i));
        count=count+1;
    end
end

figure
period=(["Baseline", "Tapentadol", "Atipamezole"]);
for n=1:3
    subplot(1,3,n)
    bar(squeeze(mean(WDR_fourHz(:,n,:))));
    xticks(1:5:31)
    xticklabels(-0.05: 0.05: 0.25)
    xlabel("Time/ Seconds")
    ylim([0 1.2])
    ylabel("Action potentials")
    subtitle(period(n))
end
for i=1:3
    xticks(ax(i),1:5:31)
    xticklabels(ax(i),-0.05: 0.05: 0.25)
    xlabel(ax(i),"Time/ Seconds")
    ylim(ax(i),[0 1])
    ylabel(ax(i),"Action potentials")
    subtitle(ax(i),period(i))    
end
ax = findall(gcf, 'Type', 'axes');

for i=1:15
    xticks(ax(i),1:10:41)
    xticklabels(ax(i),-0.1:0.1:0.3)
    xlabel(ax(i), "Time/ Seconds")
end