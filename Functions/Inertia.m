function [mass, inertia, cg] = Inertia(time, burntime)
%Outpust mass properties for the rocket
% read in inertia data and interpolate linearly in time


cd('../');
load('Data/update_inertia.mat');


cd('Functions');

% Inertial Properties [initial final]
Mass    = [inertia.wet(1) inertia.dry(1)];
Inertia = [inertia.wet(2) inertia.dry(2)]; % moment of inertia about center of gravity
CG      = [inertia.wet(3) inertia.dry(3)];

if time <= burntime
    
    mass    = Mass(1)-((Mass(1)-Mass(2))/burntime)*time;
    inertia = Inertia(1)-((Inertia(1)-Inertia(2))/burntime)*time;
    cg      = CG(1)-((CG(1)-CG(2))/burntime)*time;
else
    mass    = Mass(2);
    inertia = Inertia(2);
    cg      = CG(2);
end

end