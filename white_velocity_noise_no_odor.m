% run PControl and set things up before running this script

%%
INSECT = '';
Y = 0; % which stripe set to use (1 - 2 stripes, 2 - 4 stripes, 3 - 6 stripes, 4 - 8 stripes, 5 - 12 stripes)

DATE = datestr(now, 'YYMMDD');
DURATION = 10 * 60; % in seconds
STARTX = 1; % starting x position
EDR_DIR = 'C:\Users\researcher\Documents\Rich\edr_files_visual_expt';

% create com server connected to WinEDR
if ~exist('WinEDR','var')
    WinEDR = actxserver('winedr.auto');
end

%%
Panel_com('stop');
Panel_com('set_position', [STARTX, Y]);
pause(1);
Panel_com('start');

%% begin recording
recording_start = datestr(now,'HHMMSS');
fname = [DATE '_' recording_start '_stripes_insect' INSECT '_ypos_' num2str(Y)];
edr_path = [EDR_DIR '\' fname];

WinEDR.NewFile(edr_path);
WinEDR.StartRecording;

tic;
while toc < tic + DURATION
    
end

WinEDR.StopRecording;