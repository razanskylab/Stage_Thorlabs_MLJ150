classdef ThorlabsLabJack < handle

	properties (Constant, Hidden)

		% path to DLL files (edit as appropriate)
		DLL_PATH = 'C:\Program Files\Thorlabs\Kinesis\';

		% DLL files to be loaded
		DEVICE_MANAGER_DLL = 		'Thorlabs.MotionControl.DeviceManagerCLI.dll';
		INTEGRATE_STEPPER_DLL = 'Thorlabs.MotionControl.IntegratedStepperMotorsCLI.dll';

  	POLLING_TIME = 250; % Default polling time
		TIME_OUT_SETTINGS = 7000;  % [ms] Default timeout time for settings change
		TIME_OUT_MOVE = 100000;    % [ms] Default time out time for motor move
		DEFAUL_SERIAL_NR = '49905570';

		DO_AUTO_CONNECT = true;
		DO_AUTO_HOME = true;
		SET_DEFAULT_VEL_ACC = true;
	end

	properties (Constant, Hidden)
  	POS_RANGE = [0 50]; % [mm]
  	VEL_RANGE = [0 5]; % [mm/s]
  	ACC_RANGE = [0 10]; % [mm2/s]

		DEFAULT_VEL = 5;            % [mm/s] Default velocity
		DEFAULT_ACC = 10;            % [mm2/s] Default acceleration
	end

	properties
		serialNr(1,:) char = '';

		pos(1,1) {mustBeNumeric};
		vel(1,1) {mustBeNumeric};
		acc(1,1) {mustBeNumeric};

		% Net Properties
		DeviceNet;
		DeviceManagerAssembly; % see Load_DLLs
		StepperAssembly; % see Load_DLLs
	end

	properties (Dependent = true)
		isConnected;
		needsHoming;
	end

	methods
		function TLJ = ThorlabsLabJack(varargin)
			TLJ.Load_DLLs;
			if (nargin == 1) && ischar(varargin{1})
				TLJ.serialNr = varargin{1};
			else
				TLJ.serialNr = TLJ.DEFAUL_SERIAL_NR;
    	end

			if TLJ.DO_AUTO_CONNECT && ~TLJ.isConnected
				TLJ.Connect();
			end
			% home if needed and desired...
			if TLJ.DO_AUTO_HOME && TLJ.isConnected && TLJ.DeviceNet.NeedsHoming()
				TLJ.Home();
			end
			if TLJ.SET_DEFAULT_VEL_ACC && TLJ.isConnected
				TLJ.vel = TLJ.DEFAULT_VEL;
				TLJ.acc = TLJ.DEFAULT_ACC;
			end
		end

		function delete(TLJ)
			if TLJ.isConnected
				TLJ.Disconnect();
			end
		end

	end % < end constructur / destructor methodes

	% set/get methods %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	methods
		%%===========================================================================
		% Moves to position and waits until target positon is reached
		function set.pos(TLJ, pos)
			if pos > max(TLJ.POS_RANGE) || pos < min(TLJ.POS_RANGE)
				short_warn('Requested position out of range!');
			else
				try
        	workDone = TLJ.DeviceNet.InitializeWaitHandler(); % Initialise Waithandler for timeout
        	TLJ.DeviceNet.MoveTo(pos, workDone); % Move device to position via .NET interface
        	TLJ.DeviceNet.Wait(TLJ.TIME_OUT_MOVE);              % Wait for move to finish
				catch me % Cannot initialise device
      		error(['Unable to Move device to ',num2str(pos)]);
					rethrow me;
    		end
			end
		end

		% Get current device position
		function pos = get.pos(TLJ)
				pos = System.Decimal.ToDouble(TLJ.DeviceNet.Position);
		end

		%%===========================================================================
		% Sets target velocity of the stage
		function set.vel(TLJ, vel)
			if vel > max(TLJ.VEL_RANGE) || vel < min(TLJ.VEL_RANGE)
				short_warn('Requested velocity out of range!');
			else
				velpars = TLJ.DeviceNet.GetVelocityParams();
				velpars.MaxVelocity = vel;
				TLJ.DeviceNet.SetVelocityParams(velpars);
			end
		end

    % Read velocity from stage controller
    function vel = get.vel(TLJ)
      velpars = TLJ.DeviceNet.GetVelocityParams();
      vel = System.Decimal.ToDouble(velpars.MaxVelocity);
    end

		%%===========================================================================
		% Sets target acceleration of the stage
		function set.acc(TLJ, acc)
			if acc > max(TLJ.ACC_RANGE) || acc < min(TLJ.ACC_RANGE)
				short_warn('Requested velocity out of range!');
			else
				velpars = TLJ.DeviceNet.GetVelocityParams();
				velpars.Acceleration = acc;
				TLJ.DeviceNet.SetVelocityParams(velpars);
			end
		end

    % Read velocity from stage controller
    function acc = get.acc(TLJ)
      velpars = TLJ.DeviceNet.GetVelocityParams();
      acc = System.Decimal.ToDouble(velpars.Acceleration);
    end

		%%===========================================================================
    function isConnected = get.isConnected(TLJ)
      if isobject(TLJ.DeviceNet) && TLJ.DeviceNet.IsConnected();
        isConnected = true;
      else
        isConnected = false;
      end
    end

		%%===========================================================================
    function needsHoming = get.needsHoming(TLJ)
      if TLJ.isConnected
        needsHoming = TLJ.DeviceNet.NeedsHoming();
			else
				needsHoming = [];
			end
    end

	end % < end set/get methods

end % < end class
