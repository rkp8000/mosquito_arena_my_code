%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DESCRIPTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This code presents a binary odor stimulus in visual closed loop and then,
% after waiting for a certain intertrial period, replays both the binary
% odor & visual stimulus.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% clear/close
clear
close all
clc

%% Set file name info
insect = '13';

prefix = [datestr(now,'yy-mm-dd.HH-MM-SS') '.insect-' insect];

% Directory names
edr_dir = 'C:\Users\researcher\Documents\Rich\edr_files';
meta_dir = 'C:\Users\researcher\Documents\Rich\meta_data';

% Generate metadata filename and path
meta_fname = [prefix '.txt'];
meta_path = [meta_dir '\' meta_fname];

%% Define parameters
% Test trial parameters
% trial_durs = [10]; % (s)
% ITI_durs = [10]; % (s)
% pulse_freqs = [.5]; % (Hz)
% pulse_durs = [.25]; % (s)
% nseqs = length(trial_durs); % How many sequences to present
% seq_idx = 1;
% valve_open_signal = [2 0];
% odorant = 'test';

% % Experimental trial parameters
trial_durs = [60 60 60]; % (s)
ITI_durs = [60 60 60]; % (s)
pulse_freqs = [.5 .5 .5]; % (Hz)
pulse_durs = [.25 .25 .25]; % (s)
nseqs = length(trial_durs); % How many sequences to present
seq_idx = 1;
valve_open_signal = [2 0];
odorant = 'CO2';

% % Control trial parameters
% trial_durs = [30 30]; % (s)
% ITI_durs = [20 20]; % (s)
% pulse_freqs = [1 1]; % (Hz)
% pulse_durs = [.05 .05]; % (s)
% nseqs = length(trial_durs); % How many sequences to present
% seq_idx = 1;
% valve_open_signal = [0 2];
% odorant = 'fresh-air';

% Other parameters
numValves = 2.1;    % 1, 2, or 2.1 (where 2.1 delivers same pulse to both lines)
tp = .05;           % minimum time that must pass between arena commands
gain_x = -3;        % set gain in x direction
Vopen = 2;          % voltage to feed to valve power supplys
dt = 0.001;         % time step size (s)
ypos = 1;           % y position of visual stimulus (set to 1)

edr_odor_ch = 6;    % odor channel in edr file
edr_barpos_ch = 10; % bar position channel in edr file

barpos_factor = 96/5;   % factor for converting voltage to bar position (increments per volt)

%% open PControl
PControl;
pause(10); % Wait for everything to correctly load

%% Create COM server running WinEDR
if ~exist('WinEDR','var')
    WinEDR = actxserver('winedr.auto');
end

%% initialize arena
Panel_com('set_pattern_id', 1); pause(tp);                  % our card has only one pattern
Panel_com('set_mode', [1 0]); pause(tp);                    % closed loop in x, open loop in y (0: open loop, 1: closed loop, 2: both, 3: external input sets position, 4: internal fn generator sets position, 5: internal fn generator debug mode)
Panel_com('set_position', [1 ypos]); pause(tp);             % sets to [0 0] (Subtracts 1 because MATLAB indices start at 1 instead of 0)
Panel_com('send_gain_bias', [gain_x 0 0 0]); pause(tp);     % e.g [10 -10 0 20] sets gain_x = 1X, bias_x = -0.5 V, gain_y = 0, bias_y = 1 V (check PControl to verify this).
pause(5); % Wait for panel to initialize

%% initialize valves
analogOutSession = daq.createSession('ni');
analogOutSession.Rate = 1/dt;
if numValves == 1; analogOutSession.addAnalogOutputChannel('Dev1', 0, 'Voltage'); end
if numValves == 2 || numValves == 2.1; analogOutSession.addAnalogOutputChannel('Dev1', 0:1, 'Voltage'); end
analogOutSampleRate = analogOutSession.Rate;

%% START arena
Panel_com('start');

%% Open metadata file & write header
fid = fopen(meta_path,'wt');
header = cell(1,4);
header{1} = ['#expt_type:binary-' odorant '-visual-replay\n'];
header{2} = ['#date(yyyy-mm-dd):' datestr(now,'yyyy-mm-dd') '\n'];
header{3} = ['#time(HH-MM-SS.FFF):' datestr(now,'HH-MM-SS.FFF') '\n'];
header{4} = '#column_names:filename,path,trial_type,recording_start,trial_start,trial_end,trial_dur,pulse_dur,pulse_freq\n';

for line_idx = 1:length(header)
    fprintf(fid, header{line_idx});
end

trial_info_format = '%s,%s,%s,%s,%s,%s,%8.4f,%8.4f,%8.4f\n';

%% Loop through sequences
tr_ctr = 0;
for seq_idx = 1:nseqs
    
    trial_types = {'intertrial','closed_loop','intertrial','fixed_bar', ...
        'intertrial','open_loop'};
    % Add final intertrial if last sequence
    if seq_idx == nseqs
        trial_types = [trial_types {'intertrial'}];
    end
    ntrials = length(trial_types);
    
    % Loop through all trials in sequence
    for tr_idx = 1:ntrials
        
        tr_ctr = tr_ctr + 1;
        
        % Set trial parameters based on trial type
        trial_type = trial_types{tr_idx};
        if strcmp(trial_type,'intertrial')
            trial_dur = ITI_durs(seq_idx);
            pulse_dur = 0;
            pulse_freq = 0;
            fprintf('Running intertrial interval...\n');
            edr_fname = [prefix '.tr-' num2str(tr_ctr) '.intertrial.EDR'];
        else
            trial_dur = trial_durs(seq_idx);
            pulse_dur = pulse_durs(seq_idx);
            pulse_freq = pulse_freqs(seq_idx);
            if strcmp(trial_type,'closed_loop')
                fprintf('Running closed loop trial...\n');
                edr_fname = [prefix '.tr-' num2str(tr_ctr) '.closed_loop.EDR'];
            elseif strcmp(trial_type,'open_loop')
                fprintf('Running open loop trial...\n');
                edr_fname = [prefix '.tr-' num2str(tr_ctr) '.open_loop.EDR'];
            elseif strcmp(trial_type,'fixed_bar')
                fprintf('Running fixed bar trial...\n');
                edr_fname = [prefix '.tr-' num2str(tr_ctr) '.fixed_bar.EDR'];
            end
        end
        
        % Generate binary odor stimulus if not intertrial
        if ~strcmp(trial_type,'intertrial')
            
            pulse_prob = pulse_freq*pulse_dur; % pulse probability in one time bin
            if pulse_prob > 1
                pulse_prob = 1;
            end
            num_bins = round(trial_dur/pulse_dur);

            % Create vector of stimulus on times
            stim_on_times_logical = rand(1,num_bins) < pulse_prob;
            stim_on_derivative = diff([0 stim_on_times_logical 0]);
            % Get vector of open & close times
            open_times = find(stim_on_derivative == 1);
            close_times = find(stim_on_derivative == -1);
            % Convert open & close times to seconds
            open_times = [open_times * pulse_dur, NaN];
            close_times = [close_times * pulse_dur, NaN];

            next_open_time = open_times(1);
            next_close_time = close_times(1);
        end
        
        % Create EDR file
        edr_path = [edr_dir '\' edr_fname];
        WinEDR.NewFile(edr_path);

        % Start recording and get recording start time
        WinEDR.StartRecording;
        recording_start = datestr(now,'HH-MM-SS.FFF');

        % Perform trial action according to trial type
        if strcmp(trial_type,'closed_loop')
            
            closed_loop_path = edr_path;
            
            pulse_num = 1;
            Panel_com('start');
            
            % Get and print out trial start time
            trial_start = datestr(now,'HH-MM-SS.FFF');
            tic
            fprintf(['Start: ' trial_start '\n']);
            
            % Present binary odor stimulus in closed visual loop
            while toc < trial_dur

                if toc >= next_open_time
                    % Open valve
                    analogOutSession.outputSingleScan(valve_open_signal);
                    next_open_time = open_times(pulse_num + 1);
                elseif toc >= next_close_time
                    % Close valve
                    analogOutSession.outputSingleScan([0 0]);
                    next_close_time = close_times(pulse_num + 1);
                    pulse_num = pulse_num + 1;
                end

            end
            
        elseif strcmp(trial_type,'intertrial')
            
            intertrial_path = edr_path;
            Panel_com('start');
            
            % Get and print out trial start time
            trial_start = datestr(now,'HH-MM-SS.FFF');
            tic
            fprintf(['Start: ' trial_start '\n']);
            
            if tr_idx > 1
                % Extract odor and visual time-series
                [data, h] = import_edr(closed_loop_path);
                odor_signal = data(:,edr_odor_ch);
                barpos_signal = data(:,edr_barpos_ch);
                barpos_signal(barpos_signal <= 0) = .00001;
                edr_dt = h.DT;
                clear('data');
                clear('h');
                % Convert barpos signal to units that can be sent to arena
                barpos_arena_signal = ceil(barpos_factor * barpos_signal);
                ntimesteps = length(barpos_arena_signal);
            end
            % Wait for the rest of the intertrial interval to finish
            while toc < trial_dur
            end
            
        elseif strcmp(trial_type,'open_loop')
            
            open_loop_path = edr_path;
            
            pulse_num = 1;
            last_command_time = 0;
            Panel_com('stop');
            
            % Get and print out trial start time
            trial_start = datestr(now,'HH-MM-SS.FFF');
            tic
            fprintf(['Start: ' trial_start '\n']);
            
            % Present binary odor stimulus with controlled bar positions
            while toc < trial_dur
                
                % Present visual stimulus if long enough since last command
                if toc - last_command_time > tp
                    % Get timestep index from actual time for barpos
                    barpos = barpos_arena_signal(ceil(toc/edr_dt));
                    Panel_com('set_position', [barpos ypos]);
                    last_command_time = toc;
                end

                % Open/close odor valve
                if toc >= next_open_time
                    % Open valve
                    analogOutSession.outputSingleScan(valve_open_signal);
                    next_open_time = open_times(pulse_num + 1);
                elseif toc >= next_close_time
                    % Close valve
                    analogOutSession.outputSingleScan([0 0]);
                    next_close_time = close_times(pulse_num + 1);
                    pulse_num = pulse_num + 1;
                end
            end
        
        elseif strcmp(trial_type,'fixed_bar')
            
            open_loop_path = edr_path;
            
            pulse_num = 1;
            last_command_time = 0;
            Panel_com('stop'); pause(tp);
            Panel_com('set_position',[1,1]);
            
            % Get and print out trial start time
            trial_start = datestr(now,'HH-MM-SS.FFF');
            tic
            fprintf(['Start: ' trial_start '\n']);
            
            % Present binary odor stimulus with fixed bar
            while toc < trial_dur
                
                % Open/close odor valve
                if toc >= next_open_time
                    % Open valve
                    analogOutSession.outputSingleScan(valve_open_signal);
                    next_open_time = open_times(pulse_num + 1);
                elseif toc >= next_close_time
                    % Close valve
                    analogOutSession.outputSingleScan([0 0]);
                    next_close_time = close_times(pulse_num + 1);
                    pulse_num = pulse_num + 1;
                end
            end
        end
        
        % Make sure valve is closed
        analogOutSession.outputSingleScan([0 0]);
        
        % Get and print out trial end time
        trial_end = datestr(now,'HH-MM-SS.FFF');
        fprintf(['End: ' trial_end '\n']);
        
        % Pause a few seconds before stopping recording
        pause(5);
        WinEDR.StopRecording;

        % Write trial information to metadata file
        fprintf(fid, trial_info_format, edr_fname, edr_path, trial_type, recording_start, trial_start, trial_end, trial_dur, pulse_dur, pulse_freq);
        
    end
    
end

%% Close COM server and meta data file
analogOutSession.outputSingleScan([0 0]);
delete(WinEDR);
clear('WinEDR');
fclose('all');

%% End
disp('Experiment over.');