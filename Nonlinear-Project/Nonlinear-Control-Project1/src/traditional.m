function traditional
close all
%Set up parameters for sim
p1       = 3.473;
p2       = 0.196;
p3       = 0.242;
f1       = 5.3;
f2       = 1.1;

% Stacked parameter vector
theta    = [p1;p2;p3;f1;f2];

% Simulation final time
tf   = 10;

% Initial condition vector (X0 must be same size and "form" as X and XDot below)
% (i.e., in this sim, X0 = [e0;r0;thetahat0])
X0   = [4;10;3;2;1;1;1;1;1];

% Options for integration function
opts = odeset('RelTol',1e-3,'AbsTol',1e-3);

global his;
keyset  = {'time','tau'};
keyvalue = {10,[10;10]};
his = containers.Map(keyset,keyvalue);


% Integrate (you can send the paramters theta to the dynamics as seen below)
[t,STATES] = ode45(@(t,X) tradynamics(t,X,theta),[0 tf],X0,opts);
% Set up desired trajectory data for plots (enter desired trajectory for your simulation)
qd = [cos(0.5*t) 2*cos(t)]';

% Parse integrated states (STATES is the same "form" as X0)
% (i.e., in this sim, STATES = [e r thetahat] over all time);
e  = STATES(:,1:2)';
r  = STATES(:,3:4)';
thetaHat = STATES(:,5:9)';

% Compute x from e and xd for plotting purposes
q  = e + qd;
% Plot the actual vs desired trajectories
figure(1)
plot(t,qd,'-','LineWidth',2)
hold on
ax = gca;
ax.ColorOrderIndex = 1;
plot(t,q,':','LineWidth',2)
hold off

% Plot the filtered tracking error
figure(2)
plot(t,r,'--','LineWidth',2)

% Plot the adaptive estimates vs actual parameters
figure(3)
plot(t,repmat(theta,1,length(t)),'-','LineWidth',2)
hold on
ax = gca;
ax.ColorOrderIndex = 1;
plot(t,thetaHat,':','LineWidth',2)
hold off

figure(4)
plot(t,thetaHat-repmat(theta,1,length(t)),'-','LineWidth',2)

size(his('time'))
size(his('tau'))
size(t)

time = his('time');
tau = his('tau');
figure(5)
plot(time,tau,'-','LineWidth',2)



function [XDot] = tradynamics(t,X,theta)

global his;

% Parse parameter vector
p1 = theta(1);
p2 = theta(2);
p3 = theta(3);
f1 = theta(4);
f2 = theta(5);

% Select gains for controller
K        = 5; %Enter a number
a        = 1.5; %Enter a number

% Desired trajectory and needed derivatives
qd       = [cos(0.5*t);2*cos(t)];
qdDot    = [-0.5*sin(0.5*t); -2*sin(t)];
qdDotDot = [-0.25*cos(0.5*t); -2*cos(t)];

% Parse current states (X is the same size and "form" as X0)
% (i.e., in this sim, X = [e;r;thetahat])
e        = [X(1);X(2)];
r        = [X(3);X(4)];
thetaHat = [X(5);X(6);X(7);X(8);X(9)];

% Compute current x and xDot for convenience
q        = qd - e;
qDot     = r - a*e + qdDot;

% Compute cos(x2) and sin(x2) for convenience
c2       = cos(q(2));
s2       = sin(q(2));

% Compute current matrices for the dynamics
M        = [p1 + 2*p3*c2 p2 + p3*c2;p2 + p3*c2 p2];
Vm       = [-p3*s2*qDot(2) -p3*s2*(qDot(1) + qDot(2));p3*s2*qDot(1) 0];
fd       = [f1 0;0 f2];

% Compute current regression matrix
cd2       = cos(qd(2));
sd2       = sin(qd(2));
yd11      = qdDotDot(1); 
yd12      = qdDotDot(2); 
yd13      = 2*cd2*qdDotDot(1)+cd2*qdDotDot(2)-sd2*qdDot(2)*qdDot(1)-sd2*(qdDot(1)+qdDot(2))*qdDot(2);
yd14      = qdDot(1); 
yd15      = 0; 
yd21      = 0;
yd22      = qdDotDot(1)+qdDotDot(2); 
yd23      = cd2*qdDotDot(1)+sd2*qdDot(1)*qdDot(1); 
yd24      = 0; 
yd25      = qdDot(2); 
Yd       = [yd11 yd12 yd13 yd14 yd15;yd21 yd22 yd23 yd24 yd25];

% u        = -K*r + M*qdDotDot + Vm*qDot + fd*qDot; %Enter the expression
% u        = -K*r - e
u        = -K*r + Yd*thetaHat;

prevtimes = his('time');
prevtimes = prevtimes(t > prevtimes);
prevtaus = his('tau');
prevtaus = prevtaus(:,t > prevtimes);
his('time') = [prevtimes, t];
his('tau') = [prevtaus, u];

% Compute current closed-loop dynamics
eDot        = r - a*e;
rDot        = a*eDot + M\(-Vm*qDot-fd*qDot+u) - qdDotDot; %Enter the expression
gamma = eye([5,5]);
thetaHatDot = -gamma*Yd.'*r; %Enter the expression

t
% Stacked dynamics vector (XDot is the same size and "form" as X)
XDot        = [eDot;rDot;thetaHatDot];
