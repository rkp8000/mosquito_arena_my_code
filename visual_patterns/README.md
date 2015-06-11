# How to construct visual patterns

Overview:
When using the mosquito arena, a visual pattern consists of a set of 2D images. When the arena displays which image depends on the settings you choose. If you run the arena in closed-loop, for example, the mosquito's left-minus-right wingbeat amplitude will determine which image is displayed. If you run the arena in open loop, you can specify a specific function to drive the display.

A few more details:
The set of images stored in a pattern is itself a 2D grid. This is because it is often the case that you will want to refer to an image by the amount that it has shifted from some original image in the X and Y direction. Thus, the full pattern set is given as a 4D array, where the first two dimensions are Y and X pixels, and the last two dimensions are the indices specifying which image you want.For example, with a 16 x 96 pixel display, pattern.Pats(:, :, 3, 5) is a 16 x 96 image matrix. pattern.Pats(:, :, 3, 6) and pattern.Pats(:, :, 2, 5) are also both 16 x 96 image matrices, but presumably different ones.

Creating a pattern:

Creating a function:

Driving a pattern with a function:
