function Connect(TLJ)

	if TLJ.isConnected
		short_warn('[LabJack] Already connected!');
		return;
	else
		Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI.BuildDeviceList();  % Build device list
		serialNumbers = Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI.GetDeviceList(); % Get device list
		serialNumbers = cell(ToArray(serialNumbers)); % Convert serial numbers to cell array
		if isempty(serialNumbers)
			short_warn('[LabJack] No Thorlabs stages found!');
			return;
		end

		% CONNECT TO LAB JACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		try
		  deviceFound =  any(strcmp(serialNumbers,TLJ.serialNr));
         
		  if deviceFound
		    TLJ.DeviceNet = Thorlabs.MotionControl.IntegratedStepperMotorsCLI.LabJack.CreateLabJack(TLJ.serialNr);
				fprintf('[LabJack] Device found...');
			else
				short_warn('[LabJack] Device not found!');
				return;
		  end

			fprintf('connecting...');
		  TLJ.DeviceNet.ClearDeviceExceptions();
		    % Clears the the last device exceptions if any.
		  TLJ.DeviceNet.ConnectDevice(TLJ.serialNr);
		  TLJ.DeviceNet.Connect(TLJ.serialNr);
		    % Connects to the device with the supplied serial number.

			fprintf('initializing...');
		  if ~TLJ.DeviceNet.IsSettingsInitialized() % Wait for IsSettingsInitialized via .NET interface
	      TLJ.DeviceNet.WaitForSettingsInitialized(TLJ.TIME_OUT_SETTINGS);
		  end
		  if ~TLJ.DeviceNet.IsSettingsInitialized() % Cannot initialise device
	      error('[LabJack] Unable to initialise device!');
		  end

	    TLJ.DeviceNet.StartPolling(TLJ.POLLING_TIME);   % Start polling via .NET interface
			TLJ.DeviceNet.EnableDevice();
	    TLJ.DeviceNet.LoadMotorConfiguration(TLJ.serialNr);
	      % Initializes the current motor configuration.  This will load the
	      % settings appropriate for the motor as defined in the
	      % DeviceConfiguration settings. This should only be called once. Calling
	      % this function will ensure the configuration is setup correctly with
	      % the correct device unit converter. This call will also upload the
	      % current device settings for the device with only the specified
	      % settings prior to returning as defined by the MotorConfiguration
	      % settings

			done();
		catch ex
	 		% Cannot initialise device
		  short_warn('[LabJack] Unable to initialise device!');
			rethrow(ex);
		end
end
