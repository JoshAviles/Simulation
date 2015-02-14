function [xdot] = Launch(t,x)
% The simulation file for the launch 

tf = 50;
persistent h motor

% % update waitbar
% if isempty(h)
%    h=waitbar(0,'Launched');
% else 
%    waitbar(t/tf,h,'Launched');
% end

% Notes: 
% +x = downwind


    %% Read All Data
    cd('../');
    if t==0
        motor = dlmread('Data/Cesaroni_M1790.eng',' ',[2 3 14 4]); % [time thrust]
    end
    load('Data/aerofile.mat');
    load('Data/site.mat');
    cd('Functions');


    %% Calculate Variables

    altitude = x(2)+site.altitude;
    pitch    = x(3);

    space = (altitude > 76000); % if we are in space, neglect aerodynamic effects
    
    offrail = (x(2) > sin(site.railangle)*site.raillength) || t > 5; 


    %% Calculate Thrust
    burntime = motor(end,1);
    if t < burntime % power on
        power = true;
        Thrust = interp1([0;motor(:,1)],[0;motor(:,2)],t);
    else
        power = false;
        Thrust = 0;
    end

    %% Mass Properties
    [mass, momI, Xcg] = Inertia(burntime, t);
    
    %% Calculate Aerodynamic Forces
    if ~space
        % Atmospheric Properties
        [rho,a,~,~,~,~] = stdatmo(altitude);
        %[~,Rho] = atmosnrlmsise00(altitude,0,0,1,90,36000,'Oxygen'); %10 am at (0,0)
        %rho = Rho(6); %total mass density

        % Airspeed
        % will screw up angle of attack when at low velocity

        airspeed = [x(4) x(5)] - [site.windspeed, 0];

        % Mach number
        mach = norm(airspeed)/a;

        %alpha
        if norm(airspeed) > 0
            alpha = radtodeg(pitch - atan2(airspeed(2),airspeed(1))); %deg
            alpha = atan2d(sind(alpha),cosd(alpha));% convert to [180,-180]
        else
            alpha = 0;
        end

        % Forces
            [Ca,Cn,Xcp] = Coefficients(mach,alpha,aero);
            Vmag = norm(airspeed);

        % Geometry variables
            Lref = aero.lref*0.0254;       % to m
            Sref = aero.sref*0.00064516;   % to m^2
            Xcp  = Xcp*0.0254;             % to m

        
        if offrail
            % Body Forces
                axial_force = - 0.5*Ca*rho*Vmag^2*Sref + Thrust;
                normal_force = 0.5*Cn*rho*Vmag^2*Sref;            

            % Moment in xy plane (right handed system)
                mom = normal_force*(Xcg-Xcp);

        else
            % No motion off rail if on rail
            % Body Forces
                axial_force = - 0.5*Ca*rho*Vmag^2*Sref + Thrust;
                normal_force = 0;          

            % Moment in xy plane (right handed system)
                mom = 0;
        end

        % Rotate to ground frame
        AeroForces = [cos(x(3)) -sin(x(3)); sin(x(3)) cos(x(3))]*[axial_force; normal_force];
    else
        disp(['In space: ',num2str(altitude,'%0.0f'),' m'])
        AeroForces = [0; 0];
        mom   = 0;
        alpha = NaN;
        Xcp   = NaN;
        mach  = NaN;
        Ca    = NaN;
    end
    %% Calculate Gravity Force
    mu = 398600.4418;       % km^3/s^2 (earth gravity parameter)
    Re = 6378.1;            % km       (earth radius)
    R = Re+(altitude/1000); % km

    g = (mu/R^2)*1000;      % m/s^2

    % Ground forces
    xforce = AeroForces(1);
    yforce = AeroForces(2) - g*mass; % add gravity to the forces

%% build xdot

% Key: 
% x index   variable
% 1         x pos.
% 2         y pos.
% 3         theta (pitch)
% 4         x vel.
% 5         y vel.
% 6         omega (angular velocity)
% xdot = dx/dt

xdot = zeros(6,1);

% velocities
xdot(1) = x(4);
xdot(2) = x(5);
xdot(3) = x(6);

% accelerations
xdot(4) = xforce/mass;
xdot(5) = yforce/mass;
xdot(6) = mom/momI;

% dont let the rocket go underground on liftoff
if x(2) <= 0 && xdot(5) < 0
    xdot(5) = 0;
end

%% Record Data
Record(t, alpha, mach, Xcp, Xcg, Lref, 0.5);

end

function Record(t, alpha, mach, Xcp, Xcg, Lref, tstep)
% Records flight data to flight_record.mat
cd('../');
load('Data/record.mat');
i = size(record.time, 2);
if (i == 0) || (t > (record.time(i) + tstep))
    n = i+1;
    record.time(n)  = t;
    record.alpha(n) = alpha;
    record.mach(n)  = mach;
    record.xcp(n)   = Xcp;
    record.sm(n)    = (Xcp-Xcg)/Lref;
    clear t alpha mach Xcg Xcp Ca
    save('Data/record.mat');
end
cd('Functions');
end