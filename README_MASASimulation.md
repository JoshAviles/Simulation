# Simulation
Rocket Simulation Code for MASA

Running MASA_Simulator.m
1. Initially the simulator saves its results in a file entitled 'Data/SavedRecords/~.mat';
The save file is entitled 'Data/FlightRecord.mat';

2. The simulator asks for a prompt of initial values to start off the simulation in the form of a GUI:
prompt = {'Enter save filename:','Enter aerodynamic filename:',...
    'Enter nose ballast (lb):','Enter tail ballast (lb):',...
    'Enter launch angle (90 is vertical):',...
    'Enter launch rail length (ft):','Enter site elevation (ft):',...
    'Enter windspeed (MPH):','Enter accuracy level (1 = low and 3 = high):'};

3. 'Data/prompt.mat','answer' saves the resultant data in the form of an answer in the save file created by the MASA Simulation code.

4. The simulation then assigns values to each "answer" in the MASA Simulation file created originally at the start of the code.
savefile    = answer{1};
aerofile    = answer{2}; 
noseballast = convmass(str2double(answer{3}),'lbm','kg');
tailballast = convmass(str2double(answer{4}),'lbm','kg');
railangle   = str2double(answer{5});
raillength  = convlength(str2double(answer{6}),'ft','m');
elevation   = convlength(str2double(answer{7}),'ft','m');
accuracy    = str2double(answer{9});
windspeed   = convvel(str2double(answer{8}),'mph','m/s');

5. MASA Simulation loads the answer file in order to start running the simulation
copyfile(aerofile,'Data/aerofile.mat','f');

6. The creation of a record file creates save files saved to the assigned MASA Simulation folder that one may view for later record-keeping, debugging, and other types of general information.
record.time  = [];
record.alpha = [];
record.mach  = [];
record.xcp   = [];
record.ca    = [];
save('Data/record.mat','record');

7. Inertia properties are then calculated in the MASA Simulation code to influence the motion of the rocket throughout its flight from launch to apogee.

8. A wet Inertia and a dry Inertia matrix is created loaded from the MASA Simulation data file in order to compare inertia results... (not sure about this)

9. The Inertia matrix within the data of the MASA Simulation file is updated based on the calculations from part 7 of the file:
save('Data/update_inertia.mat','inertia')

10. An ODE section determines the accuracy of the MASA Simulation, which not only affects the accuracy of the results of the rocket launch but also the speed of the rocket simulation.

11. The matrix record of the previous flight for the simulation is deleted and replaced by a temporary data file.

12. The matrix record is then finalized in the "answers" file of the MASA Simulation to produce a final data result for the MASA Simulation.
FlightRecord = [];
FlightRecord.t           = T;
FlightRecord.x           = X(:,1);
FlightRecord.y           = X(:,2);
FlightRecord.theta       = X(:,3);
FlightRecord.vx          = X(:,4);
FlightRecord.vy          = X(:,5);
FlightRecord.omega       = X(:,6);
FlightRecord.mach        = Mach;
FlightRecord.alpha       = Alpha;
FlightRecord.Xcp         = Xcp;
FlightRecord.sm          = sm;
FlightRecord.aLaunch     = railangle;
FlightRecord.apogee      = apogee;

12. The Flight Record is plotted from launch to apogee of time versus vertical distance in order to map the rocket's vertical trajectory.

13. The final lines of the MASA Simulation.m includes an if condition to stop the simulation if the velocity of the rocket crosses zero, meaning that once
the rocket reaches apogee in the simulation, the simulation stops because at the apogee point the propulsive section of the rocket's flight ends and the rest of the rocket's
trajectory is guided by descent by parachute.
