# ABR
Visualizing and analyzing tools for ABR recordings

INSTALLATION:
Put the entire folder somewhere on your harddrive. Add this folder to the Matlab path (or move the ABR.m and Scale.m files to an exisiting folder already present in the path).
It is recommended to first run the run_TestUnits.m script before any manipulation, to make sure the

CONTENT:
ABR.m: class to represent, manipulate, analyze and visualize ABR recordings in Matlab.
Scale.m: enumeration to deal with units
ABR_GUI: graphical interface to analyze and visualize ABR recordings.
demo.mlx: Matlab live script showing examples on how the ABR class could be used
TestUnit folder: contains test-units scripts checking several aspect of the ABR class. Run the run_TestUnits.m script in Matlab to run all tes units present in the folder.

NB: this entire framework only works for ABRs recorded from... in the format...
