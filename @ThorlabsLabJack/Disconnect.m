function Disconnect(TLJ)
	fprintf('[LabJack] Disconnecting device...');

  if TLJ.isConnected
    try
      TLJ.DeviceNet.StopPolling();  % Stop polling device via .NET interface
      TLJ.DeviceNet.Disconnect();   % Disconnect device via .NET interface
			done();
		catch ex
	 		% Cannot initialise device
		  short_warn('[LabJack] Unable to disconnect device!');
			rethrow(ex);
		end
  else % Cannot disconnect because device not connected
    short_warn('Device already disconnected.');
  end
end
