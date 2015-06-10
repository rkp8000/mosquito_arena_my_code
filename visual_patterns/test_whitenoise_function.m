FS = 100; % Hz
T = 20; % minutes
NUM_TIMESTEPS = FS * T * 60; % T minutes at FS Hz
VEL_STDS = 0.25:0.25:4;

for ctr = 1:length(VEL_STDS)
    vel_std = VEL_STDS(ctr);
    func = vel_std * randn(1, NUM_TIMESTEPS);
    fname = ['function_white_noise_velocity_std_' num2str(vel_std) '.mat'];
    save(fname, 'func');
    
    func = mod(round(cumsum(func)), 96) + 1;
    fname = ['position_function_white_noise_velocity_std_' num2str(vel_std) '.mat'];
    save(fname, 'func');
end