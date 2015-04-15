%% script to present randomly moving bar signal with stimulus

%% set parameters
dur = 180; % duration (s)
bar_dt = .05; % bar position update interval (s)
barpos_range = 192;
timesteps = 0:bar_dt:10;
std_angle = 45;
smoothing = .5; % approx autocorrelation time (s)

% stim parameters
valve_open_times = [90 91 92 93];
valve_close_times = [90.5 91.5 92.5 93.5];

% valve control parameters
numValves = 2.1;    % 1, 2, or 2.1 (where 2.1 delivers same pulse to both lines)
tp = .05;           % minimum time that must pass between arena commands
gain_x = -3;        % set gain in x direction
Vopen = 2;          % voltage to feed to valve power supplys
valve_dt = 0.001;         % time step size (s)
ypos = 1;           % y position of visual stimulus (set to 1)
valve_open_signal = [2 0];

% calculate min and max barpos and other params
ntimesteps = round(dur/bar_dt);
std_barpos = round(std_angle/360*barpos_range);

% get smoothing filter
smoothing_filter_std = round(smoothing/bar_dt);
smoothing_filter_time_vec = (-3*smoothing_filter_std):(3*smoothing_filter_std);
smoothing_filter = normpdf(smoothing_filter_time_vec, 0, smoothing_filter_std);

%% generate white noise position signal
white_noise_pos = normrnd(0, std_angle, ntimesteps, 1);
time_vec = (0:length(white_noise_pos)-1)*bar_dt;
% smooth white noise signal
smoothed_pos = conv(white_noise_pos, smoothing_filter, 'same');

% renormalize std
smoothed_pos = smoothed_pos/std(smoothed_pos)*std_barpos;

figure('color','w');
plot(time_vec, smoothed_pos, 'k', 'linewidth', 2);
xlabel('t (s)')
ylabel('barpos','fontsize',16)

% convert signal to signals sendable by controller
smoothed_pos = mod(smoothed_pos, 10);

%% initialize valves
analogOutSession = daq.createSession('ni');
analogOutSession.Rate = 1/valve_dt;
if numValves == 1; analogOutSession.addAnalogOutputChannel('Dev1', 0, 'Voltage'); end
if numValves == 2 || numValves == 2.1; analogOutSession.addAnalogOutputChannel('Dev1', 0:1, 'Voltage'); end
analogOutSampleRate = analogOutSession.Rate;

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

%% start sequence
next_barpos_index = 1;
next_barpos_update = 0; % in seconds

next_valve_index = 1;
next_valve_open_time = valve_open_times(1);
next_valve_close_time = valve_close_times(1);

tic
while toc < dur
    % check if time for bar position update
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
    
    % check if time for valve opening
    if toc >= next_valve_open_time
        % open valve
        analogOutSession.outputSingleScan(valve_open_signal);
        if next_valve_index < length(valve_open_times)
            next_valve_open_time = valve_open_times(next_valve_index + 1);
        else
            next_valve_open_time = Inf;
        end
    end
    
    % check if time for valve closing
    if toc >= next_valve_close_time
        % close valve
        analogOutSession.outputSingleScan([0 0]);
        next_valve_index = next_valve_index + 1;
        if next_valve_index <= length(valve_close_times)
            next_valve_close_time = valve_close_times(next_valve_index);
        else
            next_valve_close_time = Inf;
        end
    end
end