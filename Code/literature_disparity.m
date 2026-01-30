% Parameters
IPD  = 0.065;                  % interpupillary distance [m] (6.5 cm typical)
Dmin = 10; Dmax = 150;         % distance range [m]
N    = 500;                    % number of samples
D    = linspace(Dmin, Dmax, N);

% >>> Choose fixation distance for disparity reference:
Dfix = Inf;                    % use Inf for "optical infinity" fixation
% Dfix = 2;                    % example: uncomment to use 2 m fixation instead

% --- Helper inline functions ---
verg = @(dist) 2*atan(IPD./(2*dist));        % total vergence (radians) to distance 'dist'
deg  = @(rad) (rad*180/pi);
arcmin = @(rad) (rad*180/pi*60);

% 1) Vergence vs distance (total angle between eyes, degrees)
vergence_deg = deg(verg(D));

% 2) Horizontal disparity vs distance (arcmin), for a target on midline
%    relative to the fixation plane at Dfix.
if isinf(Dfix)
    disparity_arcmin = arcmin(verg(D));                 % relative to infinity
else
    disparity_arcmin = arcmin(verg(D) - verg(Dfix));    % relative to finite Dfix
end

% --- Plotting ---
figure('Color','w','Position',[100 100 900 380]);

subplot(1,2,1);
plot(D, vergence_deg, 'LineWidth',2);
grid on;
xlabel('Distance D (m)');
ylabel('Vergence (degrees, total)');
title(sprintf('Vergence vs Distance (IPD = %.1f cm)', IPD*100));
xlim([Dmin Dmax]);

subplot(1,2,2);
plot(D, disparity_arcmin, 'LineWidth',2);
grid on;
xlabel('Distance D (m)');
ylabel('Horizontal disparity (arcmin)');
if isinf(Dfix)
    ttl = 'Disparity vs Distance (fixation at infinity)';
else
    ttl = sprintf('Disparity vs Distance (fixation at %.2f m)', Dfix);
end
title(ttl);
xlim([Dmin Dmax]);
