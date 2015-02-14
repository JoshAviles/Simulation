function PlotFlight(FlightRecord)
%PlotData - given an input file, it plots the variables

close all

convert = true;

% extract data
t     = FlightRecord.t;
x     = FlightRecord.x;
y     = FlightRecord.y;
theta = FlightRecord.theta;
vx    = FlightRecord.vx;
vy    = FlightRecord.vy;
omega = FlightRecord.omega;
mach  = FlightRecord.mach;
alpha = FlightRecord.alpha;
Xcp   = FlightRecord.Xcp;
if isfield(FlightRecord,'sm')
    sm = FlightRecord.sm;
end



% Plot Variables from ODE Solver
figure(2)
if convert
    plot(convlength(x,'m','ft'),convlength(y,'m','ft')) 
    title(['Trajectory (Apogee: ',num2str(convlength(max(y),'m','ft'),'%6.0f'),' ft)'])
    xlabel('X (ft)')
    ylabel('Y (ft)')
    hold on
    plot(0,0,'-o','MarkerFaceColor','b')
    plot(convlength(x(end),'m','ft'),convlength(y(end),'m','ft'),...
        '-s','MarkerFaceColor','r','MarkerEdgeColor','r')
else
    plot(x,y) 
    title(['Trajectory (Apogee: ',num2str(max(y),'%6.0f'),' m)'])
    xlabel('X (m)')
    ylabel('Y (m)')
    hold on
    plot(0,0,'-o','MarkerFaceColor','b')
    plot(x(end),y(end),'-s','MarkerFaceColor','r','MarkerEdgeColor','r')
end

A = axis;
A(3) = 0;
axis(A);
axis equal



figure(3)
    subplot(4,2,[1:2])
        plot(t,y)
        title('Height vs. Time')
        xlabel('Time [s]')
        ylabel('Height [m]')
        A = axis;
        A(3) = 0;
        axis(A);
        
    subplot(4,2,3)
        plot(t,x)
        title('Range (Downwind) vs. Time');
        xlabel('Time [s]');
        ylabel('Range [m]');
        
    subplot(4,2,4)
        plot(t,theta)
        title('Attitude vs. Time')
        xlabel('Time [s]')
        ylabel('Attitude [radians]')
        
    subplot(4,2,5)
        plot(t,vx)
        title('Horizontal Velocity vs. Time')
        xlabel('Time [s]')
        ylabel('Horizontal Velocity [m/s]')
        
    subplot(4,2,6)
        plot(t,vy)
        title('Vertical Velocity vs. Time')
        xlabel('Time [s]')
        ylabel('Vertical Velocity [m/s]')
        
    subplot(4,2,7)
        plot(t,omega)
        title('Angular Velocity vs. Time')
        xlabel('Time [s]')
        ylabel('Angular Velocity [radians/s]')
        
    subplot(4,2,8)
        plot(t, sqrt(vx.^2+vy.^2))
        title('Velocity v. Time')
        xlabel('Time [s]')
        ylabel('Velocity [m/s]')

% Plot extra stuff

figure(4)
    subplot(2,2,1)
        plot(t,alpha); 
        xlabel('Time [s]'); 
        ylabel('Angle of Attack [deg]');

    subplot(2,2,2)
        plot(t,mach) 
        xlabel('Time [s]')
        ylabel('Mach Number')

    subplot(2,2,3)
        plot(t,Xcp); 
        xlabel('Time [s]')
        ylabel('Xcp [m]')
if isfield(FlightRecord,'sm')
    subplot(2,2,4)
        plot(t,sm); 
        xlabel('Time [s]')
        ylabel('SM')
end
        
%{
    subplot(2,2,4)
        SM = (Xcp)./lref;
        plot(t,SM) 
        title('Stability Margin'); 
        xlabel('Time [s]')
        ylabel('Stability Margin')
        
        %}
% load rocket image
cd('../')
rocket = imread('Data/Rocket.bmp');
window = [125 625 125 625];
cd('Functions')


% Generate Movie

tsteps = 10000;
tfinal = 200;
frames = 5;
speed  = 5;
box off;

disp('Press any key to play animation')
pause

for i = 1:(size(t)/frames)
    figure(2);
        if i~=1
            delete(point);
        end
        if convert
            point = plot(convlength(x(i*frames),'m','ft'),...
                convlength(y(i*frames),'m','ft'),'-s',...
                'MarkerFaceColor','g','MarkerEdgeColor','g');
        else
            point = plot(x(i*frames),y(i*frames),'-s',...
                'MarkerFaceColor','g','MarkerEdgeColor','g');
        end
        
    animation = figure(5);
    if convert
        angle    = theta(i*frames);
        velocity = sqrt(vx(i*frames)^2+vy(i*frames)^2);
        rocket_angled = imrotate(rocket,radtodeg(angle),'crop');
        imshow(rocket_angled);
        axis(window);
    
        text(525,150,['Altitude: ',num2str(convlength(y(i*frames),'m','ft'),'%6.0f'),' ft'])
        text(525,170,['Velocity: ',num2str(convvel(velocity,'m/s','ft/s'),'%6.0f'),' ft/s'])
    else
        angle    = theta(i*frames);
        velocity = sqrt(vx(i*frames)^2+vy(i*frames)^2);
        rocket_angled = imrotate(rocket,(180/pi)*(angle),'crop');
        imshow(rocket_angled);
        axis(window);
        text(525,150,['Altitude: ',num2str(y(i*frames),'%6.0f'),' m'])
        text(525,170,['Velocity: ',num2str(velocity,'%6.0f'),' m/s'])
    end
    drawnow;
    M(i) = getframe(animation);
    pause(tfinal*frames/tsteps/speed);
    
    
end
movie2avi(M,'Manchester_02.avi')
disp('Movie Played')
end


