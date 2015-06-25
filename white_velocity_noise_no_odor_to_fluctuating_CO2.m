% run PControl and set things up before running this script

%%
INSECT = 'test';
Y = 4; % which stripe set to use (1 - 2 stripes, 2 - 4 stripes, 3 - 6 stripes, 4 - 8 stripes, 5 - 12 stripes)
DURATION = 7 * 60; % in seconds
PULSE_TRAIN_NAME = 'random_bernoulli_train_duration_30s_pulse_duration_500ms_pulse_frequency_0.25Hz.mat';
PULSE_TRAIN_FILE = fullfile('odor_patterns', PULSE_TRAIN_NAME);

VALVE_OPEN_SIGNAL = [2 0];

DATE = datestr(now, 'YYmmDD');
STARTX = 91; % starting x position
EDR_DIR = 'C:\Users\researcher\Documents\Rich\edr_files_visual_expt';
VALVE_DT = 0.001;

% load pulse train
load(PULSE_TRAIN_FILE);

% create com server connected to WinEDR
if ~exist('WinEDR','var')
    WinEDR = actxserver('winedr.auto');
end

%% 
analogOutSession = daq.createSession('ni');
analogOutSession.Rate = 1/VALVE_DT;

if numValves == 1
    analogOutSession.addAnalogOutputChannel('Dev1', 0, 'Voltage');
elseif numValves == 2 || numValves == 2.1
    analogOutSession.addAnalogOutputChannel('Dev1', 0:1, 'Voltage');
end

analogOutSampleRate = analogOutSession.Rate;

%%
Panel_com('stop');
Panel_com('set_position', [STARTX, Y]);


%% begin recording
recording_start = datestr(now,'HHMMSS');
disp('Recording started.');

% make file for odor being off
fname = [DATE '_' recording_start '_stripes_insect' INSECT '_ypos_' ...
    num2str(Y) '_CO2_off'];
edr_path = [EDR_DIR '\' fname];


WinEDR.NewFile(edr_path);
WinEDR.StartRecording;
pause(5);
Panel_com('start');

tic;
while toc < DURATION
    
end

pause(3);
WinEDR.StopRecording;

disp('Starting odor sequence...');

% wait a few seconds before starting next one
pause(3);

% make file for fluctuating CO2
fname = [DATE '_' recording_start '_stripes_insect' INSECT '_ypos_' ...
    num2str(Y) '_CO2_fluctuating_freq_' ...
    num2str(pulse_train.pulse_frequency) 'Hz_pulse_duration_' ...
    num2str(pulse_train.pulse_duration * 1000) 'ms'];

edr_path = [EDR_DIR '\' fname];


WinEDR.NewFile(edr_path);
WinEDR.StartRecording;
pause(3);

pulse_ctr = 1;
next_onset_time = pulse_train.onset_times(pulse_ctr);
next_offset_time = pulse_train.offset_times(pulse_ctr);
tic;
while toc < DURATION
    if toc >= next_onset_time
        % open valve
        analogOutSession.outputSingleScan(VALVE_OPEN_SIGNAL);
        next_onset_time = pulse_train.onset_times(pulse_ctr + 1);
    end
    if toc >= next_offset_time
        % close valve
        analogOutSession.outputSingleScan(VALVE_CLOSE_SIGNAL);
        next_offset_time = pulse_train.offset_times(pulse_ctr + 1);
        pulse_ctr = pulse_ctr + 1;
    end
end

pause(3);

WinEDR.StopRecording;

disp('Recording over.');