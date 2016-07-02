Code for controlling the mosquito visual/odor arena in the Riffell lab.

# How to run a white noise visual stimulus (velocity is white noise) with an odor M sequence

### Making the odor sequence

1. Building the odor stimulus. To build an M-sequence for odor, use the script odor_patterns/make_random_binary.m . In this script you'll specify the duration, pulse duration, and pulse frequency. The odor sequence will get saved in a .mat file in whichever directory you ran the script from. There are already two odor sequences saved in the odor_patterns directory.

### Running the experiment

1. Make sure the arena and all the relevant hardware is turned on.
2. Make sure MATLAB and WinEDR are open.
3. Run the command PControl to open the panel controller.
4. Set up everything correctly with the panel controller (i.e., make sure the correct pattern (stripes) is selected with the ). Make sure to set XPOS so that it is driven by the "position function". Set the display rate to 50 Hz. (See visual_patterns/README.md for more details on how the visual patterns are made.)
5. The script for running the experiment is white_velocity_noise_no_odor_to_fluctuating_CO2.m .
6. Set the relevant parameters at the top of the file. You should set the parameters that are given by constants, and their values should be pretty self-explanatory. The INSECT parameter is just an ID to give the insect when saving the resulting EDR file. Leaving VALVE_DT at 0.001 is fine. Make sure the VALVE control signals are opening the correct valves.
7. The script will first run the visual stimulus with no odor and save this to a file ending with ..._CO2_off.EDR . This will take DURATION seconds. Then the script will run the visual stimulus with the specified odor M-sequence accompanying it for another DURATION seconds. The data will be saved in a new .EDR file with the last portion of the file name indicating the CO2 pulse frequency and pulse duration.
