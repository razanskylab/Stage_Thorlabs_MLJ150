
classdef motor < handle
    % Matlab class to control Thorlabs motorised rotation stages
    % It is a 'wrapper' to control Thorlabs devices via the Thorlabs .NET
    % DLLs.
    %
    % Instructions:
    % Download the Kinesis DLLs from the Thorlabs website from:
    % https://www.thorlabs.com/software_pages/ViewSoftwarePage.cfm?Code=Motion_Control
    % Edit MOTORPATHDEFAULT below to point to the location of the DLLs
    % Connect your PRM1Z8 and/or K10CR1 rotation stage(s) to the PC USB port(if
    % using PRMZ8 also switch it on)
    %
    % Example:
    % a=motor.listdevices   % List connected devices
    % m1=motor              % Create a motor object
    % connect(m1,a{1})      % Connect the first devce in the list of devices
    % home(m1)              % Home the device
    % moveto(m1,45)         % Move the device to the 45 degree setting
    % moverel_deviceunit(m1, -100000) % Move 100000 'clicks' backwards
    % disconnect(m1)        % Disconnect device
    %
    % Author: Julan A.J. Fells
    % Dept. Engineering Science, University of Oxford, Oxford OX1 3PJ, UK
    % Email: julian.fells@emg.ox.ac.uk (please email issues and bugs)
    % Website: http://wwww.eng.ox.ac.uk/smp
    %
    % Known Issues:
    % 1. If motor object gets deleted or corrupted it is sometimes necessary to
    % restart Matlab
    %
    % Version History:
    % 1.0 14 March 2018 First Release


    properties (Constant, Hidden)
       % path to DLL files (edit as appropriate)
       MOTORPATHDEFAULT='C:\Program Files\Thorlabs\Kinesis\'

       % DLL files to be loaded
       DEVICE_MANAGER_DLL='Thorlabs.MotionControl.DeviceManagerCLI.dll';
       DEVICE_MANAGER_CLASS_NAME='Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI'
       GENERICMOTORDLL='Thorlabs.MotionControl.GenericMotorCLI.dll';
       GENERICMOTORCLASSNAME='Thorlabs.MotionControl.GenericMotorCLI.GenericMotorCLI';
       DCSERVODLL='Thorlabs.MotionControl.KCube.DCServoCLI.dll';
       DCSERVOCLASSNAME='Thorlabs.MotionControl.KCube.DCServoCLI.KCubeDCServo';
       INTEGSTEPDLL='Thorlabs.MotionControl.IntegratedStepperMotorsCLI.dll'
       INTEGSTEPCLASSNAME='Thorlabs.MotionControl.IntegratedStepperMotorsCLI.IntegratedStepperMotor.CageRotator';

       % Default intitial parameters
       DEFAULTVEL=10;           % Default velocity
       DEFAULTACC=10;           % Default acceleration
       TPOLLING=250;            % Default polling time
       TIMEOUTSETTINGS=7000;    % Default timeout time for settings change
       TIMEOUTMOVE=100000;      % Default time out time for motor move
    end
    properties
       % These properties are within Matlab wrapper
       isconnected=false;           % Flag set if device connected
       serialnumber;                % Device serial number
       controllername;              % Controller Name
       controllerdescription        % Controller Description
       stagename;                   % Stage Name
       position;                    % Position
       acceleration;                % Acceleration
       maxvelocity;                 % Maximum velocity limit
       minvelocity;                 % Minimum velocity limit
    end
    properties (Hidden)
       % These are properties within the .NET environment.
       deviceNET;                   % Device object within .NET
       motorSettingsNET;            % motorSettings within .NET
       currentDeviceSettingsNET;    % currentDeviceSetings within .NET
       deviceInfoNET;               % deviceInfo within .NET
    end
    methods

        function connect(h,serialNr)  % Connect device
            listdevices();    % Use this call to build a device list in case not invoked beforehand
            if ~isconnected
                switch(serialNr(1:2))
                    case '27'   % Serial number corresponds to a PRM1Z8
                        DeviceNet=Thorlabs.MotionControl.KCube.DCServoCLI.KCubeDCServo.CreateKCubeDCServo(serialNr);
                    case '55'   % Serial number corresponds to a K10CR1
                        DeviceNet=Thorlabs.MotionControl.IntegratedStepperMotorsCLI.CageRotator.CreateCageRotator(serialNr);
                    otherwise % Serial number is not a PRM1Z8 or a K10CR1
                        error('Stage not recognised');
                end
                DeviceNet.ClearDeviceExceptions();    % Clear device exceptions via .NET interface
                DeviceNet.Connect(serialNr);          % Connect to device via .NET interface
                try
                    if ~DeviceNet.IsSettingsInitialized() % Wait for IsSettingsInitialized via .NET interface
                        DeviceNet.WaitForSettingsInitialized(TIMEOUTSETTINGS);
                    end
                    if ~DeviceNet.IsSettingsInitialized() % Cannot initialise device
                        error(['Unable to initialise device ',char(serialNr)]);
                    end
                    DeviceNet.StartPolling(TPOLLING);   % Start polling via .NET interface
                    motorSettingsNET=DeviceNet.GetMotorConfiguration(serialNr); % Get motorSettings via .NET interface
                    currentDeviceSettingsNET=DeviceNet.MotorDeviceSettings;     % Get currentDeviceSettings via .NET interface
                    deviceInfoNET=DeviceNet.GetDeviceInfo();                    % Get deviceInfo via .NET interface
                    MotDir=Thorlabs.MotionControl.GenericMotorCLI.Settings.RotationDirections.Forwards; % MotDir is enumeration for 'forwards'
                    currentDeviceSettingsNET.Rotation.RotationDirection=MotDir;   % Set motor direction to be 'forwards#
                catch % Cannot initialise device
                    error(['Unable to initialise device ',char(serialNr)]);
                end
            else % Device is already connected
                error('Device is already connected.')
            end
            updatestatus(h);   % Update status variables from device
        end

        function reset(h,serialNr)    % Reset device
            DeviceNet.ClearDeviceExceptions();  % Clear exceptions vua .NET interface
            DeviceNet.ResetConnection(serialNr) % Reset connection via .NET interface
        end
        function home(h)              % Home device (must be done before any device move
            workDone=DeviceNet.InitializeWaitHandler();     % Initialise Waithandler for timeout
            DeviceNet.Home(workDone);                       % Home devce via .NET interface
            DeviceNet.Wait(TIMEOUTMOVE);                  % Wait for move to finish
            updatestatus(h);            % Update status variables from device
        end
        function moveto(h,position)     % Move to absolute position
            try
                workDone=DeviceNet.InitializeWaitHandler(); % Initialise Waithandler for timeout
                DeviceNet.MoveTo(position, workDone);       % Move devce to position via .NET interface
                DeviceNet.Wait(TIMEOUTMOVE);              % Wait for move to finish
                updatestatus(h);        % Update status variables from device
            catch % Device faile to move
                error(['Unable to Move device ',serialnumber,' to ',num2str(position)]);
            end
        end
        function moverel_deviceunit(h, noclicks)  % Move relative by a number of device clicks (noclicks)
            if noclicks<0   % if noclicks is negative, move device in backwards direction
                motordirection=Thorlabs.MotionControl.GenericMotorCLI.MotorDirection.Backward;
                noclicks=abs(noclicks);
            else            % if noclicks is positive, move device in forwards direction
                motordirection=Thorlabs.MotionControl.GenericMotorCLI.MotorDirection.Forward;
            end             % Perform relative device move via .NET interface
            DeviceNet.MoveRelative_DeviceUnit(motordirection,noclicks,TIMEOUTMOVE);
            updatestatus(h);            % Update status variables from device
        end
        function movecont(h, varargin)  % Set motor to move continuously
            if (nargin>1) && (varargin{1})      % if parameter given (e.g. 1) move backwards
                motordirection=Thorlabs.MotionControl.GenericMotorCLI.MotorDirection.Backward;
            else                                % if no parametr given move forwards
                motordirection=Thorlabs.MotionControl.GenericMotorCLI.MotorDirection.Forward;
            end
            DeviceNet.MoveContinuous(motordirection); % Set motor into continous move via .NET interface
            updatestatus(h);            % Update status variables from device
        end
        function stop(h) % Stop the motor moving (needed if set motor to continous)
            DeviceNet.Stop(TIMEOUTMOVE); % Stop motor movement via.NET interface
            updatestatus(h);            % Update status variables from device
        end
        function updatestatus(h) % Update recorded device parameters in matlab by reading them from the devuce
            isconnected=boolean(DeviceNet.IsConnected());   % update isconncted flag
            serialnumber=char(DeviceNet.DeviceID);          % update serial number
            controllername=char(deviceInfoNET.Name);        % update controleller name
            controllerdescription=char(deviceInfoNET.Description);  % update controller description
            stagename=char(motorSettingsNET.DeviceSettingsName);    % update stagename
            velocityparams = DeviceNet.GetVelocityParams();             % update velocity parameter
            acceleration=System.Decimal.ToDouble(velocityparams.Acceleration); % update acceleration parameter
            maxvelocity=System.Decimal.ToDouble(velocityparams.MaxVelocity);   % update max velocit parameter
            minvelocity=System.Decimal.ToDouble(velocityparams.MinVelocity);   % update Min velocity parameter
            position=System.Decimal.ToDouble(DeviceNet.Position);   % Read current device position
        end
        function setvelocity(h, varargin)  % Set velocity and acceleration parameters
            velpars=DeviceNet.GetVelocityParams(); % Get existing velocity and acceleration parameters
            switch(nargin)
                case 1  % If no parameters specified, set both velocity and acceleration to default values
                    velpars.MaxVelocity=DEFAULTVEL;
                    velpars.Acceleration=DEFAULTACC;
                case 2  % If just one parameter, set the velocity
                    velpars.MaxVelocity=varargin{1};
                case 3  % If two parameters, set both velocitu and acceleration
                    velpars.MaxVelocity=varargin{1};  % Set velocity parameter via .NET interface
                    velpars.Acceleration=varargin{2}; % Set acceleration parameter via .NET interface
            end
            if System.Decimal.ToDouble(velpars.MaxVelocity)>25  % Allow velocity to be outside range, but issue warning
                warning('Velocity >25 deg/sec outside specification')
            end
            if System.Decimal.ToDouble(velpars.Acceleration)>25 % Allow acceleration to be outside range, but issue warning
                warning('Acceleration >25 deg/sec2 outside specification')
            end
            DeviceNet.SetVelocityParams(velpars); % Set velocity and acceleration paraneters via .NET interface
            updatestatus(h);        % Update status variables from device
        end

    end
    methods (Static)
    end
end
