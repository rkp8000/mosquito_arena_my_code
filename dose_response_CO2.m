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
insect = '4';
conc = 'N2-396-CO2-5.4-1pc';
odorant = 'CO2';

prefix = [datestr(now,'yy-mm-dd.HH-MM-SS') '.insect-' insect '.' odorant '.conc-' conc];

% Directory names
edr_dir = 'C:\Users\researcher\Documents\Rich\edr_files';
meta_dir = 'C:\Users\researcher\Documents\Rich\meta_data';

% Generate metadata filename and path
meta_fname = [prefix '.txt'];
meta_path = [meta_dir '\' meta_fname];

%% Define parameters

% Experimental trial parameters
npulses = 5;
pulse_dur = .5;
IPI = 30;
valve_open_signal = [2 0];

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
header{4} = ['#npulses:' num2str(npulses) '\n'];
header{5} = ['#pulsedur:' num2str(pulse_dur) '\n'];
header{6} = ['#IPI:' num2str(IPI) '\n'];
header{7} = ['#valve_open_signal:' num2str(valve_open_signal) '\n'];

for line_idx = 1:length(header)
    fprintf(fid, header{line_idx});
end


% Generate all open & close times
valve_open_times = IPI + (IPI + pulse_dur)*(0:npulses-1);
valve_close_times = valve_open_times + pulse_dur;
trial_end_time = valve_close_times(end) + IPI;

% Loop through all pulses in sequence
% Create EDR file
edr_fname = [prefix '.EDR'];
edr_path = [edr_dir '\' edr_fname];
WinEDR.NewFile(edr_path);

% Start recording and get recording start time
WinEDR.StartRecording;
recording_start = datestr(now,'HH-MM-SS.FFF');

pulse_ctr = 1;

next_open_time = valve_open_times(pulse_ctr);
next_close_time = valve_close_times(pulse_ctr);

tic
fprintf('Starting pulse sequence.\n');

while toc < trial_end_time
	
	if toc >= next_open_time
		% Open valve
        disp('opening valve');
        disp(next_open_time);
		analogOutSession.outputSingleScan(valve_open_signal);
		if pulse_ctr < npulses
			next_open_time = valve_open_times(pulse_ctr + 1);
		else
			next_open_time = Inf;
		end
	end
	if toc >= next_close_time
		% Close valve
        disp('closing valve');
        disp(next_close_time);
		analogOutSession.outputSingleScan([0 0]);
		if pulse_ctr < npulses
			next_close_time = valve_close_times(pulse_ctr + 1);
		else
			next_close_time = Inf;
		end
		pulse_ctr = pulse_ctr + 1;
	end
end

fprintf('Pulse sequence over.\n');
expt_end = datestr(now,'HH-MM-SS.FFF');

% Pause a few seconds before stopping recording since WinEDR records in chunks of 2 s
pause(3);
WinEDR.StopRecording;
recording_end = datestr(now,'HH-MM-SS.FFF');

% Write recording start, end, and experiment time to file
fprintf(fid, ['#recording_start:' recording_start '\n']);
fprintf(fid, ['#expt_end:' expt_end '\n']);
fprintf(fid, ['#recording_end:' recording_end '\n']);

% Write all valve open and close times to metadata file
fprintf(fid, '#valve_open_times:');
for stim_ctr = 1:length(valve_open_times)
	if stim_ctr < length(valve_open_times)
		fprintf(fid, [num2str(valve_open_times(stim_ctr)) ', ']);
	else
		fprintf(fid, [num2str(valve_open_times(stim_ctr)) '\n']);
	end
end
fprintf(fid, '#valve_close_times:');
for stim_ctr = 1:length(valve_close_times)
	if stim_ctr < length(valve_close_times)
		fprintf(fid, [num2str(valve_close_times(stim_ctr)) ', ']);
	else
		fprintf(fid, [num2str(valve_close_times(stim_ctr)) '\n']);
	end
end

%% Close COM server and meta data file
delete(WinEDR);
clear('WinEDR');
fclose('all');
%% End
disp('Script execution complete.');