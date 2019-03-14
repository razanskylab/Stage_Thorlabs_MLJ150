function Stop(TLJ)

	fprintf('[LabJack] Stopping device...');
	try
		TLJ.DeviceNet.StopImmediate();
		done();
	catch ex
		% Cannot initialise device
		short_warn('[LabJack] Unable to stop device!');
		rethrow(ex);
	end

end
