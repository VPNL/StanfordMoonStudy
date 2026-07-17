
% plot how large should objects be so they generate a x degree visual angle
visual_angle=[0.5 1 1.5 2 5 10 20 45];
visual_angle_rad=visual_angle*pi/180;
moon_distance=384400*1000; % in m

max_exponent=ceil(log10(moon_distance));
max_exponent=5;
d=10.^(0:.1:max_exponent); % in meters
for i=1:length(visual_angle_rad)
    s(i,:)=2*d*tan(visual_angle_rad(i)/2);
end

figure('Color',[ 1 1 1],'Units','normalized','Position',[ 0 0 .8 .4]);

subplot(1,2,1)
plot(d,s,'LineWidth',3);hold on
plot(d,10*ones(size(d)),'k-')
plot(d,.1*ones(size(d)),'k-')
plot(10*ones(size(d)+3),[10^-3 10^-2 10^-1 d],'k-')
plot(100*ones(size(d)+3),[10^-3 10^-2 10^-1 d],'k-')
plot(1000*ones(size(d)+3),[10^-3 10^-2 10^-1 d],'k-')


for i=1:length(visual_angle)
    legendtext{i}=num2str(visual_angle(i));
end
legend(legendtext,'Location','NorthWest','box','off')
set (gca,'xscale','log') 
set (gca,'yscale','log') 
xlabel('distance log10(distance in m)');
ytitle=sprintf('size to generate %5.2 degree angle',visual_angle);
ylabel(ytitle)
set(gca,'FontSize',12)
colormap('hsv')

% titlestring=sprintf('tan of %5.2f [deg] visual angle=%5.6f',visual_angle,tan(visual_angle_rad));
% title(titlestring)
grid on
axis('square')
subplot(1,2,2)
bar(visual_angle,tan(visual_angle_rad));
xlabel('visual angle [deg])');
ylabel('tan(visual_angle(rad)')
grid on 
set(gca,'FontSize',12)
