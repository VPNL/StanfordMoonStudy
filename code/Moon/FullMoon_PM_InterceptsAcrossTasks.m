function [PerceptualInterscepts,AdjustedlInterscepts] = FullMoon_PM_InterceptsAcrossTasks(dataDir,basename, ResultsDir,lme_by_logRatio_by_Elevation_Perceptual,lme_by_logRatio_by_Elevation_Adjusted)

% [PerceptualInterscepts,AdjustedlInterscepts] = FullMoon_PM_InterceptsAcrossTasks(dataDir,basename, ResultsDir,lme_by_logRatio_by_Elevation_Perceptual,lme_by_logRatio_by_Elevation_Adjusted) 
% Function test if there is a relation between the intercepts estimates (PM at horizon) across tasks
% uses the lme models log2(perceptual magnification) ~ log2(elevation) + (1|ID) for each task
% (fixed slopes and random intercepts per participant)
% The plot the intercepts estimates of perceptual task against adjusted
% task and tests if there is a significant linear relation
%
%
% KGS 11/25


[feEfxPerceptual,feNamesPerceptual,feStatsPerceptual] = fixedEffects(lme_by_logRatio_by_Elevation_Perceptual )
[reEfxPerceptual,reNamesPerceptual,reStatsPerceptual] = randomEffects(lme_by_logRatio_by_Elevation_Perceptual );
PerceptualInterscepts=2.^[reEfxPerceptual+feEfxPerceptual(1)]; % these are the intercepts on a log2 scale so we need to take to power of 2 to get intercept value 
%PerceptualInterscepts=[reEfxPerceptual+feEfxPerceptual(1)]; % these are the intercepts on a log2 scale so we need to take to power of 2 to get intercept value 


[feEfxAdjusted,feNamesAdjusted,feStatsAdjusted] = fixedEffects(lme_by_logRatio_by_Elevation_Adjusted ); %% best model has random intercepts and same slope
[reEfxAdjusted,reNamesAdjusted,reStatsAdjusted] = randomEffects(lme_by_logRatio_by_Elevation_Adjusted ); % 
AdjustedlInterscepts=2.^[reEfxAdjusted+feEfxAdjusted(1)];
%AdjustedlInterscepts=[reEfxAdjusted+feEfxAdjusted(1)];

nsubjects=length(AdjustedlInterscepts);
maxval=max([AdjustedlInterscepts; PerceptualInterscepts ]);

xrange=[0:2:maxval];
[coeff_PA,int_coeff_PA,r,rint,stats_PA] = regress(PerceptualInterscepts,[AdjustedlInterscepts ones(size(AdjustedlInterscepts))]);
Estimated_y = polyval(coeff_PA,xrange);
figure('Color',[1 1 1], 'Name','Intercepts across tasks Moon')
hold on
plot(AdjustedlInterscepts, PerceptualInterscepts,'k.','MarkerSize',32);
plot(xrange,Estimated_y,'b-','LineWidth',3),

axis('equal');
xlim([0 maxval]);  ylim ([0 maxval]);
%set(gca,'XTick',xrange, 'XTickLabel', 2.^xrange,'YTick',xrange,'YTickLabel',2.^xrange,'box','off');
set(gca,'XTick',xrange, 'YTick',xrange,'box','off');
xlabel('Adjusted Intercept [degrees]')
ylabel('Perceptual Intercept [degrees]')
set(gca,'FontName','Avenir','FontSize',20)
titlestr=sprintf('R=%.2f F=%.2f p<%.3e\n',sqrt(stats_PA(1)), stats_PA(2), stats_PA(3));

title(titlestr,'FontSize',16)



% save file
filenamePNG=fullfile(ResultsDir,['FigS1_InterceptsAcrossTasks_' basename,'_', num2str(nsubjects),'.png']);
print(gcf,filenamePNG,'-dpng','-r600');
if ~exist(ResultsDir, 'dir')
    mkdir(ResultsDir);
end
