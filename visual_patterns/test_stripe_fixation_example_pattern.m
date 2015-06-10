NUM_XPIX = 96;
NUM_YPIX = 16;

pattern.x_num = 96; % There are 96 pixel around the display (12x8)
pattern.y_num = 1; % There is no vertical motion; only one frame is needed
pattern.num_panels = 24; % This is the number of unique Panel IDs required.
pattern.gs_val = 1; % This pattern will be binary , so grey scale code is 1;

Pats = zeros(NUM_YPIX, NUM_XPIX, pattern.x_num, pattern.y_num);
stripe_pattern = [ones(NUM_YPIX,92), zeros(NUM_YPIX,4)]; %dark pixels for the stripe
Pats(:, :, 1, 1) = stripe_pattern;
for j = 2:pattern.x_num    % use ShiftMatrixPats to rotate stripe image
    Pats(:,:,j,1) = ShiftMatrix(Pats(:,:,j-1,1),1,'r','y');
end

pattern.Pats = Pats; % put data in structure 
pattern.Panel_map = [12 8 4 11 7 3 10 6 2 9 5 1; 24 20 16 23 19 15 22 18 14 21 17 13]; % define panel structure vector 
pattern.BitMapIndex = process_panel_map(pattern);
pattern.data = Make_pattern_vector(pattern);
fname = 'Pattern_stripe_fixation_example'; % name must begin with ?Pattern_? 
save(fname, 'pattern');