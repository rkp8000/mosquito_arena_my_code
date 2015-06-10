NSTRIPES = 8;
STRIPE_WIDTHS = 2:8;

NUM_X = 96;

interstripe_distance = NUM_X / NSTRIPES;

stripe_patterns = ones(8,96,length(STRIPE_WIDTHS)); %dark pixels for the stripe
% fill in stripes
for wctr = 1:length(STRIPE_WIDTHS)
    stripe_width = STRIPE_WIDTHS(wctr);
    for sctr = 1:NSTRIPES
        stripe_start_idx = (sctr - 1) * interstripe_distance + 1;
        stripe_patterns(:,stripe_start_idx: stripe_start_idx + stripe_width - 1, wctr) = 0;
    end
end

pattern.x_num = NUM_X; % There are 96 pixel around the display (12x8)
pattern.y_num = length(STRIPE_WIDTHS); % There is no vertical motion; only one frame is needed
pattern.num_panels = 12; % This is the number of unique Panel IDs required.
pattern.gs_val = 1; % This pattern will be binary , so grey scale code is 1;

Pats = zeros(8, 96, pattern.x_num, pattern.y_num);

for wctr = 1:length(STRIPE_WIDTHS)
    Pats(:, :, 1, wctr) = stripe_patterns(:,:,wctr);
    for j = 2:96    % use ShiftMatrixPats to rotate stripe image
        Pats(:,:,j,wctr) = ShiftMatrix(Pats(:,:,j-1,wctr),1,'r','y');
    end
end

pattern.Pats = Pats; % put data in structure 
pattern.Panel_map = 1:1:12; % define panel structure vector 
pattern.BitMapIndex = process_panel_map(pattern);
pattern.data = Make_pattern_vector(pattern);
fname = ['Pattern_repeated_stripes_varoius_widths_number_' num2str(NSTRIPES)]; % name must begin with ?Pattern_? 
save(fname, 'pattern');