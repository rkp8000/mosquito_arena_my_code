% run PControl and set things up before running this script

%%
INSECT = '15_tr3';
Y = 4; % which stripe set to use (1 - 2 stripes, 2 - 4 stripes, 3 - 6 stripes, 4 - 8 stripes, 5 - 12 stripes)

DATE = datestr(now, 'YYmmDD');
DURATION = 7 * 60; % in seconds
STARTX = 91; % starting x position
EDR_DIR = 'C:\Users\researcher\Documents\Rich\edr_files_visual_expt';

% create com server connected to WinEDR
if ~exist('WinEDR','var')
    WinEDR = actxserver('winedr.auto');
end

%%
Panel_com('stop');
Panel_com('set_position', [STARTX, Y]);


%% begin recording
recording_start = datestr(now,'HHMMSS');
disp('Recording started.');
fname = [DATE '_' recording_start '_stripes_insect' INSECT '_ypos_' num2str(Y)];
edr_path = [EDR_DIR '\' fname];


WinEDR.NewFile(edr_path);
WinEDR.StartRecording;
pause(5);
Panel_com('start');

tic;
while toc < DURATION
    
end

WinEDR.StopRecording;

disp('Recording over.');