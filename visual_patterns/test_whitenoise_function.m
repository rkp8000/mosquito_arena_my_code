% in this script we'll create the position function corresponding to white velocity noise of several difference standard deviations
% set up parameters
FS = 100; % Hz
T = 20; % minutes
NUM_TIMESTEPS = FS * T * 60; % T minutes at FS Hz
VEL_STDS = 0.25:0.25:4; % standard deviations

% loop over all standard deviations
for ctr = 1:length(VEL_STDS)
    % make velocity function
    vel_std = VEL_STDS(ctr);
    func = vel_std * randn(1, NUM_TIMESTEPS);
    % save velocity function
    fname = ['function_white_noise_velocity_std_' num2str(vel_std) '.mat'];
    save(fname, 'func');
   
    % make position function (this is done by summing velocity function, converting positions to integers, and modding it so that positions > 96 wrap around 
    func = mod(round(cumsum(func)), 96) + 1;
    % save position function
    fname = ['position_function_white_noise_velocity_std_' num2str(vel_std) '.mat'];
    save(fname, 'func');
end
