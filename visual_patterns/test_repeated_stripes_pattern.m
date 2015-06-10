NUM_XPIX = 96;
NUM_YPIX = 16;

NUM_X = 96;
NUM_Y = 1;
NSTRIPES = 8;
STRIPE_WIDTH = 4;

interstripe_distance = NUM_X / NSTRIPES;

stripe_pattern = ones(NUM_YPIX, NUM_XPIX); %dark pixels for the stripe
% fill in stripes
for sctr = 1:NSTRIPES
    stripe_start_idx = (sctr - 1) * interstripe_distance + 1;
    stripe_pattern(:,stripe_start_idx: stripe_start_idx + STRIPE_WIDTH - 1) = 0;
end

pattern.x_num = NUM_X; % There are 96 pixel around the display (12x8)
pattern.y_num = NUM_Y; % There is no vertical motion; only one frame is needed
pattern.num_panels = 24; % This is the number of unique Panel IDs required.
pattern.gs_val = 1; % This pattern will be binary , so grey scale code is 1;

Pats = zeros(NUM_YPIX, NUM_XPIX, pattern.x_num, pattern.y_num);
Pats(:, :, 1, 1) = stripe_pattern;
for j = 2:NUM_XPIX    % use ShiftMatrixPats to rotate stripe image
    Pats(:,:,j,1) = ShiftMatrix(Pats(:,:,j-1,1),1,'r','y');
end

pattern.Pats = Pats; % put data in structure 
pattern.Panel_map = [12 8 4 11 7 3 10 6 2 9 5 1; 24 20 16 23 19 15 22 18 14 21 17 13]; % define panel structure vector 
pattern.BitMapIndex = process_panel_map(pattern);
pattern.data = Make_pattern_vector(pattern);
fname = ['Pattern_repeated_stripes_number_' ...
    num2str(NSTRIPES) '_width_' num2str(STRIPE_WIDTH) 'px']; % name must begin with ?Pattern_? 
save(fname, 'pattern');