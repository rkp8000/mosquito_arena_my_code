%% script to present randomly leaping bar signal

%% set parameters
dur = 600; % duration (s)
dt = .05; % update interval (s)
barpos_range = 96; % range of signals that get sent to update bar position
max_angle = 30; % degrees
ang_vel = 60; % degrees per second
initial_pause = 5;
bar_pauses = [3, 4, 5]; % times that bar pauses
tp = .05;           % minimum time that must pass between arena commands
gain_x = -3;        % set gain in x direction
ypos = 1;

% create bar position signal
ntimesteps = round(dur/dt);
time_vec = (0:ntimesteps - 1)*dt;
barpos = zeros(ntimesteps, 1);

current_position = 'center';
current_angle = 0;
next_position = '';
next_angle = 0;
mvmt_dir = '';
ang_vel_dt = ang_vel * dt; % angular velocity in degrees per dt
tctr = round(initial_pause/dt);

while tctr < ntimesteps
    % get next position
    switch current_position
        case 'center'
            if rand() > 0.5
                next_position = 'right';
                next_angle = max_angle;
                mvmt_dir = 'right';
            else
                next_position = 'left';
                next_angle = -max_angle;
                mvmt_dir = 'left';
            end
        case 'left'
            if rand() > 0.5
                next_position = 'right';
                next_angle = max_angle;
            else
                next_position = 'center';
                next_angle = 0;
            end
            mvmt_dir = 'right';
        case 'right'
            if rand() > 0.5
                next_position = 'left';
                next_angle = -max_angle;
            else
                next_position = 'center';
                next_angle = 0;
            end
            mvmt_dir = 'left';
    end
    
    % calculate barpos movement signal
    switch mvmt_dir
        case 'right'
            mvmt_signal = (current_angle:ang_vel_dt:next_angle)';
        case 'left'
            mvmt_signal = (current_angle:(-ang_vel_dt):next_angle)';
    end
    
    % calculate stationary signal
    pause_dur = bar_pauses(ceil(length(bar_pauses)*rand()));
    stat_signal = next_angle*ones(round(pause_dur/dt),1);
    
    % add into total barpos signal
    next_signal_chunk = [mvmt_signal; stat_signal];
    len = length(next_signal_chunk);
    next_tctr = tctr + len;
    
    overshoot = next_tctr - 1 - ntimesteps;
    if overshoot > 0 
        new_len = len - overshoot;
        next_signal_chunk = next_signal_chunk(1:new_len);
        barpos(tctr:end) = next_signal_chunk;
    else
        barpos(tctr:next_tctr - 1) = next_signal_chunk;
    end
    
    current_position = next_position;
    current_angle = next_angle;
    tctr = next_tctr;
end

figure('color','w');
plot(time_vec, barpos, 'k', 'linewidth', 2);
xlabel('t (s)')
ylabel('barpos','fontsize',16)

% convert barpos angle to sendable signals from 1 to 96
barpos = round(barpos/360*barpos_range);

barpos = mod(barpos, barpos_range) + 1;

% %% open PControl
% PControl;
% pause(10);
% 
% %% initialize arena
% Panel_com('set_pattern_id', 1); pause(tp);                  % our card has only one pattern
% Panel_com('set_mode', [3 0]); pause(tp);                    % closed loop in x, open loop in y (0: open loop, 1: closed loop, 2: both, 3: external input sets position, 4: internal fn generator sets position, 5: internal fn generator debug mode)
% Panel_com('set_position', [1 ypos]); pause(tp);             % sets to [0 0] (Subtracts 1 because MATLAB indices start at 1 instead of 0)
% Panel_com('send_gain_bias', [gain_x 0 0 0]); pause(tp);     % e.g [10 -10 0 20] sets gain_x = 1X, bias_x = -0.5 V, gain_y = 0, bias_y = 1 V (check PControl to verify this).
% pause(5); % Wait for panel to initialize
% 
% Panel_com('stop'); % make sure panel is stopped so we can send signals
% 
% disp('Press record now.');
% pause(5);
% 
% %% start sequence
% next_barpos_index = 1;
% next_barpos_update = 0; % in seconds
% 
% disp('Starting visual sequence.');
% 
% tic
% while toc < dur
%     if toc >= next_barpos_update
%         Panel_com('set_position', [barpos(next_barpos_index) 1]);
%         % get next update times, etc.
%         next_barpos_index = next_barpos_index + 1;
%         if next_barpos_index <= ntimesteps
%             next_barpos_update = time_vec(next_barpos_index);
%         else
%             next_barpos_update = Inf;
%         end
%     end
% end
% 
% Panel_com('set_position', [1 1]);
% disp('Visual sequence over.');