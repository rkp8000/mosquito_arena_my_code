%% script to present randomly moving bar signal

%% set parameters
dur = 120; % duration (s)
dt = .05; % update interval
barpos_range = 96;
timesteps = 0:dt:10;
std_angle = 45;
smoothing = .2; % approx autocorrelation time (s)
tp = .05;           % minimum time that must pass between arena commands
gain_x = -3;        % set gain in x direction
ypos = 1;

% calculate min and max barpos and other params
ntimesteps = round(dur/dt);
std_barpos = round(std_angle/360*barpos_range);

% get smoothing filter
smoothing_filter_std = round(smoothing/dt);
smoothing_filter_time_vec = (-3*smoothing_filter_std):(3*smoothing_filter_std);
smoothing_filter = normpdf(smoothing_filter_time_vec, 0, smoothing_filter_std);

%% generate white noise position signal
%white_noise_pos = normrnd(0, std_angle, ntimesteps, 1);
white_noise_pos = std_angle*randn(ntimesteps, 1);
time_vec = (0:length(white_noise_pos)-1)*dt;
% smooth white noise signal
smoothed_pos = conv(white_noise_pos, smoothing_filter, 'same');

% renormalize std
smoothed_pos = smoothed_pos/std(smoothed_pos)*std_barpos;

figure('color','w');
plot(time_vec, smoothed_pos, 'k', 'linewidth', 2);
xlabel('t (s)')
ylabel('barpos','fontsize',16)

% convert signal to signals sendable by controller
smoothed_pos = mod(smoothed_pos, barpos_range) + 1;

%% open PControl
PControl;
pause(10);

%% initialize arena
Panel_com('set_pattern_id', 1); pause(tp);                  % our card has only one pattern
Panel_com('set_mode', [3 0]); pause(tp);                    % closed loop in x, open loop in y (0: open loop, 1: closed loop, 2: both, 3: external input sets position, 4: internal fn generator sets position, 5: internal fn generator debug mode)
Panel_com('set_position', [1 ypos]); pause(tp);             % sets to [0 0] (Subtracts 1 because MATLAB indices start at 1 instead of 0)
Panel_com('send_gain_bias', [gain_x 0 0 0]); pause(tp);     % e.g [10 -10 0 20] sets gain_x = 1X, bias_x = -0.5 V, gain_y = 0, bias_y = 1 V (check PControl to verify this).
pause(5); % Wait for panel to initialize

Panel_com('stop'); % make sure panel is stopped so we can send signals

disp('Press record now.');
pause(5);

%% start sequence
next_barpos_index = 1;
next_barpos_update = 0; % in seconds

disp('Starting visual sequence.');

tic
while toc < dur
    if toc >= next_barpos_update
        % set bar position
        barpos = smoothed_pos(next_barpos_index);
        Panel_com('set_position', [barpos 1]);
        % get next update times, etc.
        next_barpos_index = next_barpos_index + 1;
        if next_barpos_index <= ntimesteps
            next_barpos_update = time_vec(next_barpos_index);
        else
            next_barpos_update = Inf;
        end
    end
end
Panel_com('set_position', [1 1]);
disp('Visual sequence over.');