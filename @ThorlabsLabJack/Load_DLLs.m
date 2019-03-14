function Load_DLLs(TLJ)
	fprintf('[LabJack] Adding .NET assemblies...');
	TLJ.DeviceManagerAssembly = NET.addAssembly([TLJ.DLL_PATH, TLJ.DEVICE_MANAGER_DLL]);
	TLJ.StepperAssembly       = NET.addAssembly([TLJ.DLL_PATH, TLJ.INTEGRATE_STEPPER_DLL]);
	done();
end
