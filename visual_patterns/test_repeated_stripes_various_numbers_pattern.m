STRIPE_WIDTH = 2;
STRIPE_NUMBERS = [2, 4, 6, 8, 12];

NUM_X = 96;

interstripe_distances = NUM_X ./ STRIPE_NUMBERS;

stripe_patterns = ones(8,96,length(STRIPE_NUMBERS)); %dark pixels for the stripe
% fill in stripes
for nctr = 1:length(STRIPE_NUMBERS)
    nstripes = STRIPE_NUMBERS(nctr);
    interstripe_distance = interstripe_distances(nctr);
    for sctr = 1:nstripes
        stripe_start_idx = (sctr - 1) * interstripe_distance + 1;
        stripe_patterns(:,stripe_start_idx: stripe_start_idx + STRIPE_WIDTH - 1, nctr) = 0;
    end
end

pattern.x_num = NUM_X; % There are 96 pixel around the display (12x8)
pattern.y_num = length(STRIPE_NUMBERS); % There is no vertical motion; only one frame is needed
pattern.num_panels = 12; % This is the number of unique Panel IDs required.
pattern.gs_val = 1; % This pattern will be binary , so grey scale code is 1;

Pats = zeros(8, 96, pattern.x_num, pattern.y_num);

for nctr = 1:length(STRIPE_NUMBERS)
    Pats(:, :, 1, nctr) = stripe_patterns(:,:,nctr);
    for j = 2:96    % use ShiftMatrixPats to rotate stripe image
        Pats(:,:,j,nctr) = ShiftMatrix(Pats(:,:,j-1,nctr),1,'r','y');
    end
end

pattern.Pats = Pats; % put data in structure 
pattern.Panel_map = 1:1:12; % define panel structure vector 
pattern.BitMapIndex = process_panel_map(pattern);
pattern.data = Make_pattern_vector(pattern);
directory_name = '/Users/rkp/Dropbox/Repositories/mosquito_arena_pattern_data';
fpath = [directory_name '/Pattern_repeated_stripes_width_' ...
    num2str(STRIPE_WIDTH) 'px_various_numbers']; % name must begin with ?Pattern_? 
save(fpath, 'pattern');