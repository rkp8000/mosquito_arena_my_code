# How to construct visual patterns

Overview:
When using the mosquito arena, a visual pattern consists of a set of 2D images. When the arena displays which image depends on the settings you choose. If you run the arena in closed-loop, for example, the mosquito's left-minus-right wingbeat amplitude will determine which image is displayed. If you run the arena in open loop, you can specify a specific function to drive the display.

A few more details:
You can think of the set of images that you will be displaying as laid out in a 2D grid, e.g., a 10 x 10 grid would contain 100 images. In MATLAB, the entire image is thus stored as a 4D array. The last two dimensions index the column and row of the image and the first two dimensions index the y and x coordinates of the pixels. In most pattern-making scripts, this array is called Pats. For example, Pats(:, :, 3, 1) is the 2D array corresponding to the image in the third column and the first row. Pats(10, 5, 4, 4) is the value of the 10th pixel down and 5th pixel over in the image in the 4th column and 4th row.

One common stimulus set you will probably have is an image that can be displayed at any horizontal location on the arena. Thus, if you 96 columns of LEDs in the arena and you want to be able to display an image at any horizontal location the size of Pats will be (NY, NX, 96, 1), where NY is the number of y pixels (LEDs) and NX is the number of x pixels (which will also be 96). For this reason, the last two indices in Pats are often referred to as XPOS and YPOS, respectively, because they often specify what the image on the arena will look like if it has been shifted in the X or Y direction (though this need not be the case -- another common way to do it is to have XPOS indicate the X-shifted images and YPOS indicate which of several sets of images you want, e.g., you could have stripes of different widths, with each width corresponding to one YPOS).

Creating a pattern:
To create a pattern, you have to specify the image you want at each XPOS and YPOS. The code that comes with the arena has some useful functions such as ShiftMatrix that help you create this. Check out the code for test_repeated_stripes_pattern.m for an example of how to do this. At the end of all this, you should have a 4D array called Pats that contains all your images and is indexed according to the description above.

Once you have the Pats array, you have to bind it to a MATLAB struct called "pattern" and which contains some other meta information.

The specific fields that "pattern" must have are:

pattern.x_num - the number of XPOSs you have in your image grid (note: not the number of x pixels in the arena)
pattern.y_num - the number of YPOSs you have in your image grid
pattern.num_panels - the number of 8 x 8 LED panels the arena is composed of
pattern.gs_val - gray scale (set to 1 if you're just using pixels that are on or off - for more details about this, see the manual linked at the bottom of this document) 

pattern.Pats - this is the Pats array that contains all your images (discussed above)

pattern.Panel_map - this is the map containing the IDs of each Panel (they are not necessarily in order of their location in the arena): for the arena in the Riffell Lab, the panel map contains 24 numbers because the arena has 2 rows of 12 panels; the specific Panel_map that should be used (according to the arena configuration on 06/17/2015) is: pattern.Panel_map = [12 8 4 11 7 3 10 6 2 9 5 1; 24 20 16 23 19 15 22 18 14 21 17 13]

Once these fields have been properly filled out in the pattern struct, you need to fill in a few more fields using the functions that come with the arena code (just put the following in your script):

pattern.BitMapIndex = process_panel_map(pattern);
pattern.data = Make_pattern_vector(pattern);


Finally, before you load the pattern to an SD card, you have to save the struct to a .mat file, which you can do using:

save('path\to\file', 'pattern');

Creating a function:

Driving a pattern with a function:
