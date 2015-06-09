pattern.x_num = 96; % There are 96 pixel around the display (12x8)
pattern.y_num = 1; % There is no vertical motion; only one frame is needed
pattern.num_panels = 12; % This is the number of unique Panel IDs required.
pattern.gs_val = 1; % This pattern will be binary , so grey scale code is 1;

Pats = zeros(8, 96, pattern.x_num, pattern.y_num);
stripe_pattern = [ones(8,88),zeros(8,8)]; %dark pixels for the stripe
Pats(:, :, 1, 1) = stripe_pattern;
for j = 2:96    % use ShiftMatrixPats to rotate stripe image
    Pats(:,:,j,1) = ShiftMatrix(Pats(:,:,j-1,1),1,'r','y');
end

pattern.Pats = Pats; % put data in structure 
pattern.Panel_map = 1:1:12; % define panel structure vector 
pattern.BitMapIndex = process_panel_map(pattern);
pattern.data = Make_pattern_vector(pattern);
directory_name = '/Users/rkp/Dropbox/Repositories/mosquito_arena_pattern_data';
str = [directory_name '/Pattern_stripe_fixation_example']; % name must begin with ?Pattern_? 
save(str, 'pattern');