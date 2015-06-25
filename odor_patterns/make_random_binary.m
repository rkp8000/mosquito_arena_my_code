%%
% Make a random binary odor stimulus

TRAIN_DURATION = 20 * 60; % s
PULSE_DURATION = 0.5; % s
PULSE_FREQUENCY = 0.1; % s

n_timesteps = TRAIN_DURATION / PULSE_DURATION;

pulse_prob = PULSE_FREQUENCY * PULSE_DURATION;

pulse_timesteps = rand(1, n_timesteps) < pulse_prob;

pulse_onsets = find(diff([0 pulse_timesteps]) > 0) - 1;

pulse_offsets = find(diff([pulse_timesteps 0]) < 0);

pulse_onset_times = pulse_onsets * PULSE_DURATION;
pulse_offset_times = pulse_offsets * PULSE_DURATION;

pulse_onset_times = [pulse_onset_times inf];
pulse_offset_times = [pulse_offset_times inf];

pulse_train.onset_times = pulse_onset_times;
pulse_train.offset_times = pulse_offset_times;
pulse_train.train_duration = TRAIN_DURATION;
pulse_train.pulse_duration = PULSE_DURATION;
pulse_train.pulse_frequency = PULSE_FREQUENCY;

fname = ['random_bernoulli_train_duration_' num2str(TRAIN_DURATION) 's_' ...
    'pulse_duration_' num2str(PULSE_DURATION * 1000) 'ms_' ...
    'pulse_frequency_' num2str(PULSE_FREQUENCY) 'Hz.mat'];
save(fname, 'pulse_train');