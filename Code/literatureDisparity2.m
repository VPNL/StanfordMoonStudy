% Parameters
I = 0.065;                 % interpupillary distance [m] (6.5 cm)
D = 15;                    % target distance [m]
elev_deg = linspace(0,90,361);         % elevation angles [deg]
elev = deg2rad(elev_deg);              % [rad]

% Vergence vs elevation:
% Effective horizontal baseline shrinks by cos(theta)
% Total vergence angle between the eyes (radians)
V_rad = 2 * atan( (I .* cos(elev)) ./ (2*D) );
V_deg = rad2deg(V_rad);                 % [deg], total between eyes

% Horizontal disparity vs elevation:
% Here we plot the binocular parallax of the target at D
% (equivalently, disparity if fixation were at optical infinity).
% If you instead fixate the target at D, the disparity of that target is 0.
disparity_arcmin = V_rad * (180/pi*60); % [arcmin]

% ---- Plotting ----
figure('Color','w','Position',[100 100 900 380]);

subplot(1,2,1);
plot(elev_deg, V_deg, 'LineWidth', 2);
grid on
xlabel('Elevation \theta (deg)');
ylabel('Vergence (deg, total)');
title(sprintf('Vergence vs Elevation (D=%.1f m, IPD=%.1f cm)', D, I*100));
xlim([0 90]);

subplot(1,2,2);
plot(elev_deg, disparity_arcmin, 'LineWidth', 2);
grid on
xlabel('Elevation \theta (deg)');
ylabel('Horizontal disparity (arcmin)');
title('Horizontal disparity vs Elevation (relative to infinity fixation)');
xlim([0 90]);

% Optional: show per-eye convergence (half the total vergence)
per_eye_deg = V_deg / 2;
disp(['Per-eye convergence at 0° elev: ', num2str(per_eye_deg(1), '%.4f'), ' deg']);
