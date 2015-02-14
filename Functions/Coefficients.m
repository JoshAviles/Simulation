function [Ca,Cn,Xcp] = Coefficients(mach,alpha,aero)
% [Ca,Cn,Xcp] = Coefficients(mach,alpha,altitude,aero)
% Load the Aerodynamic Coeffients for the rocket given a mach, angle of
% attack, and altitude. This will also return a negative Cn
%
% INPUTS:
%       mach     = the Mach number we want to lookup at
%       alpha    = the angle of attack we want to lookup at (degrees)
%       altitude = the altitude that we want to lookup at (meters)
%       aero     = the aerodynamic data for the vehicle
%
% OUTPUTS:
%       Ca  = the axial force coefficient
%       Cn  = the normal force coefficient
%       Xcp = the center of pressure

if alpha >= 0
    a_neg = false;  
else
    a_neg = true;
end

if mach < min(aero.mach);
    disp(['Mach out of range: ',num2str(mach)])
    mach = min(aero.mach);
elseif mach > max(aero.mach); 
    disp(['Mach out of range: ',num2str(mach)])
    mach = max(aero.mach);    
end

alpha = abs(alpha);
if alpha > max(aero.alpha)
    disp(['Alpha out of range: ',num2str(alpha)])
    alpha = max(aero.alpha);
end

[X,Y] = meshgrid(aero.mach,aero.alpha);

Ca  = interp2(X,Y,aero.ca,  mach, alpha);
Cn  = interp2(X,Y,aero.cn,  mach, alpha);
Xcp = interp2(X,Y,aero.xcp, mach, alpha);



if a_neg
    Cn = -Cn;
end
coeff = [Ca, Cn, Xcp];

end

