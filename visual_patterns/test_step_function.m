% this makes a step function for the arena; the image jumps from position 1
% to position 32 to position 64.
FS = 100; % Hz
T = 9; % seconds
NUM_TIMESTEPS = round(FS * T); % T s at FS Hz

func = zeros(1, NUM_TIMESTEPS);
func(301:600) = 32;
func(601:900) = 64;

save('position_function_steps.mat', 'func');