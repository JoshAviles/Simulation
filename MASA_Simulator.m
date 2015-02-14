function MASA_Simulator

clc;
clear all;
close all;

%savefileblank = 'Data/SavedRecords/~.mat';
%savefile = 'Data/FlightRecord.mat';

%prompt for info
load('Data/prompt.mat');
def = answer;


prompt = {'Enter save filename:','Enter aerodynamic filename:',...
    'Enter nose ballast (lb):','Enter tail ballast (lb):',...
    'Enter launch angle (90 is vertical):',...
    'Enter launch rail length (ft):','Enter site elevation (ft):',...
    'Enter windspeed (MPH):','Enter accuracy level (1 = low and 3 = high):'};
linesize = [1 50; 1 50; 1 50; 1 50; 1 50; 1 50; 1 50; 1 50; 1 50];
answer = inputdlg(prompt,'Simulation Input',linesize,def);
if isempty(answer)
    disp('Canceled!')
    return
end

save('Data/prompt.mat','answer');

savefile    = answer{1};
aerofile    = answer{2}; 
noseballast = convmass(str2double(answer{3}),'lbm','kg');
tailballast = convmass(str2double(answer{4}),'lbm','kg');
railangle   = str2double(answer{5});
raillength  = convlength(str2double(answer{6}),'ft','m');
elevation   = convlength(str2double(answer{7}),'ft','m');
accuracy    = str2double(answer{9});
windspeed   = convvel(str2double(answer{8}),'mph','m/s');


copyfile(aerofile,'Data/aerofile.mat','f');
%% Simulation
% Load Data

load 'Data/aerofile.mat'
if exist(savefile,'file') == 0 % if the file does not exist create it
    FlightRecord = struct;
    save(savefile,'FlightRecord');
else % if the file does exist load it
    load(savefile);
end


% create record file
record.time  = [];
record.alpha = [];
record.mach  = [];
record.xcp   = [];
record.ca    = [];
save('Data/record.mat','record');



% recreate intertia properties
load 'Data/raw_inertia.mat'
xnose = 1.0668; % location of nose ballast
xtail = 2.3749; % location of tail ballast

mw  = noseballast+tailballast+inertia.wet(1);
md  = noseballast+tailballast+inertia.dry(1);

cmw = ((xnose*noseballast)+(xtail*tailballast)+(inertia.wet(3)*inertia.wet(1)))/mw;  
cmd = ((xnose*noseballast)+(xtail*tailballast)+(inertia.dry(3)*inertia.dry(1)))/md;
% parallel axis theorem
rw  = abs(cmw-inertia.wet(3));
rd  = abs(cmd-inertia.dry(3));
Iw  = (inertia.wet(2)+(mw*rw^2))+(noseballast*(cmw-xnose)^2)+(tailballast*(xtail-cmw)^2);
Id  = (inertia.dry(2)+(md*rd^2))+(noseballast*(cmd-xnose)^2)+(tailballast*(xtail-cmd)^2);

inertia.wet = [mw Iw cmw];
inertia.dry = [md Id cmd];

save('Data/update_inertia.mat','inertia')

% Sim Setup
tfinal = 50;                                     % seconds
tsteps = 10000;                                   % number of time steps
tspan = [0:tfinal/tsteps:tfinal];

load('Data/site.mat')
site.railangle = railangle;
site.altitude = elevation;
site.raillength = raillength;
site.windspeed  = windspeed;
save('Data/site.mat','site')

x0      = zeros(6,1); 
x0(3)   = degtorad(railangle);            % initial angle

tic
cd('Functions');


odephasA(tspan,x0,'init');
if accuracy == 1
    options = odeset('Events',@events,'OutputFcn',@odephasA,'OutputSel',[1 2],'AbsTol',1e-1,'RelTol',1e-3);    % Debugging
elseif accuracy == 2
    options = odeset('Events',@events,'OutputFcn',@odephasA,'OutputSel',[1 2],'AbsTol',1e-3,'RelTol',1e-6);   % Moderate simulation
elseif accuracy == 3
    options = odeset('Events',@events,'OutputFcn',@odephasA,'OutputSel',[1 2],'AbsTol',1e-6,'RelTol',1e-8);   % Accurate simulation
    %options = odeset('Events',@events,'AbsTol',1e-6,'RelTol',1e-8);   % Accurate simulation
else
    error('Accuracy level not recognized');
    options = [];
end
    
%

[T,X,TE,XE,IE]   = ode23(@Launch, tspan, x0, options);
cd('../');
toc

% Delete useless data at end of flight
if X(end,5) >= 0
    fprintf(2,'\nSimulation not completed\n\nIncrease simulation time!\n');
end

% Recover recorded data
load 'Data/record.mat';

Xcp   = interp1(record.time, record.xcp, T);
Alpha = interp1(record.time, record.alpha, T);
Mach  = interp1(record.time, record.mach, T);
sm    = interp1(record.time, record.sm, T);

% delete temporary flight record 
delete('Data/record.mat');

% Save data to file

apogee = max(X(:,2));

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

%save('Data/FlightRecord.mat','FlightRecord');
save(savefile,'FlightRecord');



%% Plot Data
% Print Relevant Information to Display
disp(['Apogee: ', num2str(convlength(apogee,'m','ft'),'%6.0f'),' ft'])
TE
XE

close all
PlotData = false;
if PlotData
    cd('Functions');
    PlotFlight(FlightRecord); 
    cd('../');
end


end

function [value,isterminal,direction] = events(t,x)
% Locate the time when velocity passes through zero in a decreasing direction
% and stop integration.  

value(1)      = x(5);  % detect vertical velocity = 0
isterminal(1) = 1;     % stop the integration
direction(1)  = -1;    % negative direction velocity is decreasing

value(2)      = convvel(sqrt(x(4)^2+x(5)^2),'m/s','ft/s') - 100;
isterminal(2) = 0;
direction(2)  = 1;
end
