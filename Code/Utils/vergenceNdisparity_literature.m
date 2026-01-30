% VergenceNdisparity_literature
%% Vergence & disparity table for a vector of distances
% Settings
IPD = 0.065;                                              % interpupillary distance [m], e.g., 6.5 cm
distances = [1 5 10 15 100 150 1000 1500 10000 15000];   % meters
stereo_threshold_arcsec = 10;     %  stereoacuity (arcsec), normal range 10-30 arcsec
csv_filename = 'vergence_disparity_table.csv';

% --- Core functions ---
verg_rad = @(D) 2*atan(IPD./(2*D));                 % total vergence (radians)
verg_deg = @(D) rad2deg(verg_rad(D));               % total vergence (degrees)
% derivative d/dD of 2*atan(IPD/(2D))  [radians per meter]
dVdD_rad = @(D) - IPD ./ (D.^2 .* (1 + (IPD./(2*D)).^2));

% Conversions
rad2arcmin = @(x) rad2deg(x)*60;
rad2arcsec = @(x) rad2deg(x)*3600;

% Compute columns
V_deg_total   = verg_deg(distances);
per_eye_deg   = V_deg_total/2;
V_arcmin_tot  = V_deg_total*60;
V_arcsec_tot  = V_deg_total*3600;

% Local disparity sensitivity (arcsec per +1 m) around each D
dVdD_arcsec_per_m = abs(dVdD_rad(distances)) * (180/pi) * 3600;

% Minimal resolvable depth step (meters) for given stereo threshold
% Guard against division by extremely small derivatives at huge distances:
eps_floor = 1e-12;
safe_dVdD = max(dVdD_arcsec_per_m, eps_floor);
min_depth_step_m = stereo_threshold_arcsec ./ safe_dVdD;

% Assemble table
T = table( ...
    distances(:), ...
    V_deg_total(:), ...
    per_eye_deg(:), ...
    V_arcmin_tot(:), ...
    V_arcsec_tot(:), ...
    dVdD_arcsec_per_m(:), ...
    min_depth_step_m(:), ...
    'VariableNames', { ...
        'Distance_m', ...
        'Vergence_deg_total', ...
        'Per_eye_deg', ...
        'Vergence_arcmin_total', ...
        'Vergence_arcsec_total', ...
        'Disparity_change_per_1m_arcsec_per_m', ...
        'Min_depth_step_for_threshold_m' ...
    });

% Display & save
disp(T);
writetable(T, csv_filename);
fprintf('Saved table to %s\n', csv_filename);

%% Notes:
% - Vergence is the total angle between eyes for a midline target at distance D.
% - "Disparity_change_per_1m_arcsec_per_m" is NOT a threshold; it tells you how many arcsec
%   of horizontal disparity arise for a +1 m depth change at that D (while fixating at D).
% - "Min_depth_step_for_threshold_m" is the smallest depth increment at D that reaches your
%   chosen stereo threshold (stereo_threshold_arcsec). Adjust that parameter to match observers.

%% 
%% Stereo depth discrimination vs. distance
% Computes minimal resolvable depth step (Δzmin)
% for different stereoacuity thresholds across distances.

% Parameters
IPD = 0.065;                           % interpupillary distance [m]
thresholds_arcsec = [5 10 30];         % stereo thresholds (arcseconds)
distances = logspace(log10(0.5), 4, 200);  % distances: 0.5 m → 10,000 m

% Convert thresholds to radians
arcsec2rad = @(x) x * (pi / (180 * 3600));
thresholds_rad = arcsec2rad(thresholds_arcsec);

% Compute Δzmin = D^2 * Δθ / IPD  [m]
DeltaZ = zeros(length(distances), length(thresholds_rad));
for i = 1:length(thresholds_rad)
    DeltaZ(:,i) = (distances.^2 .* thresholds_rad(i)) / IPD;
end

% --- Plot ---
figure('Color','w','Position',[100 100 720 460]);
loglog(distances, DeltaZ(:,1)*1000, 'LineWidth',2); hold on;  % 5 arcsec
loglog(distances, DeltaZ(:,2)*1000, 'LineWidth',2);           % 10 arcsec
loglog(distances, DeltaZ(:,3)*1000, 'LineWidth',2);           % 30 arcsec
grid on

xlabel('Viewing distance D (m)');
ylabel('Smallest resolvable depth Δz_{min} (mm)');
title('Stereo depth discrimination vs. distance');

legend('5 arcsec (best)', '10 arcsec (typical)', '30 arcsec (average)', ...
       'Location','northwest');
xlim([0.5 1e4]);
ylim([1e-4 1e8]);

% --- Optional: annotate rough perceptual limits ---
text(2, 1e-3, 'Sub-mm precision (near)', 'FontSize',9);
text(10, 10, 'cm-level (mid-range)', 'FontSize',9);
text(100, 1000, 'm-level (far field)', 'FontSize',9);

%% Optional: save table to CSV
DeltaZ_table = table(distances(:), ...
    DeltaZ(:,1), DeltaZ(:,2), DeltaZ(:,3), ...
    'VariableNames', {'Distance_m', 'Dz_5arcsec_m', 'Dz_10arcsec_m', 'Dz_30arcsec_m'});
writetable(DeltaZ_table, 'Stereo_Depth_Discrimination_Table.csv');
fprintf('Saved table to Stereo_Depth_Discrimination_Table.csv\n');

%%
%% Stereo depth discrimination vs. distance (with fusion limits)
% Computes minimal resolvable depth (Δzmin) for given stereo thresholds
% and marks the maximal distances where binocular fusion is still possible.

clear; clc;
IPD = 0.065;                            % interpupillary distance [m]
thresholds_arcsec = [5 10 30];          % stereo thresholds (arcseconds)
distances = logspace(log10(0.5), 4, 200); % 0.5 m → 10,000 m

% Convert thresholds to radians
arcsec2rad = @(x) x * (pi / (180 * 3600));
thresholds_rad = arcsec2rad(thresholds_arcsec);

%% 1. Compute minimal detectable depth difference Δzmin
DeltaZ = zeros(length(distances), length(thresholds_rad));
for i = 1:length(thresholds_rad)
    DeltaZ(:,i) = (distances.^2 .* thresholds_rad(i)) / IPD;   % meters
end

%% 2. Compute fusion-limit distances
% Fusion breaks down when vergence < fusion_limit
% Vergence = 2*atan(IPD/(2*D))  →  D = IPD / (2*tan(V/2))
fusion_limits_deg = [2 6];  % ±2° (fovea), ±6° (periphery)
fusion_D = IPD ./ (2*tan(deg2rad(fusion_limits_deg/2)));

fprintf('Fusion breakdown distances:\n');
fprintf('  ±2° (foveal): %.2f m\n', fusion_D(1));
fprintf('  ±6° (peripheral): %.2f m\n', fusion_D(2));

%% 3. Plot results
figure('Color','w','Position',[100 100 800 480]);
hold on;
loglog(distances, DeltaZ(:,1)*1000, 'LineWidth',2); % 5 arcsec
loglog(distances, DeltaZ(:,2)*1000, 'LineWidth',2); % 10 arcsec
loglog(distances, DeltaZ(:,3)*1000, 'LineWidth',2); % 30 arcsec

% Add fusion-limit dashed lines
for i = 1:length(fusion_D)
    xline(fusion_D(i), '--', ...
        sprintf('  Fusion limit ±%d° (%.2f m)', fusion_limits_deg(i), fusion_D(i)), ...
        'LineWidth',1.2, 'LabelOrientation','horizontal', 'LabelVerticalAlignment','bottom');
end

grid on
xlabel('Viewing distance D (m)');
ylabel('Smallest resolvable depth Δz_{min} (mm)');
title('Stereo depth discrimination vs. distance with fusion limits');
legend('5 arcsec (best)', '10 arcsec (typical)', '30 arcsec (average)', ...
       'Location','northwest');
xlim([0.5 1e4]);
ylim([1e-4 1e8]);

%% 4. Save table
DeltaZ_table = table(distances(:), ...
    DeltaZ(:,1), DeltaZ(:,2), DeltaZ(:,3), ...
    'VariableNames', {'Distance_m', 'Dz_5arcsec_m', 'Dz_10arcsec_m', 'Dz_30arcsec_m'});
writetable(DeltaZ_table, 'Stereo_Depth_Discrimination_Table.csv');
fprintf('Saved table to Stereo_Depth_Discrimination_Table.csv\n');