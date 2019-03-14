TLJ = ThorlabsLabJack();
TLJ.Home();

% set default speed and acc
TLJ.vel = TLJ.DEFAULT_VEL;
TLJ.acc = TLJ.DEFAULT_ACC;

TLJ.pos = 25; % move to position you like...

TLJ.Stop();

TLJ.Disconnect();
