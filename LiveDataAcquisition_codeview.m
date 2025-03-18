classdef LiveDataAcquisition < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        LiveDataAcquisitionUIFigure     matlab.ui.Figure
        LiveViewPanel                   matlab.ui.container.Panel
        xlimEditField                   matlab.ui.control.NumericEditField
        xlimEditFieldLabel              matlab.ui.control.Label
        TimewindowEditField             matlab.ui.control.NumericEditField
        TimewindowsEditFieldLabel       matlab.ui.control.Label
        YmaxEditField                   matlab.ui.control.NumericEditField
        YmaxEditFieldLabel              matlab.ui.control.Label
        YminEditField                   matlab.ui.control.NumericEditField
        YminEditFieldLabel              matlab.ui.control.Label
        AutoscaleYSwitch                matlab.ui.control.Switch
        AutoscaleYSwitchLabel           matlab.ui.control.Label
        LiveAxes                        matlab.ui.control.UIAxes
        NeuroCrownRecordingLabel        matlab.ui.control.Label
        DevicePanel                     matlab.ui.container.Panel
        DeMUXshiftEditField             matlab.ui.control.NumericEditField
        DeMUXshiftEditFieldLabel        matlab.ui.control.Label
        LPF3dBEditField                 matlab.ui.control.NumericEditField
        LPF3dBEditFieldLabel            matlab.ui.control.Label
        HPF3dBEditField                 matlab.ui.control.NumericEditField
        HPF3dBEditFieldLabel            matlab.ui.control.Label
        FilterCheckBox                  matlab.ui.control.CheckBox
        GaincorrectCheckBox             matlab.ui.control.CheckBox
        HPFdriftremoveCheckBox          matlab.ui.control.CheckBox
        CalibrationDropDown             matlab.ui.control.DropDown
        CalibrationDropDownLabel        matlab.ui.control.Label
        AnalogsamplerateEditField       matlab.ui.control.NumericEditField
        AnalogsamplerateEditFieldLabel  matlab.ui.control.Label
        OversamplefactorEditField       matlab.ui.control.NumericEditField
        OversamplefactorEditFieldLabel  matlab.ui.control.Label
        DeMUXplotCheckBox               matlab.ui.control.CheckBox
        AnalogoutputDropDown            matlab.ui.control.DropDown
        AnalogoutputDropDownLabel       matlab.ui.control.Label
        MUXsettingDropDown              matlab.ui.control.DropDown
        MUXsettingDropDownLabel         matlab.ui.control.Label
        HPFresetDropDown                matlab.ui.control.DropDown
        HPFresetDropDownLabel           matlab.ui.control.Label
        DeviceDropDown                  matlab.ui.control.DropDown
        DeviceDropDownLabel             matlab.ui.control.Label
        CouplingDropDown                matlab.ui.control.DropDown
        CouplingDropDownLabel           matlab.ui.control.Label
        TerminalConfigDropDown          matlab.ui.control.DropDown
        TerminalConfigDropDownLabel     matlab.ui.control.Label
        RangeDropDown                   matlab.ui.control.DropDown
        RangeDropDownLabel              matlab.ui.control.Label
        MeasurementTypeDropDown         matlab.ui.control.DropDown
        MeasurementTypeDropDownLabel    matlab.ui.control.Label
        ChannelDropDown                 matlab.ui.control.DropDown
        ChannelDropDownLabel            matlab.ui.control.Label
        AcquisitionPanel                matlab.ui.container.Panel
        FiletextaddonEditField          matlab.ui.control.EditField
        FiletextaddonEditFieldLabel     matlab.ui.control.Label
        LogStatusText                   matlab.ui.control.Label
        LogdatatofileSwitch             matlab.ui.control.Switch
        LogdatatofileSwitchLabel        matlab.ui.control.Label
        StopButton                      matlab.ui.control.Button
        StartButton                     matlab.ui.control.Button
    end

    % 2018/02/09 version 1.0 Andrei Ursache
    % 2019/01/07 version 1.2, AU, Added IEPE measurement type
    % 2020/01/16 version 1.3, AU, updated DAQ code from Session to DataAcquisition interface

    % 2024/08/13 version 2.0, GS, added nidaqmx funcitonality
    
    
    properties (Access = private)
        DAQ                   % Handle to DAQ object
        DAQMeasurementTypes = {'Voltage','IEPE','Audio'};  % DAQ input measurement types supported by the app
        DAQSubsystemTypes = {'AnalogInput','AudioInput'};  % DAQ subsystem types supported by the app
        DevicesInfo           % Array of devices that provide analog input voltage or audio input measurements
        LogRequested          % Logical value, indicates whether user selected to log data to file from the UI (set by LogdatatofileSwitch)
        TimestampsFIFOBuffer  % Timestamps FIFO buffer used for live plot of latest "N" seconds of acquired data
        DataFIFOBuffer        % Data FIFO buffer used for live plot of latest "N" seconds of acquired data
        FIFOMaxSize = 1E+6    % Maximum allowed FIFO buffer size for DataFIFOBuffer and TimestampsFIFOBuffer
        LivePlotLine          % Handle to line plot of acquired data
        TriggerTime           % Acquisition start time stored as datetime
        TempFilename          % Temporary binary file name, acquired data is logged to this file during acquisition
        TempFile              % Handle of opened binary file, acquired data is logged to this file during acquisition
        Filename = 'daqdata.mat' % Default MAT file name at app start
        Filepath = pwd        % Default folder for saving the MAT file at app start

        % defines physical addresses on nidaq (see load_daqmx_constants(app) for full definitions)
        slot_name1              % slot of card 1
        slot_name2              % slot of card 2
        card_1_name             % name of chasis + slot = card
        card_2_name             % name of chasis + slot = card
        device_name
        device_name2
        DevTypeSize
        DevType
        clck_out_ID
        dreset_out_ID
        hpfreset_out_ID
        enableD_out_ID
        dig_power_on_ID
        dig_locations
        card_1_analogins
        card_2_analogins
        analog_output_address
        analog_output_address2

        % constants for daqmx states (see load_daqmx_constants(app) for full definitions)
        DAQmx_Val_WaitInfinitely
        DAQmx_Val_GroupByChannel
        DAQmx_Val_FiniteSamps
        DAQmx_Val_ContSamps
        DAQmx_Val_Rising
        DAQmx_Val_Falling
        DAQmx_Val_Task_Verify
        DAQmx_Val_Volts
        DAQmx_Val_Diff
        DAQmx_Val_Hz
        DAQmx_Val_Low
        DAQmx_Val_ChanPerLine
        DAQmx_Val_AllowRegen
        DAQmx_Val_DMA
        DAQmx_Val_Interrupts
        DAQmx_Val_OnBrdMemNotFull
        DAQmx_Val_DoNotInvertPolarity

        % defines sampling rate + record mode (see load_daqmx_constants(app) for full definitions)
        oversample_factor
        ai_sample_rate
        muxrate
        digital_data_rate
        dig_samps_per_analog
        samples_for_buffer
        time_step
        num_ch
        record_case
        HPF_status
        hpf_period
        hpf_duration
        n_hpf_period
        n_hpf_duration
        time_calibration
        n_analogins_per_card
        buffer_size_plot
        buffer_size_plot_calib
        init_data_reject
        plot_view
        samps_to_cut_st
        samps_to_cut_end
        time_record

        % properties for connecting backplanes for RTSIs (see connect_backplane_RTSI(app) for full definitions)
        RTSI0_config_sourceTerminal
        RTSI0_config_destinationTerminal
        RTSI0_config_signalModifiers

        % properties for digital output generation (see initialize_digital_outs(app) for full definitions)
        task_handle_digout
        digout_config_Lines
        digout_config_NamesofLines
        digout_config_LineGrouping

        digout_config_SampleRate
        digout_config_ClockSourceTerminal
        digout_config_ActiveEdge
        digout_config_SampleMode
        digout_config_SamplesToGenerate
        digital_data_out_CLK
        digital_data_out_DRESET
        digital_data_out_HPFRESET
        digital_data_out_enableD
        digital_data_out_digOn
        digital_data_out_total
        digout_config_TriggerSource
        digout_config_TriggerEdge
        digout_config_Nsamplesperchan
        digout_config_AutoStart
        digout_config_Timeout
        digout_config_DataLayout
        digout_config_WriteArray
        digout_config_Reserved

        % properties for analog input generation (see initialize_analog_ins(app) for full description)
        task_handle_ai1
        task_handle_ai2
        ai_config_PhysicalChannelcard1
        ai_config_PhysicalChannelcard2
        ai_config_ChannelName
        ai_config_TerminalConfig
        ai_config_MinValue
        ai_config_MaxValue
        ai_config_Units
        ai_config_CustomScaleName
        ai_config_SampleRate
        ai_config_ClockSourceTerminal
        ai_config_ActiveEdge
        ai_config_SampleMode
        ai_config_SamplesToAcquire
        ai_config_TriggerSource
        ai_config_TriggerEdge

        ai_config_NumSamplesPerChannel
        ai_config_Timeout
        ai_config_FillMode
        ai_config_BufferSize
        ai_config_DataCard1
        ai_config_DataCard2
        ai_config_SampsPerChanRead
        ai_config_ReservedBuffer
        ai_config_SampsPerChanReadcard1
        ai_config_SampsPerChanReadcard2
        time_vec
        time_vec_total
        samples_per_ai1
        data_out
        samples_per_ai2
        data_out2

        % properties for analog out (sound, see initialize_analog_out(app) for full description)
        task_handle_analogout
        analogout_config_physicalChannel
        analogout_config_nameToAssignToChannel
        analogout_config_minVal
        analogout_config_maxVal
        analogout_config_units
        analogout_config_customScaleName
        analogout_config_TriggerSource
        analogout_config_TriggerEdge
        analogout_config_SampleRate
        analogout_config_ClockSourceTerminal
        analogout_config_ActiveEdge
        analogout_config_SampleMode
        analogout_config_SamplesToAcquire
        analog_data_out_total
        analog_data_out_total_ch
        analog_data_out_onoroff
        analogout_config_Nsamplesperchan
        analogout_config_AutoStart
        analogout_config_Timeout
        analogout_config_DataLayout
        analogout_config_WriteArray
        analogout_config_Reserved
        analogout_samples_for_buffer
        analogout_samples_tomakeperch

        freq_val_order

        % properties for syncing ref clocks (see sync_ref_clks(app) for full description)
        clk_used_daqcard1
        clk_used_daqcard1_confirm
        clk_used_daqcard2
        clk_used_daqcard2_confirm
        clk_used_daqcard2dig
        clk_used_daqcard2dig_confirm   
        clk_used_daqcard2ao
        clk_used_daqcard2ao_confirm

        % control plotting
        is_stopbuttonpushed
        channel_to_plot
        loop_val

        % control output file 
        LogDataOut                  % if true, then file is made to output
        MUX_case
        HPF_case
        data_out_directory
        filename_analogdata
        fid_analogdata
        buffer_plot_time
        tasktype

        % control calibration
        calibrationselected
        iscalibrated
        samps_total_card1
        analog_calib_data
        time_vals_demuxed_calib
        sorted_data_calib
        time_vals_demuxed_cor
        avg_ch_reset_shape
        sorted_data_calib_cor
        avg_env_inv
        gaincorrect_option

        % control filtering
        filt_b
        filt_a
    end
    
    methods (Access = private)
        
        
        function scansAvailable_Callback(app, src, ~)
        %scansAvailable_Callback Executes on DAQ object ScansAvailable event
        %  This callback function gets executed periodically as more data is acquired.
        %  For a smooth live plot update, it stores the latest N seconds
        %  (specified time window) of acquired data and relative timestamps in FIFO
        %  buffers. A live plot is updated with the data in the FIFO buffer.
        %  If data logging option is selected in the UI, it also writes data to a
        %  binary file.
            
            if ~isvalid(app)
                return
            end
            
            [data,timestamps,triggertime] = read(src, src.ScansAvailableFcnCount, 'OutputFormat','Matrix');
            
            if app.LogRequested
                % If Log data to file switch is on
                latestdata = [timestamps, data]' ;
                fwrite(app.TempFile, latestdata, 'double');
                if timestamps(1)==0
                    app.TriggerTime = triggertime;
                end
            end
            
            % Store continuous acquisition data in FIFO data buffers
            buffersize = round(app.ai_sample_rate * app.TimewindowEditField.Value) + 1;
            app.TimestampsFIFOBuffer = storeDataInFIFO(app, app.TimestampsFIFOBuffer, buffersize, timestamps);
            app.DataFIFOBuffer = storeDataInFIFO(app, app.DataFIFOBuffer, buffersize, data(:,1));
            
            % Update plot data
            set(app.LivePlotLine, 'XData', app.TimestampsFIFOBuffer, 'YData', app.DataFIFOBuffer);
            if numel(app.TimestampsFIFOBuffer) > 1
                xlim(app.LiveAxes, [app.TimestampsFIFOBuffer(1), app.TimestampsFIFOBuffer(end)])
            end
        end
        
        function data = storeDataInFIFO(~, data, buffersize, datablock)
        %storeDataInFIFO Store continuous acquisition data in a FIFO data buffer
        %  Storing data in a finite-size FIFO buffer is used to plot the latest "N" seconds of acquired data for
        %  a smooth live plot update and without continuously increasing memory use.
        %  The most recently acquired data (datablock) is added to the buffer and if the amount of data in the
        %  buffer exceeds the specified buffer size (buffersize) the oldest data is discarded to cap the size of
        %  the data in the buffer to buffersize.
        %  input data is the existing data buffer (column vector Nx1).
        %  buffersize is the desired buffer size (maximum number of rows in data buffer) and can be changed.
        %  datablock is a new data block to be added to the buffer (column vector Kx1).
        %  output data is the updated data buffer (column vector Mx1).
        
            % If the data size is greater than the buffer size, keep only the
            % the latest "buffer size" worth of data
            % This can occur if the buffer size is changed to a lower value during acquisition
            if size(data,1) > buffersize
                data = data(end-buffersize+1:end,:);
            end
            
            if size(datablock,1) < buffersize
                % Data block size (number of rows) is smaller than the buffer size
                if size(data,1) == buffersize
                    % Current data size is already equal to buffer size.
                    % Discard older data and append new data block,
                    % and keep data size equal to buffer size.
                    shiftPosition = size(datablock,1);
                    data = circshift(data,-shiftPosition);
                    data(end-shiftPosition+1:end,:) = datablock;
                elseif (size(data,1) < buffersize) && (size(data,1)+size(datablock,1) > buffersize)
                    % Current data size is less than buffer size and appending the new
                    % data block results in a size greater than the buffer size.
                    data = [data; datablock];
                    shiftPosition = size(data,1) - buffersize;
                    data = circshift(data,-shiftPosition);
                    data(buffersize+1:end, :) = [];
                else
                    % Current data size is less than buffer size and appending the new
                    % data block results in a size smaller than or equal to the buffer size.
                    % (if (size(data,1) < buffersize) && (size(data,1)+size(datablock,1) <= buffersize))
                    data = [data; datablock];
                end
            else
                % Data block size (number of rows) is larger than or equal to buffer size
                data = datablock(end-buffersize+1:end,:);
            end
        end
        
        function [items, itemsData] = getChannelPropertyOptions(~, subsystem, propertyName)
        %getChannelPropertyOptions Get options available for a DAQ channel property
        %  Returns items and itemsData for displaying options in a dropdown component
        %  subsystem is the DAQ subsystem handle corresponding to the DAQ channel
        %  propertyName is channel property name as a character array, and can be
        %    'TerminalConfig', or 'Coupling', or 'Range'.
        %  items is a cell array of possible property values, for example {'DC', 'AC'}
        %  itemsData is [] (empty) for 'TerminalConfig' and 'Coupling', and is a cell array of
        %     available ranges for 'Range', for example {[-10 10], [-1 1]}
            
            switch propertyName
                case 'TerminalConfig'
                    items = cellstr(string(subsystem.TerminalConfigsAvailable));
                    itemsData = [];
                case 'Coupling'
                    items = cellstr(string(subsystem.CouplingsAvailable));
                    itemsData = [];
                case 'Range'
                    numRanges = numel(subsystem.RangesAvailable);
                    items = strings(numRanges,1);
                    itemsData = cell(numRanges,1);
                    for ii = 1:numRanges
                        range = subsystem.RangesAvailable(ii);
                        items(ii) = sprintf('%.2f to %.2f', range.Min, range.Max);
                        itemsData{ii} = [range.Min range.Max];
                    end
                    items = cellstr(items);                    
            end
        end
        
        
        function setAppViewState(app, state)
        %setAppViewState Sets the app in a new state and enables/disables corresponding components
        %  state can be 'deviceselection', 'configuration', 'acquisition', or 'filesave'
        
            switch state                
                case 'deviceselection'
                    app.AnalogsamplerateEditField.Enable = 'off';
                    app.DeviceDropDown.Enable = 'on';
                    app.ChannelDropDown.Enable = 'off';
                    app.MeasurementTypeDropDown.Enable = 'off';
                    app.RangeDropDown.Enable = 'off';
                    app.TerminalConfigDropDown.Enable = 'off';
                    app.CouplingDropDown.Enable = 'off';
                    app.StartButton.Enable = 'off';
                    app.LogdatatofileSwitch.Enable = 'off';                    
                    app.StopButton.Enable = 'off';
                    app.TimewindowEditField.Enable = 'off';
                    app.FiletextaddonEditField.Enable = 'off';
                    app.HPFdriftremoveCheckBox.Enable = 'off';
                    app.GaincorrectCheckBox.Enable = 'off';
                    app.FilterCheckBox.Enable = 'off';
                    app.HPF3dBEditField.Enable = 'off';
                    app.HPF3dBEditFieldLabel.Enable = 'off';
                    app.LPF3dBEditField.Enable = 'off';
                    app.LPF3dBEditFieldLabel.Enable = 'off';
                    app.DeMUXshiftEditFieldLabel.Enable = 'off';
                    app.DeMUXshiftEditField.Enable = 'off';
                case 'configuration'
                    app.AnalogsamplerateEditField.Enable = 'on';
                    app.DeviceDropDown.Enable = 'on';
                    app.ChannelDropDown.Enable = 'on';
                    app.MeasurementTypeDropDown.Enable = 'on';
                    app.RangeDropDown.Enable = 'on';
                    app.StartButton.Enable = 'on';
                    app.LogdatatofileSwitch.Enable = 'on';
                    app.StopButton.Enable = 'off';
                    app.TimewindowEditField.Enable = 'on';
                    app.FiletextaddonEditField.Enable = 'on';

                    switch app.DAQ.Channels(1).MeasurementType
                        case 'Voltage'
                            % Voltage channels do not have ExcitationSource
                            % property, so disable the corresponding UI controls
                            app.TerminalConfigDropDown.Enable = 'on';
                            app.CouplingDropDown.Enable = 'on';                            
                        case 'Audio'
                            % Audio channels do not have TerminalConfig, Coupling, and ExcitationSource
                            % properties, so disable the corresponding UI controls
                            app.TerminalConfigDropDown.Enable = 'off';
                            app.CouplingDropDown.Enable = 'off';                            
                        case 'IEPE'
                            app.TerminalConfigDropDown.Enable = 'on';
                            app.CouplingDropDown.Enable = 'on';                            
                    end
                case 'acquisition'
                    app.AnalogsamplerateEditField.Enable = 'off';
                    app.DeviceDropDown.Enable = 'off';
                    app.ChannelDropDown.Enable = 'off';
                    app.MeasurementTypeDropDown.Enable = 'off';
                    app.RangeDropDown.Enable = 'off';
                    app.TerminalConfigDropDown.Enable = 'off';
                    app.CouplingDropDown.Enable = 'off';
                    app.StartButton.Enable = 'off';
                    app.LogdatatofileSwitch.Enable = 'off';                    
                    app.StopButton.Enable = 'on';
                    app.TimewindowEditField.Enable = 'on';
                    app.FiletextaddonEditField.Enable = 'on';
                    updateLogdatatofileSwitchComponents(app)
                case 'filesave'
                    app.AnalogsamplerateEditField.Enable = 'off';
                    app.DeviceDropDown.Enable = 'off';
                    app.ChannelDropDown.Enable = 'off';
                    app.MeasurementTypeDropDown.Enable = 'off';
                    app.RangeDropDown.Enable = 'off';
                    app.TerminalConfigDropDown.Enable = 'off';
                    app.CouplingDropDown.Enable = 'off';
                    app.StartButton.Enable = 'off';
                    app.LogdatatofileSwitch.Enable = 'off';                    
                    app.StopButton.Enable = 'off';
                    app.TimewindowEditField.Enable = 'on';
                    app.FiletextaddonEditField.Enable = 'on';
                    updateLogdatatofileSwitchComponents(app)   
            end
        end
        
        
        function binFile2MAT(~, filenameIn, filenameOut, numColumns, metadata)
        %BINFILE2MAT Loads 2-D array of doubles from binary file and saves data to MAT file
        % Processes all data in binary file (filenameIn) and saves it to a MAT file without loading
        % all data to memory.
        % If output MAT file (filenameOut) already exists, data is overwritten (not appended).
        % Input binary file is a matrix of doubles with numRows x numColumns
        % MAT file (filenameOut) is a MAT file with the following variables
        %   timestamps = a column vector ,  the first column in the data from binary file
        %   data = a 2-D array of doubles, includes 2nd-last columns in the data from binary file
        %   metatada = a structure, which is provided as input argument, used to provide additional
        %              data information
                    
            % If filenameIn does not exist, error out
            if ~exist(filenameIn, 'file')
                error('Input binary file ''%s'' not found. Specify a different file name.', filenameIn);
            end
            
            % If output MAT file already exists, delete it
            if exist(filenameOut, 'file')
                delete(filenameOut)
            end
            
            % Determine number of rows in the binary file
            % Expecting the number of bytes in the file to be 8*numRows*numColumns
            fileInfo = dir(filenameIn);
            numRows = floor(fileInfo.bytes/(8*double(numColumns)));
            
            % Create matfile object to save data loaded from binary file
            matObj = matfile(filenameOut);
            matObj.Properties.Writable = true;
            
            % Initialize MAT file
            matObj.timestamps(numRows,1) = 0;
            matObj.data(numRows,1) = 0;
            
            % Open input binary file
            fid = fopen(filenameIn,'r');
            
            % Specify how many rows to process(load and save) at a time
            numRowsPerChunk = 10E+6;
            
            % Keeps track of how many rows have been processed so far
            ii = 0;
            
            while(ii < numRows)
                
                % chunkSize = how many rows to process in this iteration
                % If it's the last iteration, it's possible the number of rows left to
                % process is different from the specified numRowsPerChunk
                chunkSize = min(numRowsPerChunk, numRows-ii);
                
                data = fread(fid, [numColumns,chunkSize], 'double');
                
                matObj.timestamps((ii+1):(ii+chunkSize), 1) = data(1,:)';
                matObj.data((ii+1):(ii+chunkSize), 1) = data(2:end,:)';
                
                ii = ii + chunkSize;
            end
            
            fclose(fid);
            
            % Save provided metadata to MAT file
            matObj.metadata = metadata;
        end
        
        function deviceinfo = daqListSupportedDevices(app, subsystemTypes, measurementTypes)
        %daqListSupportedDevices Get connected devices that support the specified subsystem and measurement types      
            
            % Detect all connected devices
            devices = daqlist;
            deviceinfo = devices.DeviceInfo;
            
            % Keep a subset of devices which have the specified subystem and measurement types
            deviceinfo = daqFilterDevicesBySubsystem(app, deviceinfo, subsystemTypes);
            deviceinfo = daqFilterDevicesByMeasurement(app, deviceinfo, measurementTypes);
            
        end
                
        function filteredDevices = daqFilterDevicesBySubsystem(~, devices, subsystemTypes)
        %daqFilterDevicesBySubsystem Filter DAQ device array by subsystem type
        %  devices is a DAQ device info array
        %  subsystemTypes is a cell array of DAQ subsystem types, for example {'AnalogInput, 'AnalogOutput'}
        %  filteredDevices is the filtered DAQ device info array
            
            % Logical array indicating if device has any of the subsystem types provided
            hasSubsystemArray = false(numel(devices), 1);
            
            % Go through each device and see if it has any of the subsystem types provided
            for ii = 1:numel(devices)
                hasSubsystem = false;
                for jj = 1:numel(subsystemTypes)
                    hasSubsystem = hasSubsystem || ...
                        any(strcmp({devices(ii).Subsystems.SubsystemType}, subsystemTypes{jj}));
                end
                hasSubsystemArray(ii) = hasSubsystem;
            end
            filteredDevices = devices(hasSubsystemArray);
        end
        
        function filteredDevices = daqFilterDevicesByMeasurement(~, devices, measurementTypes)
        %daqFilterDevicesByMeasurement Filter DAQ device array by measurement type
        %  devices is a DAQ device info array
        %  measurementTypes is a cell array of measurement types, for example {'Voltage, 'Current'}
        %  filteredDevices is the filtered DAQ device info array
            
            % Logical array indicating if device has any of the measurement types provided
            hasMeasurementArray = false(numel(devices), 1);
            
            % Go through each device and subsystem and see if it has any of the measurement types provided
            for ii = 1:numel(devices)
                % Get array of available subsystems for the current device
                subsystems = [devices(ii).Subsystems];
                hasMeasurement = false;
                for jj = 1:numel(subsystems)
                    % Get cell array of available measurement types for the current subsystem
                    measurements = subsystems(jj).MeasurementTypesAvailable;
                    for kk = 1:numel(measurementTypes)
                        hasMeasurement = hasMeasurement || ...
                            any(strcmp(measurements, measurementTypes{kk}));
                    end
                end
                hasMeasurementArray(ii) = hasMeasurement;
            end
            filteredDevices = devices(hasMeasurementArray);
        end
        
        function updateRateUIComponents(app)
        %updateRateUIComponents Updates UI with current rate and time window limits
            
            % Update UI to show the actual data acquisition rate and limits
            value = app.AnalogsamplerateEditField.Value;
            
            % Update time window limits
            % Minimum time window shows 2 samples
            minTimeWindow = 1/value;
            maxTimeWindow = app.time_record;
            app.TimewindowEditField.Limits = [minTimeWindow, maxTimeWindow];
            
        end
        
        
        function closeApp_Callback(app, ~, event, isAcquiring)
        %closeApp_Callback Clean-up after "Close Confirm" dialog window
        %  "Close Confirm" dialog window is called from CloseRequestFcn
        %  of the app UIFigure.
        %   event is the event data of the UIFigure CloseRequestFcn callback.
        %   isAcquiring is a logical flag (true/false) corresponding to DAQ
        %   running state.            
            
            %   Before closing app if acquisition is currently on (isAcquiring=true) clean-up 
            %   data acquisition object and close file if logging.
            switch event.SelectedOption
                case 'OK'
                    if isAcquiring
                        % Acquisition is currently on
                        stop(app.DAQ)
                        delete(app.DAQ)
                        if app.LogRequested
                            fclose(app.TempFile);
                        end
                    else
                        % Acquisition is stopped
                    end

                    delete(app)
                case 'Cancel'
                    % Continue
            end
            
        end
        
        function updateAutoscaleYSwitchComponents(app)
        %updateAutoscaleYSwitchComponents Updates UI components related to y-axis autoscale
        
            value = app.AutoscaleYSwitch.Value;
            switch value
                case 'Off'
                    app.YminEditField.Enable = 'on';
                    app.YmaxEditField.Enable = 'on';
                    YmaxminValueChanged(app, []);
                case 'On'
                    app.YminEditField.Enable = 'off';
                    app.YmaxEditField.Enable = 'off';
                    app.LiveAxes.YLimMode = 'auto';
            end
        end
        
        function updateChannelMeasurementComponents(app)
        %updateChannelMeasurementComponents Updates channel properties and measurement UI components
            measurementType = app.MeasurementTypeDropDown.Value;

            % Get selected DAQ device index (to be used with DaqDevicesInfo list)
            deviceIndex = app.DeviceDropDown.Value - 1;
            deviceID = app.DevicesInfo(deviceIndex).ID;
            vendor = app.DevicesInfo(deviceIndex).Vendor.ID;
                        
            % Get DAQ subsystem information (analog input or audio input)
            % Analog input or analog output subsystems are the first subsystem of the device
            subsystem = app.DevicesInfo(deviceIndex).Subsystems(1);
            
            % Delete existing data acquisition object
            delete(app.DAQ);
            app.DAQ = [];
            
            % Create a new data acquisition object
            d = daq(vendor);
            addinput(d, deviceID, app.ChannelDropDown.Value, measurementType);
                        
            % Configure DAQ ScansAvailableFcn callback function
            d.ScansAvailableFcn = @(src,event) scansAvailable_Callback(app, src, event);
            
            % Store data acquisition object handle in DAQ app property
            app.DAQ = d;
             
            % Only 'Voltage', 'IEPE' and 'Audio' measurement types are supported in this version of the app
            % Depending on what type of device is selected, populate the UI elements channel properties
            switch subsystem.SubsystemType
                case 'AnalogInput'                                       
                    % Populate dropdown with available channel 'TerminalConfig' options
                    app.TerminalConfigDropDown.Items = getChannelPropertyOptions(app, subsystem, 'TerminalConfig');
                    % Update UI with the actual channel property value
                    % (default value is not necessarily first in the list)
                    % DropDown Value must be set as a character array in MATLAB R2017b
                    app.TerminalConfigDropDown.Value = d.Channels(1).TerminalConfig;
                    app.TerminalConfigDropDown.Tag = 'TerminalConfig';
                    
                    % Populate dropdown with available channel 'Coupling' options
                    app.CouplingDropDown.Items =  getChannelPropertyOptions(app, subsystem, 'Coupling');
                    % Update UI with the actual channel property value
                    app.CouplingDropDown.Value = d.Channels(1).Coupling;
                    app.CouplingDropDown.Tag = 'Coupling';
                                        
                    
                    ylabel(app.LiveAxes, 'Voltage (V)')
                                        
                case 'AudioInput'
                    ylabel(app.LiveAxes, 'Normalized amplitude')
            end
            
            % Update UI with current rate and time window limits
            updateRateUIComponents(app)
                    
            % Populate dropdown with available 'Range' options
            [rangeItems, rangeItemsData] = getChannelPropertyOptions(app, subsystem, 'Range');
            app.RangeDropDown.Items = rangeItems;
            app.RangeDropDown.ItemsData = rangeItemsData;
            
            % Update UI with current channel 'Range'
            currentRange = d.Channels(1).Range;
            app.RangeDropDown.Value = [currentRange.Min currentRange.Max];
            app.RangeDropDown.Tag = 'Range';
            
            app.DeviceDropDown.Items{1} = 'Deselect device';
            
            % Enable DAQ device, channel properties, and start acquisition UI components
            setAppViewState(app, 'configuration');

            app.ai_sample_rate      = app.AnalogsamplerateEditField.Value;   
            app.DAQ.Rate            = app.ai_sample_rate;
        end
        
        function updateLogdatatofileSwitchComponents(app)
            value = app.LogdatatofileSwitch.Value;
            switch value
                case 'Off'
                    app.LogDataOut = false;
                    disp('write data to file = off')
                    
                case 'On'
                    app.LogDataOut = true;
                    app.data_out_directory ='C:\Users\dropb\Documents\Gabi\NeuroCrown_raw_data';
                    disp('write data to file = on, files will be made in')
                    disp(app.data_out_directory)
            end
        end
        
        function load_daqmx_constants(app)
           % Setup nidaq names; (check NIMAX to see name)
            % chasis
            chasis_name = 1;
            if chasis_name == 1
                pxi_chasis_name = 'PXI1';
            elseif chasis_name == 2
                pxi_chasis_name = 'PXI2';
            else
                disp('Assign chasis name, 1 or 2 (check NIMAX to see name)')
            end
            % slot names
            app.slot_name1 = 'Slot2';
            app.slot_name2 = 'Slot3';
            % put it together & view
            app.card_1_name = append(pxi_chasis_name,app.slot_name1);
            app.card_2_name = append(pxi_chasis_name,app.slot_name2);
            
            %Define constants
            app.DAQmx_Val_WaitInfinitely = -1;
            app.DAQmx_Val_GroupByChannel =  0;
            app.DAQmx_Val_FiniteSamps    =  10178;  % Code to defines sample mode to be finite N samples - https://www.ni.com/docs/en-US/bundle/ni-daqmx-c-api-ref/page/mxcprop/attr1300.html
            app.DAQmx_Val_ContSamps      =  10123;	% Code to defines sample mode to be continuous samples - https://www.ni.com/docs/en-US/bundle/ni-daqmx-c-api-ref/page/mxcprop/attr1300.html
            app.DAQmx_Val_Rising         =  10280;  % Code to define rising edge to change value - https://www.ni.com/docs/en-US/bundle/ni-daqmx-c-api-ref/page/mxcprop/attr0697.html
            app.DAQmx_Val_Falling        =  10171;  % Code to define falling edge - https://www.ni.com/docs/en-US/bundle/ni-daqmx-c-api-ref/page/mxcprop/attr0697.html
            app.DAQmx_Val_Task_Verify    =  2;      % Code to define how to change a state of an action - https://documentation.help/NI-DAQmx-C-Functions/DAQmxTaskControl.html
            app.DAQmx_Val_Volts          =  10348;  % Code to specify we are using volts on the scale - https://documentation.help/NI-DAQmx-C-Properties/Attr18F7.html
            app.DAQmx_Val_Diff           =  10106;  % Code for differentialinput config - https://documentation.help/NI-DAQmx-C-Properties/Attr1097.html
            
            % for dig
            app.DAQmx_Val_Hz             =  10373;  % Code to define Hertz as unit for frequency https://documentation.help/NI-DAQmx-C-Properties/Attr0806.html
            app.DAQmx_Val_Low            =  10214;  % Code to define idle state of dig as low - https://documentation.help/NI-DAQmx-C-Properties/Attr21A7.html
            
            % for digital out, values here - https://gist.github.com/bjarthur/22b9d32f384e0e189ce4191e4c908950
            app.DAQmx_Val_ChanPerLine    =  0;      % Code to define line grouping as one channel for each line for digitals (https://documentation.help/NI-DAQmx-C-Functions/DAQmxCreateDOChan.html)
            app.DAQmx_Val_GroupByChannel =  0;      % Code to define how data is put into digital out matrix. 0 = non interleaved, 1 = interleaved (https://www.ni.com/docs/en-US/bundle/ni-daqmx/page/mxcncpts/interleaving.html)
            
            % Allow on board regen
            app.DAQmx_Val_AllowRegen     =  10097;  % Enables regen mode to prevent underflow https://documentation.help/NI-DAQmx-C-Properties/Attr1453.html
            app.DAQmx_Val_DMA            =  10054;  % Direct Memory Access. Data transfers take place independently from the application. - https://www.ni.com/docs/en-US/bundle/ni-daqmx-c-api-ref/page/mxcprop/attr2266.html
            app.DAQmx_Val_Interrupts     =  10204;  % Data transfers take place independently from the application. Using interrupts increases CPU usage because the CPU must service interrupt requests. Typically, you should use interrupts if the device is out of DMA channels. (same url as above)
            app.DAQmx_Val_OnBrdMemNotFull=  10242;  % Condition to specify buffer refill anytime it is not full
            
            % Define sampling rates of analog, digital, etc...
            app.oversample_factor   = app.OversamplefactorEditField.Value;
            app.ai_sample_rate      = app.AnalogsamplerateEditField.Value;   
            app.DAQ.Rate            = app.ai_sample_rate;
            
            % Sampling rate for analog in, i.e, 32 channels * 20 ksps = 640 ksps
            app.muxrate             = (1/app.oversample_factor)*app.ai_sample_rate;     % frequency of changing channels
            app.digital_data_rate   = 2*app.muxrate;                                % dig freq = 2X mux rate; Digital data rate for clock change = twice MUX rate change
            app.dig_samps_per_analog = app.ai_sample_rate/app.digital_data_rate;
            app.samples_for_buffer  = 4*app.ai_sample_rate;
            app.time_step           = 1/app.ai_sample_rate;
            app.num_ch              = 32;                                           % number of channels in mux (32 for 32:1)
            
            disp('over sample factor, AI rate, MUX rate, digital rate = ')
            disp(num2str(app.oversample_factor))
            disp(num2str(app.ai_sample_rate))
            disp(num2str(app.muxrate))
            disp(num2str(app.digital_data_rate))

            % RTSI connecting terminal constants
            app.DAQmx_Val_DoNotInvertPolarity = 0;                                  % do not invert polarity
            
            % Define channel info
            app.clck_out_ID = append(app.card_2_name,'/port0/line3');           % Output digital address for clock out (see mapping file)
            app.dreset_out_ID = append(app.card_2_name,'/port0/line2');         % Output digital address for dreset out, set to 1 during disable
            app.hpfreset_out_ID = append(app.card_2_name,'/port0/line6');       % Output digital address for hpfreset out, set to 1 during disable
            app.enableD_out_ID = append(app.card_2_name,'/port0/line1');        % Output digital address for enabling digital output of level shifter, write 0 to enable
            app.dig_power_on_ID = append(app.card_2_name,'/port0/line0');       % Output digital address for stim daq power on, set to 0 to disable, 1 to enable
            
            %dig_locations = append('PXI2Slot4/port0/line7',',','PXI2Slot4/port0/line1');
            app.dig_locations = append(app.clck_out_ID,',',app.dreset_out_ID,',',app.hpfreset_out_ID,',',app.enableD_out_ID,',',app.dig_power_on_ID);
            
            % define shank analog inputs (see HDMI file for mapping)                
            app.card_1_analogins = append(app.card_1_name,'/ai0:7');    %append(shank_1_address,',',shank_2_address,',',shank_5_address,',',shank_6_address, ',',shank_9_address,',',shank_10_address,',',shank_13_address,',',shank_14_address);
            app.card_2_analogins = append(app.card_2_name,'/ai0:7');
            
            % analog output address for speaker and analog out on sig
            app.analog_output_address = append(app.card_2_name,'/ao0');      % address for speaker out      
            app.analog_output_address2 = append(app.card_2_name,'/ao1');     % address for analog out on/off signal
            
            % analog input settings
            app.n_analogins_per_card = 8;                               % 8 analog inputs
            app.buffer_plot_time = 1;                                   % plot 1s of data
            app.buffer_size_plot = 4*app.buffer_plot_time*app.ai_sample_rate*app.n_analogins_per_card;          % plot in units of time
            
            %  decides which digital outputs to write and HPF parameters            
            app.hpf_period = 125e-3;                                    % reset every 125 ms
            app.hpf_duration = 0.2e-3;                                  % reset for 200 micro
            app.n_hpf_period = app.digital_data_rate *app.hpf_period;            % number of samples in hpf period
            app.n_hpf_duration = app.digital_data_rate*app.hpf_duration;         % number of samples in hpf duration
            disp('N samps hpf period and hpf duration = ')
            disp(num2str(app.n_hpf_period))
            disp(num2str(app.n_hpf_duration))
            
        end

        function reset_daq_device(app)
            % Reset daq 
            disp( '### Resetting Device ###' );
            
            app.device_name = app.card_1_name;
            [err_code] = daq.ni.NIDAQmx.DAQmxResetDevice(app.device_name);
            disp( '### Resetting Card 1 ###' );
            if err_code ~= 0
                disp( '### Reset card 2 error =  ###' );
                disp(num2str(err_code));
            end     
            
            app.device_name2 = app.card_2_name;
            [err_code] = daq.ni.NIDAQmx.DAQmxResetDevice(app.device_name2);
            disp( '### Resetting Card 2 ###' );
            if err_code ~= 0
                disp( '### Reset card 2 error =  ###' );
                disp(num2str(err_code));
            end
        end

        function connect_backplane_RTSI(app)
            % Attach RTSI0 from one card to another

            disp( '### Connect RTSI0 on card 1 to RTSI0 on card 2  ###' );
            
            % Define terminals
            app.RTSI0_config_sourceTerminal = append('/',app.card_2_name,'/RTSI0');     
            app.RTSI0_config_destinationTerminal = append('/',app.card_1_name,'/RTSI0');     
            app.RTSI0_config_signalModifiers = int32(app.DAQmx_Val_DoNotInvertPolarity);  
            
            % resetting the device sometimes doesn't disconnect the terminals so this
            % just makes sure everything is disconnected before you connect
            [err_code] = daq.ni.NIDAQmx.DAQmxDisconnectTerms(app.RTSI0_config_sourceTerminal, ...
                                                                 app.RTSI0_config_destinationTerminal);
            
            % then this connects them
            [err_code] = daq.ni.NIDAQmx.DAQmxConnectTerms(app.RTSI0_config_sourceTerminal, ...
                                                                 app.RTSI0_config_destinationTerminal, ...
                                                                 app.RTSI0_config_signalModifiers );
            disp(num2str(err_code));
            
            % Attach ai start trigger of first card to RTSI0 (which is also connected
            % to RTSI0 on other card)
            disp( '### Connect RTSI0 on card 1 to /ai/StartTrigger' );
            app.RTSI0_config_sourceTerminal = append('/',app.card_2_name,'/ai/StartTrigger');    
            app.RTSI0_config_destinationTerminal = append('/',app.card_2_name,'/RTSI0')
            
            % resetting the device sometimes doesn't disconnect the terminals so this
            % just makes sure everything is disconnected before you connect
            [err_code] = daq.ni.NIDAQmx.DAQmxDisconnectTerms(app.RTSI0_config_sourceTerminal, ...
                                                                 app.RTSI0_config_destinationTerminal);
            
            % then this connects them
            app.RTSI0_config_signalModifiers = int32(app.DAQmx_Val_DoNotInvertPolarity);         
            [err_code] = daq.ni.NIDAQmx.DAQmxConnectTerms(app.RTSI0_config_sourceTerminal, ...
                                                                 app.RTSI0_config_destinationTerminal, ...
                                                                 app.RTSI0_config_signalModifiers );
            disp(num2str(err_code))
        end

        function initialize_digital_outs(app)
            % Create digital output clocked by the internal clock triggered by ai - https://documentation.help/NI-DAQmx-C-Functions/DAQmxCreateDOChan.html
                        
            % Create digital output task
            [err_code, th_digout] = daq.ni.NIDAQmx.DAQmxCreateTask( char(0), uint64(0) ); % Create task
            app.task_handle_digout = uint64(th_digout);
            disp( ['### Creating digital output ###' '(' num2str( app.task_handle_digout ) ')']);
            
            
            % Create digital output channel
            app.digout_config_Lines = app.dig_locations;
            app.digout_config_NamesofLines = char(0);
            app.digout_config_LineGrouping  = int32(app.DAQmx_Val_ChanPerLine);           % Define units as Hertz
            [err_code] = daq.ni.NIDAQmx.DAQmxCreateDOChan( app.task_handle_digout, ...
                                                                  app.digout_config_Lines, ...
                                                                  app.digout_config_NamesofLines, ...
                                                                  app.digout_config_LineGrouping );
            if err_code ~=0
                disp('dig output create chan err =')
                disp(num2str(err_code));
            end     

            % this code sets the ref clock for card 2 & digout
            [err_code, app.clk_used_daqcard2dig] = daq.ni.NIDAQmx.DAQmxSetRefClkSrc(app.task_handle_digout,char("PXIe_Clk100"));
            if err_code ~=0
                disp('set ref clk for digout, clk & err =')
                disp(app.clk_used_daqcard2dig)
                disp(num2str(err_code));
            end
            [err_code] = daq.ni.NIDAQmx.DAQmxSetRefClkRate(app.task_handle_digout,100000000.0);                                         % assign ref freq to clk freq
            [err_code, app.clk_used_daqcard2dig_confirm] = daq.ni.NIDAQmx.DAQmxGetRefClkSrc(app.task_handle_digout,char("NULL"),uint32(23));% confirm ref clk is right
            if err_code ~=0
                disp('get ref clk for digout, clk & err =')
                disp(app.clk_used_daqcard2dig)
                disp(num2str(err_code));
            end

            disp(append('Clk used for ref =',app.clk_used_daqcard2dig_confirm))
            

            % set regen mode
            [err_code] = daq.ni.NIDAQmx.DAQmxSetWriteRegenMode( app.task_handle_digout, int32(app.DAQmx_Val_AllowRegen));
            
            % Set data transfer method
            [err_code] = daq.ni.NIDAQmx.DAQmxSetDODataXferMech( app.task_handle_digout, app.digout_config_NamesofLines, int32(app.DAQmx_Val_DMA));
                        
            % Configures output buffer
            [err_code] = daq.ni.NIDAQmx.DAQmxCfgOutputBuffer(app.task_handle_digout,uint32(app.samples_for_buffer));
            if err_code ~=0
                disp('buff config error =');
                disp(num2str(err_code));
            end
            
            [err_code] = daq.ni.NIDAQmx.DAQmxSetDODataXferReqCond(app.task_handle_digout, app.digout_config_NamesofLines, int32(app.DAQmx_Val_OnBrdMemNotFull));
            
            if err_code ~=0
                disp('DO transfer req cond');
                disp(num2str(err_code));
            end           
         
            
            % Configure timing for digital output channel - https://www.ni.com/docs/en-US/bundle/ni-daqmx-c-api-ref/page/daqmxcfunc/daqmxcfgsampclktiming.html
            disp( ['### Configuring Channel ###' '(' num2str( app.task_handle_digout ) ')'] );
            app.digout_config_SampleRate          = double(app.digital_data_rate);          % Defines sample rate (has to match clock rate for this terminal)
            app.digout_config_ClockSourceTerminal = 'OnboardClock';                         % Assigns internal clock to be the clock (synced with PXIe_100 MHz clk)
            app.digout_config_ActiveEdge          = int32(app.DAQmx_Val_Rising);            % Defines rising edge of clock to sample on
            app.digout_config_SampleMode          = int32(app.DAQmx_Val_ContSamps);         % Defines continuous output
            app.digout_config_SamplesToGenerate   = uint64( app.samples_for_buffer );       % Defines how many samples generate for buffer size
            [err_code] = daq.ni.NIDAQmx.DAQmxCfgSampClkTiming( app.task_handle_digout, ...
                                                               app.digout_config_ClockSourceTerminal, ...
                                                               app.digout_config_SampleRate,          ...
                                                               app.digout_config_ActiveEdge,          ...
                                                               app.digout_config_SampleMode,          ...
                                                               app.digout_config_SamplesToGenerate );
            
            if app.record_case == 1            
                % make clock alternating samples
                app.digital_data_out_CLK = zeros(1,app.samples_for_buffer);    
                for i = 1:length(app.digital_data_out_CLK)
                    if ~mod(i,2)
                        app.digital_data_out_CLK(i) = 1;
                    end
                end
                    
                app.digital_data_out_DRESET = ones(1,app.samples_for_buffer);       % Generates Dreset to zeros (will add data later in loop)
                app.digital_data_out_enableD = zeros(1,app.samples_for_buffer);     % Generate array of zeros to enablelevel shifter to be on (on test board)
                app.digital_data_out_digOn = ones(1,app.samples_for_buffer);        % Generate array of ones to enablelevel stim daq to be enabled
                
                % Remove CLK & add DRESET once every 32 cycles, period = 2 samples - 01 
                for i = 1:64:app.samples_for_buffer
                    app.digital_data_out_CLK(i+1) = 0;
                    app.digital_data_out_DRESET(i+1) = 0;                         % DRESET is inverted so 0 is high
                end
            
            elseif app.record_case == 2
                app.digital_data_out_CLK = zeros(1,app.samples_for_buffer);          % write clock low, set to record from ch1
                app.digital_data_out_DRESET = zeros(1,app.samples_for_buffer);       % write dreset low, set to record from ch1
                app.digital_data_out_enableD = zeros(1,app.samples_for_buffer);      % Generate array of zeros to enablelevel shifter to be on (on test board)
                app.digital_data_out_digOn = ones(1,app.samples_for_buffer);         % Generate array of ones to enablelevel stim daq to be enabled
            end
            
            % Controls HPF behaviour
            if app.HPF_status == 1
                app.digital_data_out_HPFRESET = zeros(1,app.samples_for_buffer);      % write HPFrest to be zero which keeps the switch on
            elseif app.HPF_status == 2
                app.digital_data_out_HPFRESET = ones(1,app.samples_for_buffer);      % write HPFrest to be one which keeps the switch off
            elseif app.HPF_status == 3
                app.digital_data_out_HPFRESET = ones(1,app.samples_for_buffer);      % write HPFrest to be zero which keeps the switch on then alternate
                for i = 1:app.n_hpf_period:app.samples_for_buffer
                    app.digital_data_out_HPFRESET(i:i+app.n_hpf_duration) = zeros(1,length(i:i+app.n_hpf_duration));
                end
            end            
            
            
            % append data
            app.digital_data_out_total = [app.digital_data_out_CLK,app.digital_data_out_DRESET,app.digital_data_out_HPFRESET,app.digital_data_out_enableD,app.digital_data_out_digOn];
            
            
            disp(num2str(err_code))
            % Look to RTSI0 aka aitrigger from other card for trigger;     
            app.digout_config_TriggerSource = 'RTSI0';     % Define sample mode to be continuous
            app.digout_config_TriggerEdge = int32(app.DAQmx_Val_Rising);          % Defines buffer size
            [err_code] = daq.ni.NIDAQmx.DAQmxCfgDigEdgeStartTrig( app.task_handle_digout, ...
                                                                  app.digout_config_TriggerSource, ...
                                                                  app.digout_config_TriggerEdge );
            
            % Create digital output data - https://www.ni.com/docs/en-US/bundle/ni-daqmx-c-api-ref/page/daqmxcfunc/daqmxwritedigitallines.html
            disp( ['### Writing digital data Channel ###' '(' num2str( app.task_handle_digout ) ')'] );
            app.digout_config_Nsamplesperchan     = int32(app.samples_for_buffer);          % Defines n samples per channel
            app.digout_config_AutoStart           = uint32(0);                          % Assigns 0 to autostart (so it won't autostart)
            app.digout_config_Timeout             = double(0);                          % Defines -1 so that it never times out
            app.digout_config_DataLayout          = uint32(app.DAQmx_Val_GroupByChannel);   % Defines how data is put into write - https://www.ni.com/docs/en-US/bundle/ni-daqmx/page/mxcncpts/interleaving.html
            app.digout_config_WriteArray          = uint8(app.digital_data_out_total);      % Defines how many samples generate for buffer size
            app.digout_config_Reserved            = uint32(0);                          % idk, "Reserved for future use. Pass NULL to this parameter."
            [err_code, data_out, suh] = daq.ni.NIDAQmx.DAQmxWriteDigitalLines( app.task_handle_digout, ...
                                                               app.digout_config_Nsamplesperchan, ...
                                                               app.digout_config_AutoStart,          ...
                                                               app.digout_config_Timeout,          ...
                                                               app.digout_config_DataLayout,          ...
                                                               app.digout_config_WriteArray, ...
                                                               int32([0]),app.digout_config_Reserved);
            disp(num2str(err_code));

            %Visualize digital outputs
            figure(100)
            subplot(4,1,1)
            plot(app.digital_data_out_CLK)
            xlim([1 200])
            title('1.Clock output')
            xlabel('Sample Number')
            ylabel('value')
            
            subplot(4,1,2)
            plot(app.digital_data_out_DRESET)
            xlim([1 200])
            title('2.Dreset')
            xlabel('Sample Number')
            ylabel('value')
            
            subplot(4,1,3)
            plot(app.digital_data_out_HPFRESET)
            xlim([1 25000])
            title('3.HPFreset')
            xlabel('Sample Number')
            ylabel('value')
            
            subplot(4,1,4)
            hold on
            plot(app.digital_data_out_enableD)
            plot(app.digital_data_out_digOn,'bo')
            xlim([1 200])
            ylim([0 1.25])
            title('4.Enable lvl shifter and enable dig power')
            xlabel('Sample Number')
            ylabel('value')
            legend('Level Shifter Enable','Enable Dig Power')
        end

        function initialize_analog_ins(app)
            % Create analog input task for card 1
            disp( '### Creating analog 1 Task ###' );
            th_ai = uint64(0);
            [err_code, th_ai] = daq.ni.NIDAQmx.DAQmxCreateTask( char(0), uint64(0) );
            app.task_handle_ai1    = uint64(th_ai);
            
            % Configure the task as AI
            disp( ['### Creating AI Channel ### voltage range =' '(' num2str( app.task_handle_ai1 ) ')']);
            disp(app.RangeDropDown.Value)              

            
            % Add an analog input channel for testing (you can only add outputs from 1
            % card to each task, thus I'm creating different tasks)
            app.ai_config_PhysicalChannelcard1 = app.card_1_analogins;
            app.ai_config_ChannelName     = char(0);
            app.ai_config_TerminalConfig  = int32(app.DAQmx_Val_Diff);
            app.ai_config_MinValue        = double(app.RangeDropDown.Value(1)); % change range of analog input
            app.ai_config_MaxValue        = double(app.RangeDropDown.Value(2));
            app.ai_config_Units           = int32(app.DAQmx_Val_Volts);
            app.ai_config_CustomScaleName = char(0);
            [err_code] = daq.ni.NIDAQmx.DAQmxCreateAIVoltageChan( app.task_handle_ai1, ...
                                                                  app.ai_config_PhysicalChannelcard1, ...
                                                                  app.ai_config_ChannelName,     ...
                                                                  app.ai_config_TerminalConfig,  ...
                                                                  app.ai_config_MinValue,        ...
                                                                  app.ai_config_MaxValue,        ...
                                                                  app.ai_config_Units,           ...
                                                                  app.ai_config_CustomScaleName );

            % this code sets the ref clock for card 1 (ai task is on card 2) - https://documentation.help/NI-DAQmx-C-Properties/Func1316.html
            % Set reference clocks for tasks - https://forums.ni.com/t5/PXI/How-can-I-guarentee-my-two-PXIe-6396-cards-are-using-PXIe-CLK100/m-p/4388182
            [err_code, app.clk_used_daqcard1] = daq.ni.NIDAQmx.DAQmxSetRefClkSrc(app.task_handle_ai1,char("PXIe_Clk100"));
            if err_code ~=0
                disp('set ref clk for ai1, clk & err =')
                disp(app.clk_used_daqcard1)
                disp(num2str(err_code));
            end
            [err_code] = daq.ni.NIDAQmx.DAQmxSetRefClkRate(app.task_handle_ai1,100000000.0);
            [err_code, app.clk_used_daqcard1_confirm] = daq.ni.NIDAQmx.DAQmxGetRefClkSrc(app.task_handle_ai1,char("NULL"),uint32(23));
            if err_code ~=0
                disp('get ref clk for ai1, clk & err =')
                disp(app.clk_used_daqcard1_confirm)
                disp(num2str(err_code));
            end              

            %%Verify analog input task
            disp( ['### Veryfing Task - AI card 1 ###' '(' num2str( app.task_handle_ai1 ) ')'] );
            [err_code] = daq.ni.NIDAQmx.DAQmxTaskControl( app.task_handle_ai1, ...
                                                          int32(app.DAQmx_Val_Task_Verify) );
            if err_code ~=0
                disp('AI card 1 task verification error = ')
                disp(num2str(err_code));
            end 

            %%Configure analog input channel sampling rate
            disp( ['### Configuring Channels AI1 ###' '(' num2str( app.task_handle_ai1 ) ')'] );
            app.ai_config_SampleRate          = double( app.ai_sample_rate );                   % Defines sample rate (has to match clock rate for this terminal)
            app.ai_config_ClockSourceTerminal = 'OnboardClock';                                 % Assigns Onboard clock to be the source
            app.ai_config_ActiveEdge          = int32(app.DAQmx_Val_Rising);                    % Defines rising edge of clock to sample on
            app.ai_config_SampleMode          = int32(app.DAQmx_Val_ContSamps);                 % Defines finite n samples mode
            app.ai_config_SamplesToAcquire    = uint64( app.buffer_size_plot );                 % Defines how many samples to acquire
            [err_code] = daq.ni.NIDAQmx.DAQmxCfgSampClkTiming( app.task_handle_ai1, ...
                                                               app.ai_config_ClockSourceTerminal, ...
                                                               app.ai_config_SampleRate,          ...
                                                               app.ai_config_ActiveEdge,          ...
                                                               app.ai_config_SampleMode,          ...                                                   
                                                               app.ai_config_SamplesToAcquire );
            if err_code ~=0
                disp('analog input config timing card 1 error code =')
                disp(num2str(err_code));
            end 

            % trigger to trigger analog input - https://www.ni.com/docs/en-US/bundle/ni-daqmx-c-api-ref/page/daqmxcfunc/daqmxcfgdigedgestarttrig.html
            app.ai_config_TriggerSource = 'RTSI0';     % trigger source for AI in card 1 = RTSI0 (which should be connected to ai/startrigger of card 2 from earlier section 
            app.ai_config_TriggerEdge = int32(app.DAQmx_Val_Rising);          % Defines buffer size
            [err_code] = daq.ni.NIDAQmx.DAQmxCfgDigEdgeStartTrig( app.task_handle_ai1, ...
                                                                  app.ai_config_TriggerSource, ...
                                                                  app.ai_config_TriggerEdge );
            if err_code ~=0
                disp('analog trigger error code =')
                disp(num2str(err_code));
            end          

            % Create analog input task for card 2
            
            disp( '### Creating analog 2 Task ###' );
            th_ai2 = uint64(0);
            [err_code, th_ai2] = daq.ni.NIDAQmx.DAQmxCreateTask( char(0), uint64(0) );
            app.task_handle_ai2    = uint64(th_ai2);                        
            
            % Add 8 analog input channels (you can only add outputs from 1
            % card to each task, thus I'm creating different tasks)
            app.ai_config_PhysicalChannelcard2 = app.card_2_analogins;
            [err_code] = daq.ni.NIDAQmx.DAQmxCreateAIVoltageChan( app.task_handle_ai2, ...
                                                                  app.ai_config_PhysicalChannelcard2, ...
                                                                  app.ai_config_ChannelName,     ...
                                                                  app.ai_config_TerminalConfig,  ...
                                                                  app.ai_config_MinValue,        ...
                                                                  app.ai_config_MaxValue,        ...
                                                                  app.ai_config_Units,           ...
                                                                  app.ai_config_CustomScaleName );


            % this code sets the ref clock for card 2 
            [err_code, app.clk_used_daqcard2] = daq.ni.NIDAQmx.DAQmxSetRefClkSrc(app.task_handle_ai2,char("PXIe_Clk100"));            
            if err_code ~=0
                disp('set ref clk for ai2, clk & err =')
                disp(char(app.clk_used_daqcard2))
                disp(num2str(err_code));
            end
            [err_code] = daq.ni.NIDAQmx.DAQmxSetRefClkRate(app.task_handle_ai2,100000000.0);                                            % assign ref freq to clk freq
            [err_code, app.clk_used_daqcard2_confirm] = daq.ni.NIDAQmx.DAQmxGetRefClkSrc(app.task_handle_ai2,char("NULL"),uint32(23));   % confirm ref clk is right            
            if err_code ~=0
                disp('get ref clk for ai2, clk & err =')
                disp(char(app.clk_used_daqcard2_confirm))
                disp(num2str(err_code));
            end



            %%Verify analog input task - card 2
            disp( ['### Veryfing Task - AI card 2 ###' '(' num2str( app.task_handle_ai2 ) ')'] );
            [err_code] = daq.ni.NIDAQmx.DAQmxTaskControl( app.task_handle_ai2, ...
                                                          int32(app.DAQmx_Val_Task_Verify) );
            if err_code ~=0
                disp('AI card 2 verification error = ')
                disp(num2str(err_code));
            end
            
                      
            %%Configure analog input channel sampling rate
            disp( ['### Configuring Card 2 analog input###' '(' num2str( app.task_handle_ai2 ) ')'] );
            [err_code] = daq.ni.NIDAQmx.DAQmxCfgSampClkTiming( app.task_handle_ai2, ...
                                                               app.ai_config_ClockSourceTerminal, ...
                                                               app.ai_config_SampleRate,          ...
                                                               app.ai_config_ActiveEdge,          ...
                                                               app.ai_config_SampleMode,          ...                                                   
                                                               app.ai_config_SamplesToAcquire );
        
            % values for analog recording read function
            app.ai_config_NumSamplesPerChannel = int32(-1);         % Read all available samples
            app.ai_config_Timeout              = double(-1);        % amount of time to wait for real before timing out (-1 for wa it forever) 
            app.ai_config_FillMode             = uint32(app.DAQmx_Val_GroupByChannel);
            app.ai_config_BufferSize           = uint32(app.buffer_size_plot);
            app.ai_config_DataCard1            = double(zeros(app.ai_config_BufferSize, 1 ));
            app.ai_config_DataCard2            = double(zeros(app.ai_config_BufferSize, 1 ));
            app.ai_config_SampsPerChanRead     = int32(0);
            app.ai_config_ReservedBuffer       = uint32(0);
        end

        function initialize_analog_out(app)
            % Create analog output task
            [err_code, th_analogout] = daq.ni.NIDAQmx.DAQmxCreateTask( char(0), uint64(0) ); % Create task
            app.task_handle_analogout = uint64(th_analogout);
            disp( ['### Creating analog output ###' '(' num2str( th_analogout ) ')']);

            app.analogout_samples_tomakeperch = length(app.analog_data_out_total);
            app.analogout_samples_for_buffer = length(app.analog_data_out_total_ch);                      
            
            % Create analog output channel
            app.analogout_config_physicalChannel = append(app.analog_output_address, ',', app.analog_output_address2);
            app.analogout_config_nameToAssignToChannel = char(0);
            app.analogout_config_minVal = double(-5);
            app.analogout_config_maxVal = double(5);
            app.analogout_config_units = int32(app.DAQmx_Val_Volts);
            app.analogout_config_customScaleName = char(0); % must be null 
            [err_code] = daq.ni.NIDAQmx.DAQmxCreateAOVoltageChan( app.task_handle_analogout, ...
                                                                  app.analogout_config_physicalChannel, ...
                                                                  app.analogout_config_nameToAssignToChannel, ...
                                                                  app.analogout_config_minVal, ...
                                                                  app.analogout_config_maxVal, ...
                                                                  app.analogout_config_units, ...
                                                                  app.analogout_config_customScaleName);
            disp(num2str(err_code));
            
            % % trigger to trigger analog output - https://www.ni.com/docs/en-US/bundle/ni-daqmx-c-api-ref/page/daqmxcfunc/daqmxcfgdigedgestarttrig.html
            app.analogout_config_TriggerSource = 'RTSI0';     % Define sample mode to be continuous
            app.analogout_config_TriggerEdge = int32(app.DAQmx_Val_Rising);          % Defines buffer size
            [err_code] = daq.ni.NIDAQmx.DAQmxCfgDigEdgeStartTrig( app.task_handle_analogout, ...
                                                                  app.analogout_config_TriggerSource, ...
                                                                  app.analogout_config_TriggerEdge );
            
            if err_code ~=0
                disp('analog out trigger error code =')
                disp(num2str(err_code));
            end

            % set refclk to PXIe_Clk100 (need to do this for every task regardless of card)
            [err_code, app.clk_used_daqcard2ao] = daq.ni.NIDAQmx.DAQmxSetRefClkSrc(app.task_handle_analogout,char("PXIe_Clk100"));
            if err_code ~=0
                disp('set ref clk for analogout, clk & err =')
                disp(app.clk_used_daqcard2ao)
                disp(num2str(err_code));
            end
            [err_code] = daq.ni.NIDAQmx.DAQmxSetRefClkRate(app.task_handle_analogout,100000000.0);                                              % assign ref freq to clk freq
            [err_code, app.clk_used_daqcard2ao_confirm] = daq.ni.NIDAQmx.DAQmxGetRefClkSrc(app.task_handle_analogout,char("NULL"),uint32(23));    % confirm ref clk is right
            if err_code ~=0
                disp('get ref clk for analogout, clk & err =')
                disp(app.clk_used_daqcard2ao_confirm)
                disp(num2str(err_code));
            end        
            
            %%Configure analog output channel sampling rate - https://www.ni.com/docs/en-US/bundle/ni-daqmx-c-api-ref/page/daqmxcfunc/daqmxcfgsampclktiming.html
            app.analogout_config_SampleRate          = double( app.ai_sample_rate );        % Defines sample rate (has to match clock rate for this terminal)
            app.analogout_config_ClockSourceTerminal = 'OnboardClock';                      % Assigns Onboard clock to be the source
            app.analogout_config_ActiveEdge          = int32(app.DAQmx_Val_Rising);         % Defines rising edge of clock to sample on
            app.analogout_config_SampleMode          = int32(app.DAQmx_Val_FiniteSamps);    % Defines finite n samples mode
            app.analogout_config_SamplesToAcquire    = uint64( app.analogout_samples_for_buffer );                % Defines how many samples to generate
            
            disp( ['### Configuring analog output ###' '(' num2str( app.task_handle_analogout ) ')'] );
            [err_code] = daq.ni.NIDAQmx.DAQmxCfgSampClkTiming( app.task_handle_analogout, ...
                                                               app.analogout_config_ClockSourceTerminal, ...
                                                               app.analogout_config_SampleRate,          ...
                                                               app.analogout_config_ActiveEdge,          ...
                                                               app.analogout_config_SampleMode,          ...                                                   
                                                               app.analogout_config_SamplesToAcquire );
                                          
            % Create analog output data - https://www.ni.com/docs/en-US/bundle/ni-daqmx-c-api-ref/page/daqmxcfunc/daqmxwriteanalogf64.html
            disp( ['### Writing analog output data Channel ###' '(' num2str( app.task_handle_analogout ) ')'] );
            app.analogout_config_Nsamplesperchan     = int32(app.analogout_samples_tomakeperch);           % Defines n samples per channel
            app.analogout_config_AutoStart           = uint32(0);                               % Assigns 0 to autostart (so it won't autostart)
            app.analogout_config_Timeout             = double(0);                               % Defines -1 so that it never times out
            app.analogout_config_DataLayout          = uint32(app.DAQmx_Val_GroupByChannel);    % Defines how data is put into write - https://www.ni.com/docs/en-US/bundle/ni-daqmx/page/mxcncpts/interleaving.html
            app.analogout_config_WriteArray          = double(app.analog_data_out_total_ch);       % Defines data output
            app.analogout_config_Reserved            = uint32(0);                               % idk, "Reserved for future use. Pass NULL to this parameter."
            [err_code, data_out_analog, idk] = daq.ni.NIDAQmx.DAQmxWriteAnalogF64( app.task_handle_analogout, ...
                                                               app.analogout_config_Nsamplesperchan, ...
                                                               app.analogout_config_AutoStart,          ...
                                                               app.analogout_config_Timeout,          ...
                                                               app.analogout_config_DataLayout,          ...
                                                               app.analogout_config_WriteArray, ...
                                                               int32([0]),app.analogout_config_Reserved);
            disp(err_code)
        end

        function record_data(app)
            % This function runs the actual acquisition of data. First sets
            % up all of the tasks, then they are started when we start
            % analog input of card 2 (because of backplane triggers). This
            % then starts a loop to read data as long as the number of
            % samples is less than sampling rate*record time. Within the
            % loop, it plots chunks of the data as it's being recorded in
            % windows of buffer_plot_time. It reads data from the buffer
            % every loop and writes that data to a file if data logging is
            % on. Then, once it collects all samples, it closes the write
            % file, and stops all tasks.

            % arm digitals & card 2
            [err_code] = daq.ni.NIDAQmx.DAQmxStartTask( app.task_handle_ai1 );
            if err_code ~= 0
                disp('start AI 1 task error code =')
                disp(num2str(err_code))
            end
            [err_code] = daq.ni.NIDAQmx.DAQmxStartTask( app.task_handle_digout );
            if err_code ~= 0
                disp('start DO task error code =')
                disp(num2str(err_code))
            end

            % arm analog out task 
            if strcmp(app.AnalogoutputDropDown.Value,'Off') == false
                [err_code] = daq.ni.NIDAQmx.DAQmxStartTask( app.task_handle_analogout );
            end           
            if err_code ~= 0
                disp('start AO task error code =')
                disp(num2str(err_code))
            end
            
            % start recording (this sends out ai start trigger to RTSI0)
            disp( ['### start recording ###' '(' num2str( app.task_handle_ai2 ) ')']);
            [err_code] = daq.ni.NIDAQmx.DAQmxStartTask( app.task_handle_ai2 );        
            if err_code ~= 0
                disp('start analog card in error code =')
                disp(num2str(err_code))
            end   

            disp('Channel to plot is = ')
            disp(num2str(app.channel_to_plot))           
            
            % variables for loop
            total_num_samps_to_read = app.time_record*app.ai_config_SampleRate;
            samps_read = 0;
            samps_read2 = 0;
            num_errors = 0;
            samps_total_card1 = [];
            samps_total_card2 = [];
            app.time_vec_total = [];

            app.buffer_plot_time = app.TimewindowEditField.Value;
            samples_to_plot = app.buffer_plot_time*app.ai_config_SampleRate;
            app.time_vec = 1/double(app.ai_config_SampleRate):1/double(app.ai_config_SampleRate):double(app.buffer_plot_time); % time vector for plotting
            n = 1;
            plot_indicies = 1:samples_to_plot:total_num_samps_to_read+samples_to_plot; % make total time + 1 indicies (don't use last one, just use it for index loop)

            while samps_read < total_num_samps_to_read && app.is_stopbuttonpushed == false && num_errors < 20
                % read data for card 1
                [err_code,                   ...
                 app.ai_config_DataCard1,             ...
                 app.ai_config_SampsPerChanReadcard1, ...
                 app.ai_config_ReservedBuffer] = ...
                    daq.ni.NIDAQmx.DAQmxReadAnalogF64( app.task_handle_ai1, ...
                                                       app.ai_config_NumSamplesPerChannel, ...
                                                       app.ai_config_Timeout,              ...
                                                       app.ai_config_FillMode,             ...
                                                       app.ai_config_DataCard1,            ...
                                                       app.ai_config_BufferSize,           ...
                                                       app.ai_config_SampsPerChanRead,     ...
                                                       app.ai_config_ReservedBuffer );

                samps_read = samps_read + app.ai_config_SampsPerChanReadcard1;

                % Channel data is mapped serially; we read all chanenls so
                % need to extract the one to be plotted based on the one
                % selected in the GUI. "app.channel_to_plot" is
                % the analog channel ranging from 1 - 8.

                analog_ch_ID = app.channel_to_plot;
                n_analog_ins = 8;
                data_card1_read = app.ai_config_DataCard1(1:app.ai_config_SampsPerChanReadcard1*n_analog_ins);
                data_card1_reshaped = reshape(data_card1_read,[app.ai_config_SampsPerChanReadcard1,n_analog_ins])';
                %disp(size(data_card1_reshaped))
                data_out1 = data_card1_reshaped(analog_ch_ID,:);
                samps_total_card1 = [samps_total_card1, data_out1];

                if err_code ~= 0
                    disp('Read analog card 1 error code =')
                    disp(num2str(err_code))
                    num_errors = num_errors +1;
                end   

                % Read data for card 2 
                [err_code,                   ...
                 app.ai_config_DataCard2,             ...
                 app.ai_config_SampsPerChanReadcard2, ...
                 app.ai_config_ReservedBuffer] = ...
                    daq.ni.NIDAQmx.DAQmxReadAnalogF64( app.task_handle_ai2, ...
                                                       app.ai_config_NumSamplesPerChannel, ...
                                                       app.ai_config_Timeout,              ...
                                                       app.ai_config_FillMode,             ...
                                                       app.ai_config_DataCard2,            ...
                                                       app.ai_config_BufferSize,           ...
                                                       app.ai_config_SampsPerChanRead,     ...
                                                       app.ai_config_ReservedBuffer );
                if err_code ~= 0
                    disp('Read analog card 2 error code =')
                    disp(num2str(err_code))
                    num_errors = num_errors +1;
                end   

                samps_read2 = samps_read2 + app.ai_config_SampsPerChanReadcard2;
                data_card2_read = app.ai_config_DataCard2(1:app.ai_config_SampsPerChanReadcard2*n_analog_ins);
                data_card2_reshaped = reshape(data_card2_read,[app.ai_config_SampsPerChanReadcard2,n_analog_ins])';
                %disp(size(data_card2_reshaped))
                data_out2 = data_card2_reshaped(analog_ch_ID,:);
                samps_total_card2 = [samps_total_card2, data_out2];

                pause(0.01) % need this pause to allow stop button to be pushed to register

                % write data to file if log is on. Choose which card analog
                % recording channel is on then write it. 
                if app.LogDataOut == true
                    if app.DeviceDropDown.Value == 2
                        card_data_out = data_out1;
                    elseif app.DeviceDropDown.Value == 3
                        card_data_out = data_out2;
                    end
                    fprintf(app.fid_analogdata, '%d\n', card_data_out); 
                end               
                             
                % if the difference in samples read between cards is > 0.1%
                % report values as warning
                if abs(samps_read - samps_read2)/samps_read2 > 0.01
                    warning('Sampling warning; samps read card 1, samps read card 2 = ')
                    disp(num2str(samps_read))
                    disp(num2str(samps_read2))
                    num_errors = num_errors + 1;
                end

                %try
                    % plot data if it's been the amount of samples (based on
                    % sample rate and time to plot)
                    
                if length(samps_total_card1) > plot_indicies(n+1)    

                    % disp('Samps read card 1, samps read card 2 = ')
                    % disp(num2str(samps_read))
                    % disp(num2str(samps_read2))                        
                    old_ind = plot_indicies(n);
                    new_ind = plot_indicies(n+1)-1;

                    % plot data from card 1 or card 2
                    if app.DeviceDropDown.Value == 2
                        %disp(size(samps_total_card1))
                        plot(app.LiveAxes, app.time_vec, samps_total_card1(old_ind:new_ind))
                        %figure(87)
                        %plot(app.time_vec, samps_total_card1(old_ind:new_ind))
                    elseif app.DeviceDropDown.Value == 3
                        %disp(size(samps_total_card2))
                        plot(app.LiveAxes, app.time_vec, samps_total_card2(old_ind:new_ind))
                    end
                    xlim(app.LiveAxes,[0 app.xlimEditField.Value])%app.buffer_plot_time])
                    app.time_vec_total = [app.time_vec_total, app.time_vec + (n-1)];

                    % plot muxed if mux is selected
                    if app.DeMUXplotCheckBox.Value == 1                            
                        old_ind_shift = old_ind + app.DeMUXshiftEditField.Value + app.dig_samps_per_analog; % shift by one digital sample (starts off) 
                        figure(7)
                        tiledlayout(4,8)                               
                        [time_vals_demuxed, sorted_data] = demux(app.time_vec, samps_total_card1(old_ind_shift:new_ind), app.num_ch, app.ai_sample_rate, app.muxrate);
                        
                        % disp('demux sizes')
                        % disp(size(time_vals_demuxed))
                        % disp(size(sorted_data))

                        if app.HPFdriftremoveCheckBox.Value == 1
                            [time_cor, demux_cor] = remove_drift(time_vals_demuxed, sorted_data, app.avg_ch_reset_shape, app.avg_env_inv, app.samps_to_cut_st, app.samps_to_cut_end, 1, app.gaincorrect_option);
                            disp(size(time_cor))
                            disp(size(demux_cor))
                        end
                        
                        % plot demuxed, corrected, filtered data
                        n_samps_plot = round((app.muxrate/32)*app.xlimEditField.Value);
                        
                        for i = 1:32
                            nexttile
                            time_vals_out = time_vals_demuxed(i,:);
                            data_demuxed = sorted_data(i,:);        

                            if app.HPFdriftremoveCheckBox.Value == 1
                                hold on
                                
                                if app.FilterCheckBox.Value == 1 % if bandpass selected, then bandpass
                                   bandpass_data = filtfilt(app.filt_b,app.filt_a,demux_cor(i,:));
                                   plot(time_cor(i,:),bandpass_data,'r')
                                else % if not, just plot calibrated demuxed data w/o filtering
                                    plot(time_cor(i,:),demux_cor(i,:),'r')
                                end                                                         
                            end                                
                            plot(time_vals_out(1:n_samps_plot),data_demuxed(1:n_samps_plot))
                            %xlabel('Time (s)')
                            %ylabel('Voltage (V)')
                            %title(append('Ch = ',num2str(i)))
                            %xlim([0 app.xlimEditField.Value])
                        end
                        pause(0.0001)
                        
                    end
                    n = n + 1
                end
                    
                % catch
                %     warning('End of cycle most likely; samps read card 1, samps read card 2 = ')
                %     disp(num2str(samps_read))
                %     disp(num2str(samps_read2))
                %     num_errors = num_errors + 1;
                % end                

            end

            %figure(6)
            %hold on
            %plot(samps_total_card1,'ro')
            disp('Num errors = ')
            disp(num2str(num_errors))
            disp('Samps read, total samps to read = ')
            disp(num2str(samps_read))
            disp(num2str(total_num_samps_to_read))

            % if Calibration is on and it's the first calibration then run
            % calibration based on the data and enable other options
            if strcmp(app.CalibrationDropDown.Value,'On') == true && app.iscalibrated == 0
                % run calibration function
                app.samps_total_card1 = samps_total_card1;
                run_calibration(app)

                % store calibration data to seperate variable
                app.analog_calib_data = samps_total_card1;
                                
                % enable options now that calibration happened
                app.HPFdriftremoveCheckBox.Enable = 'on';
                app.GaincorrectCheckBox.Enable = 'on';
                app.FilterCheckBox.Enable = 'on';
                app.HPF3dBEditField.Enable = 'on';
                app.HPF3dBEditFieldLabel.Enable = 'on';
                app.LPF3dBEditField.Enable = 'on';
                app.LPF3dBEditFieldLabel.Enable = 'on';
                app.iscalibrated = 1;
            end

            % if data logging is on, close the file that was written for
            % analog data
            if app.LogDataOut == true
                fclose(app.fid_analogdata);    
            end     

            %stop tasks
            [err_code] = daq.ni.NIDAQmx.DAQmxStopTask( app.task_handle_ai1 );
            [err_code] = daq.ni.NIDAQmx.DAQmxStopTask( app.task_handle_ai2 );
            [err_code] = daq.ni.NIDAQmx.DAQmxStopTask( app.task_handle_digout );

            % stop analog out if it's there
            if strcmp(app.AnalogoutputDropDown.Value,'Off') == false
                [err_code] = daq.ni.NIDAQmx.DAQmxStopTask( app.task_handle_analogout );
                if err_code ~= 0
                    disp('Analog out stop err code')                
                    disp(err_code)
                end
            end
            StopButtonPushed(app)
        end

        function write_data_to_file(app)
            % Writes 3 or 4 files (date/time + title) depending on task
            % 1. first one is the tone order if it was tones
            % 2. second one is the raw analog output time/data
            % 3. third one is the digital pattern used (first 3200 samples)
            % 4. fourth one is recording metadata
            % 5. fifth file is a log of the command window (anything disp
            % prints to).
            % 6. sixth file is the raw analog output to the speaker and the
            % on/off signal if analog out is selected to be on
            % (downsampled by OSF and num ch)
            % 7. Seventh file is the raw calibration output data if option
            % is selected

            % get date/time for directory name
            format longG
            t = now;
            d = datetime(t,'ConvertFrom','datenum');
            d_str = datestr(d);
            d_str_min = strrep(d_str,':','_');
            d_str_cor = strrep(d_str_min,'-','_');
            d_str_cor = strrep(d_str_cor,' ','_');
            
            % make directory                        
            data_path = append(app.data_out_directory,'\',d_str_cor,'_',app.FiletextaddonEditField.Value,'_',app.tasktype);  
            mkdir(data_path);
            
            % get data/time for file name
            d_file = datetime(t,'ConvertFrom','datenum');
            d_str_file = datestr(d_file);
            d_str_min_file = strrep(d_str_file,':','_');
            d_str_cor_file = strrep(d_str_min_file,'-','_');
            d_str_cor_file = strrep(d_str_cor_file,' ','_');   
            data_path_file = append(data_path,'\',d_str_cor_file,'_',app.FiletextaddonEditField.Value,'_',app.tasktype);
                        
            % 1. write tone output order to file if doing tone decoding
            if strcmp(app.AnalogoutputDropDown.Value,'On - Tones') == true 
                filename_freqorder = append(data_path_file,'_freqorder','.txt');
                
                % write file output with frequency order
                fid = fopen(filename_freqorder,'w');
                fprintf(fid, '%d\n',app.freq_val_order);
                fclose(fid);
            end          

            % 2. make file to write analog data to output; writes it during the record_data loop
            app.filename_analogdata = append(data_path_file,'_data','.txt');
            app.fid_analogdata = fopen(app.filename_analogdata, 'a+');

            % 3. write first few periods of digital data to file
            dig_out_range = 1:3200; % output the first 100 digital cycles (1 cycle = 32)
            filename_digital = append(data_path_file,'_digitalpattern','.txt');            
            output_table_dig = table(app.digital_data_out_CLK(dig_out_range)',app.digital_data_out_DRESET(dig_out_range)', ...
                app.digital_data_out_HPFRESET(dig_out_range)',app.digital_data_out_enableD(dig_out_range)',app.digital_data_out_digOn(dig_out_range)', ...
                'VariableNames', {'1CLK', '2DRESET','3HPFRESET','stimdaqEN','lvlshiftEN'});
            writetable(output_table_dig,filename_digital, 'WriteVariableNames', true);

            % 4. write meta data to output 
            filename_metadata = append(data_path_file,'_metadata','.txt');
            C = cell(20,2);
            C{1,1} = 'Card 1 name';
            C{1,2} = app.card_1_name;
            C{2,1} = 'Card 2 name';
            C{2,2} = app.card_2_name;
            C{3,1} = 'Analog sampling rate';
            C{3,2} = app.ai_sample_rate;
            C{4,1} = 'Digital sampling rate';
            C{4,2} = app.digital_data_rate; 
            C{5,1} = 'MUX rate';
            C{5,2} = app.muxrate; 
            C{6,1} = 'Samples for buffer';
            C{6,2} = app.samples_for_buffer; 
            C{7,1} = 'N ch';
            C{7,2} = app.num_ch;
            C{8,1} ='HPF reset period';
            C{8,2} = app.hpf_period;
            C{9,1} = 'HPF reset duration';
            C{9,2} = app.hpf_duration;
            C{10,1} = 'MUX setting';
            C{10,2} = app.MUX_case;
            C{11,1} = 'HPF reset status';
            C{11,2} = app.HPF_case;
            C{12,1} = 'Analog output task';
            C{12,2} = app.AnalogoutputDropDown.Value;
            C{13,1} = 'Analog output channel';
            C{13,2} = app.analog_output_address;
            C{14,1} = 'Record duration (s)';
            C{14,2} = app.time_record;
            C{15,1} = 'Date & time';
            C{15,2} = d_str_cor_file;
            C{16,1} = 'Data save path = ';
            C{16,2} = data_path;
            C{17,1} = 'Analog input/save ch =';
            C{17,2} = app.ChannelDropDown.Value;
            C{18,1} = 'Card selected for analog input';
            C{18,2} = char(app.DeviceDropDown.Items(app.DeviceDropDown.Value));
            C{19,1} = 'Oversampling factor = ';
            C{19,2} = app.oversample_factor;            
            C{20,1} = 'File text to add = ';
            C{20,2} = app.FiletextaddonEditField.Value;                 
            writecell(C, filename_metadata)

            % 5. Make log of command window
            filename_commandlog = append(data_path_file,'_commandlog','.txt');
            diary(filename_commandlog)

            % 6. Make log of analog output if it is on
            if strcmp(app.AnalogoutputDropDown.Value,'Off') == false
                filename_audio_sigs = append(data_path_file,'_audiosigs','.txt');
                downsample_factor = app.num_ch*app.oversample_factor;
                downsample_audio = downsample(app.analog_data_out_total',downsample_factor);
                downsample_audio_onoff = downsample(app.analog_data_out_onoroff',downsample_factor);
                output_table_audio = table(downsample_audio, downsample_audio_onoff, ...
                    'VariableNames', {'Raw_audio_waveform', 'Audio_onoff_sig'});
                tic
                writetable(output_table_audio,filename_audio_sigs, 'WriteVariableNames', true);
                toc
            end

            % 7. Write raw output calibraiton data (about 10s of data) if
            % selected
            if app.calibrationselected == true && app.iscalibrated == 1
                filename_calib_data = append(data_path_file,'_calibrationdata','.txt');
                output_table_calib = table(app.analog_calib_data','VariableNames', {'Raw_calib_data'});
                tic
                writetable(output_table_calib,filename_calib_data, 'WriteVariableNames', true);
                toc                
            end
        end

        function run_calibration(app)
            % clip 1st second of calib time incase any artifacts at start
            n_samps_cut_start = app.ai_config_SampleRate*1+app.DeMUXshiftEditField.Value + app.dig_samps_per_analog;             % cut the first second of data (prone to artifacts)            
            n_samps_total = app.ai_config_SampleRate*app.time_record; 

            % disp('Total size of calibraiton data')
            % disp(size(app.time_vec_total(n_samps_cut_start:n_samps_total)))
            % disp(size(app.samps_total_card1(n_samps_cut_start:n_samps_total)))   

            % first demux data
            [app.time_vals_demuxed_calib, app.sorted_data_calib] = demux(app.time_vec_total(n_samps_cut_start:n_samps_total), ...
                app.samps_total_card1(n_samps_cut_start:n_samps_total), app.num_ch, app.ai_sample_rate, app.muxrate);

            % calibrate demuxed data
            app.samps_to_cut_st = 50;
            app.samps_to_cut_end = 10;

            % disp(size(app.time_vals_demuxed_calib))
            % disp(size(app.sorted_data_calib))
            
            tic
            [app.time_vals_demuxed_cor, app.avg_ch_reset_shape, app.sorted_data_calib_cor,app.avg_env_inv] = calibrate_drift( ...
                app.time_vals_demuxed_calib, app.sorted_data_calib, app.samps_to_cut_st, app.samps_to_cut_end, 1);
            toc

            % disp(size(app.avg_ch_reset_shape))
            % disp(size(app.avg_env_inv))            

            range_min = 1;
            range_max = length(app.time_vals_demuxed_cor(1,:));
            std_dev = zeros(1,app.num_ch-3);

            % View env_inv
            figure(30)
            for i = 1:app.num_ch
                subplot(8,4,i)
                bandpass_data = filtfilt(app.filt_b,app.filt_a,app.sorted_data_calib_cor(i,:));
                plot(app.time_vals_demuxed_cor(i,range_min:range_max),bandpass_data(range_min:range_max))               
                ylim([-0.01 0.01])
            end
            

        end

    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            cd('C:\Users\dropb\Documents\Gabi\16_shank\App\NeuroCrown_GUI')
            app.time_record = 1;            % default time to record
            app.tasktype = 'audiooff';      % default task type is no audio output 
            app.calibrationselected = false;% default is calibration not selected
            app.iscalibrated = 0;           % it is not calibrated when it starts up
            app.gaincorrect_option = 1;     % set it to not gain correct as default
                        
            % This function executes when the app starts, before user interacts with UI
            app.LiveDataAcquisitionUIFigure.Icon='crown_favicon.png';
            
            % Set the app controls in device selection state
            setAppViewState(app, 'deviceselection');
            drawnow
            
            % Get connected devices that have the supported subsystem and measurement types
            devices = daqListSupportedDevices(app, app.DAQSubsystemTypes, app.DAQMeasurementTypes);
            
            % Store DAQ device information (filtered list) into DevicesInfo app property
            % This is used by other functions in the app
            app.DevicesInfo = devices;
           
            % Populate the device drop down list with cell array of composite device names (ID + model)
            % First element is "Select a device"
            deviceDescriptions = cellstr(string({devices.ID}') + " [" + string({devices.Model}') + "]");
            app.DeviceDropDown.Items = ['Select a device'; deviceDescriptions];
            
            % Assign dropdown ItemsData to correspond to device index + 1
            % (first item is not a device)
            app.DeviceDropDown.ItemsData = 1:numel(devices)+1;
            
            % Create a line plot and store its handle in LivePlot app property
            % This is used for updating the live plot from scansAvailable_Callback function
            app.LivePlotLine = plot(app.LiveAxes, NaN, NaN);
            
            % Turn off axes toolbar and data tips for live plot axes
            app.LiveAxes.Toolbar.Visible = 'off';
            disableDefaultInteractivity(app.LiveAxes);
            
            % Initialize the AutoscaleYSwitch, YminSpinner, and YmaxSpinner components in the correct
            % state (AutoscaleYSwitch enabled, YminSpinner and YmaxSpinner disabled).
            updateAutoscaleYSwitchComponents(app)

            % Initialize parameters
            app.record_case = 2;            % Turns off MUX
            app.HPF_status = 3;             % Turns on HPF reset
            app.HPF_case = app.HPFresetDropDown.Value;
            app.MUX_case = app.MUXsettingDropDown.Value;

            app.is_stopbuttonpushed = false;
        end

        % Value changed function: DeviceDropDown
        function DeviceDropDownValueChanged(app, event)
            value = app.DeviceDropDown.Value;
            disp(app.DeviceDropDown.Items(app.DeviceDropDown.Value))
            
            if ~isempty(value)
                % Device index is offset by 1 because first element in device dropdown
                % is "Select a device" (not a device).
                deviceIndex = value-1 ;
                
                % Reset channel property options
                app.ChannelDropDown.Items = {''};
                app.MeasurementTypeDropDown.Items = {''};
                app.RangeDropDown.Items = {''};
                app.TerminalConfigDropDown.Items = {''};
                app.CouplingDropDown.Items = {''};                
                setAppViewState(app, 'deviceselection');

                
                % Delete data acquisition object, as a new one will be created for the newly selected device
                delete(app.DAQ);
                app.DAQ = [];
                
                if deviceIndex > 0
                    % If a device is selected
                    
                    % Get subsystem information to update channel dropdown list and channel property options
                    % For devices that have an analog input or an audio input subsystem, this is the first subsystem
                    subsystem = app.DevicesInfo(deviceIndex).Subsystems(1);
                    app.ChannelDropDown.Items = cellstr(string(subsystem.ChannelNames));
                                        
                    % Populate available measurement types for the selected device
                    app.MeasurementTypeDropDown.Items = intersect(app.DAQMeasurementTypes,...
                                subsystem.MeasurementTypesAvailable, 'stable');

                    % Update channel and channel property options
                    updateChannelMeasurementComponents(app)

                else
                    % If no device is selected

                    % Delete existing data acquisition object
                    delete(app.DAQ);
                    app.DAQ = [];
                    
                    app.DeviceDropDown.Items{1} = 'Select a device';

                    setAppViewState(app, 'deviceselection');
                end
            end
        end

        % Button pushed function: StartButton
        function StartButtonPushed(app, event)
            app.is_stopbuttonpushed = false;

            % Nidaq functions
            % Load constants for recording
            load_daqmx_constants(app)

            % Reset daq device
            reset_daq_device(app)

            % Coennect cards through backplane via RTSI ports
            connect_backplane_RTSI(app)

            % Create digital outputs and setup clk/trigger
            initialize_digital_outs(app)         

            % Create analog output (for speaker) and setup clk/trigger
            if strcmp(app.AnalogoutputDropDown.Value,'Off') == false
                initialize_analog_out(app)
            end

            % create files for logging/metadata if log data arg is on
            if app.LogDataOut == true
                write_data_to_file(app)
            end      

            % Create analog inputs and setup clk/trigger
            initialize_analog_ins(app)            

            % plot the current selected analog input on the current device
            app.channel_to_plot = str2num(app.ChannelDropDown.Value(3))+1;
            disp('device desc & analog plot/record =')
            disp(app.DeviceDropDown.Value)
            display(app.ChannelDropDown.Value)

            % create filter for data using updated filter settings
            update_filter(app)          
                               
            % Disable DAQ device, channel properties, and start acquisition UI components
            setAppViewState(app, 'acquisition');
            pause(0.001)
            
            % Generate output & record data
            record_data(app)            
            diary off
        end

        % Button pushed function: StopButton
        function StopButtonPushed(app, event)

            app.is_stopbuttonpushed = true;
            setAppViewState(app, 'configuration');
        end

        % Value changed function: ChannelDropDown
        function ChannelDropDownValueChanged(app, event)
            
            updateChannelMeasurementComponents(app)
            
        end

        % Value changed function: CouplingDropDown, RangeDropDown, 
        % ...and 1 other component
        function ChannelPropertyValueChanged(app, event)
            % Shared callback for RangeDropDown, TerminalConfigDropDown, CouplingDropDown
            
            % This executes only for 'Voltage' measurement type, since for 'Audio' measurement
            % type Range never changes, and TerminalConfig and Coupling are disabled.
            
            value = event.Source.Value;
            
            % Set channel property to selected value
            % The channel property name was previously stored in the UI component Tag
            propertyName = event.Source.Tag;
            try
                set(app.DAQ.Channels(1), propertyName, value);
            catch exception
                % In case of error show it and revert the change
                uialert(app.LiveDataAcquisitionUIFigure, exception.message, 'Channel property error');
                event.Source.Value = event.PreviousValue;
            end
            
            % Make sure shown channel property values are not stale, as some property update can trigger changes in other properties
            % Update UI with current channel property values from data acquisition object
            currentRange = app.DAQ.Channels(1).Range;
            app.RangeDropDown.Value = [currentRange.Min currentRange.Max];
            app.TerminalConfigDropDown.Value = app.DAQ.Channels(1).TerminalConfig;
            app.CouplingDropDown.Value = app.DAQ.Channels(1).Coupling;
            
        end

        % Callback function
        function RateSliderValueChanging(app, event)
            changingValue = event.Value;
            app.RateEdit.Value = changingValue;
        end

        % Callback function
        function RateSliderValueChanged(app, event)
            % Shared callback for RateSlider and RateEdit
            
            value = event.Source.Value;
            if ~isempty(app.DAQ)
                app.AnalogsamplerateEditField.Value = value;
                
                % Update UI with current rate and time window limits
                updateRateUIComponents(app)
                
            end
        end

        % Value changed function: YmaxEditField, YminEditField
        function YmaxminValueChanged(app, event)
            % Shared callback for YmaxEditField and YminEditField
            
            ymin = app.YminEditField.Value;
            ymax = app.YmaxEditField.Value;
            if ymax>ymin
                ylim(app.LiveAxes, [ymin, ymax]);
            else
                % If new limits are not correct, revert the change
                event.Source.Value = event.PreviousValue;
            end
        end

        % Value changed function: AutoscaleYSwitch
        function AutoscaleYSwitchValueChanged(app, event)
            updateAutoscaleYSwitchComponents(app)
        end

        % Value changed function: LogdatatofileSwitch
        function LogdatatofileSwitchValueChanged(app, event)
            updateLogdatatofileSwitchComponents(app)
        end

        % Close request function: LiveDataAcquisitionUIFigure
        function LiveDataAcquisitionCloseRequest(app, event)
            
            isAcquiring = ~isempty(app.DAQ) && app.DAQ.Running;
            if isAcquiring
                question = 'Abort acquisition and close app?';
                
            else
                % Acquisition is stopped
                question = 'Close app?';
            end

            try
                reset_daq_device(app)
            catch
            end
            
            uiconfirm(app.LiveDataAcquisitionUIFigure,question,'Confirm Close',...
                'CloseFcn',@(src,event) closeApp_Callback(app,src,event,isAcquiring));
            
        end

        % Value changed function: MeasurementTypeDropDown
        function MeasurementTypeDropDownValueChanged(app, event)
            
            updateChannelMeasurementComponents(app)

        end

        % Value changed function: MUXsettingDropDown
        function update_MUX_setting(app, event)
            value = app.MUXsettingDropDown.Value;
            if strcmp(value,'On') == true
                app.record_case = 1; % turns on MUX
                app.MUX_case ='MUX on';
            elseif strcmp(value,'Off') == true
                app.record_case = 2; % turns off MUX
                app.MUX_case ='MUX off';
            end
            display(value) 
        end

        % Value changed function: HPFresetDropDown
        function update_HPFreset(app, event)
            value = app.HPFresetDropDown.Value;
            if strcmp(value,'On') == true
                app.HPF_status = 3;             % turns on hpf reset
                app.HPF_case = 'HPF reset on';
            elseif strcmp(value,'Off - switch open') == true
                app.HPF_status = 2; 
                app.HPF_case = value;
            elseif strcmp(value,'Off - shorted to gnd') == true
                app.HPF_status = 1;
                app.HPF_case = value;
            end
            disp(' HPF res case = ')
            disp(value)
            disp(app.HPF_status)
        end

        % Value changed function: AnalogoutputDropDown
        function analog_output_update(app, event)

            % generates analog output type
            value = app.AnalogoutputDropDown.Value;
                        
            if strcmp(value,'On - Tones') == true 
                % If tones are selected, generate tones, randomize & append 
                [tone_outs, freq_vals] = generate_tones(0.5e3, 32e3, 13, 50e-3, 950e-3, app.ai_sample_rate,'linear');
                [append_tones_out, app.freq_val_order] = randomize_tones_append(tone_outs, freq_vals, 10);
                app.analog_data_out_total = append_tones_out;

                % update amount of time to acquire analog inputs
                app.time_record = 132;
                app.tasktype = 'tones';
                                     
            elseif strcmp(value,'On - Clicks') == true
                % If clicks are selected, generate clicks, append them
                click_duration = 0.2e-3;
                clicks_out = generate_clicks(click_duration, 1-click_duration, app.ai_sample_rate,'linear');
                append_clicks_out = append_clicks(clicks_out, 130);
                app.analog_data_out_total = append_clicks_out;

                % update amount of time to acquire analog inputs
                app.time_record = 132; 
                app.tasktype = 'clicks';

            elseif strcmp(value,'On - Clicks 10s') == true
                % If clicks are selected for 10s, generate clicks, append them
                click_duration = 0.2e-3;
                clicks_out = generate_clicks(click_duration, 1-click_duration, app.ai_sample_rate,'linear');
                append_clicks_out = append_clicks(clicks_out, 10);
                app.analog_data_out_total = append_clicks_out;

                % update amount of time to acquire analog inputs
                app.time_record = 10; 
                app.tasktype = 'clicks';

            elseif strcmp(value, 'Off') == true
                app.time_record = 10;
                app.tasktype = 'audiooff';
            end
            
            if strcmp(value,'Off') ~= true
                % create additional analog output signal to indicate if an
                % output is happening or not (to feed into open ephys for
                % microecog decoding, not used as much for NeuroCrown)
                app.analog_data_out_onoroff = zeros(1, length(app.analog_data_out_total));
                for i=1:length(app.analog_data_out_total)
                    % if analog output is on (aka not zero) then other analog
                    % output signal is 1 (indicating analog out is on)
                    if app.analog_data_out_total(i) ~= 0
                        app.analog_data_out_onoroff(i) = 1;
                    end
                end

                app.analog_data_out_total_ch = [app.analog_data_out_total, app.analog_data_out_onoroff];

                N_samples_100ms = int32(app.ai_sample_rate*100e-3);
                N_samples_5s = int32(app.ai_sample_rate*5000e-3);

                figure(6)
                subplot(4,1,1)                
                plot(app.analog_data_out_total)
                title('Analog out 0 (to speakers) zoomed in 100 ms')
                xlim([0 N_samples_100ms])                
                xlabel('Sample Number')
                ylabel('Voltage (V)')

                subplot(4,1,2)                
                plot(app.analog_data_out_onoroff)
                title('Analog out 1 (to openephys or other) zoomed in 100 ms')
                xlim([0 N_samples_100ms])                
                xlabel('Sample Number')
                ylabel('Voltage (V)')

                subplot(4,1,3)
                plot(app.analog_data_out_total)
                title('Analog out 0 (to openephys or other) zoomed in 5 s')
                xlim([0 N_samples_5s])
                xlabel('Sample Number')
                ylabel('Voltage (V)')

                subplot(4,1,4)
                plot(app.analog_data_out_onoroff)
                title('Analog out 1 (to openephys or other) zoomed in 5s')
                xlim([0 N_samples_5s])
                xlabel('Sample Number')
                ylabel('Voltage (V)')
            end
       

        end

        % Value changed function: DeMUXplotCheckBox
        function DeMUX_plot_option(app, event)
            value = app.DeMUXplotCheckBox.Value;
            app.DeMUXshiftEditFieldLabel.Enable = 'on';
            app.DeMUXshiftEditField.Enable = 'on';
        end

        % Value changed function: CalibrationDropDown
        function calibration_status_update(app, event)
            value = app.CalibrationDropDown.Value;            
            if strcmp(value,'On') == true
                app.calibrationselected = true;                
                app.time_record = 30;           
                disp('Calibration On; Make sure MUX & HPF reset are also on.')                
            end

            if strcmp(value,'Off') == true
                app.iscalibrated = 0;
            end

        end

        % Callback function
        function update_filer(app, event)
            value = app.FilterCheckBox.Value;
            
        end

        % Value changed function: FilterCheckBox
        function update_filter(app, event)
            value = app.FilterCheckBox.Value;

            % if filter data is on, make filter
            if app.FilterCheckBox.Value == 1
                F1 = app.HPF3dBEditField.Value;
                F2 = app.LPF3dBEditField.Value;
                Fs = floor(app.muxrate/32);                  % Sampling Frequency
                Fn = floor(Fs/2);                            % Nyquist Frequency
                Wp = [F1 F2]/Fn;                             % Define passband
                [app.filt_b,app.filt_a] = butter(4,Wp,'bandpass');
                %freqz(b,a, 4096, Fs);                      % view filter                     
            end


            
        end

        % Value changed function: GaincorrectCheckBox
        function update_gaincorrect(app, event)
            value = app.GaincorrectCheckBox.Value;
            if value == 1
                app.gaincorrect_option = 2;
            else
                app.gaincorrect_option = 1;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create LiveDataAcquisitionUIFigure and hide until all components are created
            app.LiveDataAcquisitionUIFigure = uifigure('Visible', 'off');
            app.LiveDataAcquisitionUIFigure.Position = [100 100 968 746];
            app.LiveDataAcquisitionUIFigure.Name = 'Live Data Acquisition';
            app.LiveDataAcquisitionUIFigure.CloseRequestFcn = createCallbackFcn(app, @LiveDataAcquisitionCloseRequest, true);

            % Create AcquisitionPanel
            app.AcquisitionPanel = uipanel(app.LiveDataAcquisitionUIFigure);
            app.AcquisitionPanel.Position = [282 642 664 89];

            % Create StartButton
            app.StartButton = uibutton(app.AcquisitionPanel, 'push');
            app.StartButton.ButtonPushedFcn = createCallbackFcn(app, @StartButtonPushed, true);
            app.StartButton.BackgroundColor = [0.4706 0.6706 0.1882];
            app.StartButton.FontSize = 14;
            app.StartButton.FontColor = [1 1 1];
            app.StartButton.Position = [423 32 100 24];
            app.StartButton.Text = 'Start';

            % Create StopButton
            app.StopButton = uibutton(app.AcquisitionPanel, 'push');
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);
            app.StopButton.BackgroundColor = [0.6392 0.0784 0.1804];
            app.StopButton.FontSize = 14;
            app.StopButton.FontColor = [1 1 1];
            app.StopButton.Position = [544 32 100 24];
            app.StopButton.Text = 'Stop';

            % Create LogdatatofileSwitchLabel
            app.LogdatatofileSwitchLabel = uilabel(app.AcquisitionPanel);
            app.LogdatatofileSwitchLabel.HorizontalAlignment = 'center';
            app.LogdatatofileSwitchLabel.Position = [50 45 84 22];
            app.LogdatatofileSwitchLabel.Text = 'Log data to file';

            % Create LogdatatofileSwitch
            app.LogdatatofileSwitch = uiswitch(app.AcquisitionPanel, 'slider');
            app.LogdatatofileSwitch.ValueChangedFcn = createCallbackFcn(app, @LogdatatofileSwitchValueChanged, true);
            app.LogdatatofileSwitch.Position = [165 46 45 20];

            % Create LogStatusText
            app.LogStatusText = uilabel(app.AcquisitionPanel);
            app.LogStatusText.Position = [54 6 532 22];
            app.LogStatusText.Text = '';

            % Create FiletextaddonEditFieldLabel
            app.FiletextaddonEditFieldLabel = uilabel(app.AcquisitionPanel);
            app.FiletextaddonEditFieldLabel.HorizontalAlignment = 'right';
            app.FiletextaddonEditFieldLabel.Position = [39 16 87 22];
            app.FiletextaddonEditFieldLabel.Text = 'File text add on';

            % Create FiletextaddonEditField
            app.FiletextaddonEditField = uieditfield(app.AcquisitionPanel, 'text');
            app.FiletextaddonEditField.Position = [135 17 132 20];

            % Create DevicePanel
            app.DevicePanel = uipanel(app.LiveDataAcquisitionUIFigure);
            app.DevicePanel.Position = [21 14 250 618];

            % Create ChannelDropDownLabel
            app.ChannelDropDownLabel = uilabel(app.DevicePanel);
            app.ChannelDropDownLabel.HorizontalAlignment = 'right';
            app.ChannelDropDownLabel.Position = [73 540 50 22];
            app.ChannelDropDownLabel.Text = 'Channel';

            % Create ChannelDropDown
            app.ChannelDropDown = uidropdown(app.DevicePanel);
            app.ChannelDropDown.Items = {};
            app.ChannelDropDown.ValueChangedFcn = createCallbackFcn(app, @ChannelDropDownValueChanged, true);
            app.ChannelDropDown.Position = [129 540 100 22];
            app.ChannelDropDown.Value = {};

            % Create MeasurementTypeDropDownLabel
            app.MeasurementTypeDropDownLabel = uilabel(app.DevicePanel);
            app.MeasurementTypeDropDownLabel.HorizontalAlignment = 'right';
            app.MeasurementTypeDropDownLabel.Position = [13 506 110 22];
            app.MeasurementTypeDropDownLabel.Text = 'Measurement Type';

            % Create MeasurementTypeDropDown
            app.MeasurementTypeDropDown = uidropdown(app.DevicePanel);
            app.MeasurementTypeDropDown.Items = {};
            app.MeasurementTypeDropDown.ValueChangedFcn = createCallbackFcn(app, @MeasurementTypeDropDownValueChanged, true);
            app.MeasurementTypeDropDown.Position = [129 506 100 22];
            app.MeasurementTypeDropDown.Value = {};

            % Create RangeDropDownLabel
            app.RangeDropDownLabel = uilabel(app.DevicePanel);
            app.RangeDropDownLabel.HorizontalAlignment = 'right';
            app.RangeDropDownLabel.Position = [82 472 41 22];
            app.RangeDropDownLabel.Text = 'Range';

            % Create RangeDropDown
            app.RangeDropDown = uidropdown(app.DevicePanel);
            app.RangeDropDown.Items = {};
            app.RangeDropDown.ValueChangedFcn = createCallbackFcn(app, @ChannelPropertyValueChanged, true);
            app.RangeDropDown.Position = [129 472 100 22];
            app.RangeDropDown.Value = {};

            % Create TerminalConfigDropDownLabel
            app.TerminalConfigDropDownLabel = uilabel(app.DevicePanel);
            app.TerminalConfigDropDownLabel.HorizontalAlignment = 'right';
            app.TerminalConfigDropDownLabel.Position = [31 405 92 22];
            app.TerminalConfigDropDownLabel.Text = 'Terminal Config.';

            % Create TerminalConfigDropDown
            app.TerminalConfigDropDown = uidropdown(app.DevicePanel);
            app.TerminalConfigDropDown.Items = {};
            app.TerminalConfigDropDown.ValueChangedFcn = createCallbackFcn(app, @ChannelPropertyValueChanged, true);
            app.TerminalConfigDropDown.Position = [129 405 100 22];
            app.TerminalConfigDropDown.Value = {};

            % Create CouplingDropDownLabel
            app.CouplingDropDownLabel = uilabel(app.DevicePanel);
            app.CouplingDropDownLabel.HorizontalAlignment = 'right';
            app.CouplingDropDownLabel.Position = [70 438 53 22];
            app.CouplingDropDownLabel.Text = 'Coupling';

            % Create CouplingDropDown
            app.CouplingDropDown = uidropdown(app.DevicePanel);
            app.CouplingDropDown.Items = {};
            app.CouplingDropDown.ValueChangedFcn = createCallbackFcn(app, @ChannelPropertyValueChanged, true);
            app.CouplingDropDown.Position = [129 438 100 22];
            app.CouplingDropDown.Value = {};

            % Create DeviceDropDownLabel
            app.DeviceDropDownLabel = uilabel(app.DevicePanel);
            app.DeviceDropDownLabel.HorizontalAlignment = 'right';
            app.DeviceDropDownLabel.Position = [21 574 42 22];
            app.DeviceDropDownLabel.Text = 'Device';

            % Create DeviceDropDown
            app.DeviceDropDown = uidropdown(app.DevicePanel);
            app.DeviceDropDown.Items = {'Detecting devices...'};
            app.DeviceDropDown.ValueChangedFcn = createCallbackFcn(app, @DeviceDropDownValueChanged, true);
            app.DeviceDropDown.Position = [69 574 160 22];
            app.DeviceDropDown.Value = 'Detecting devices...';

            % Create HPFresetDropDownLabel
            app.HPFresetDropDownLabel = uilabel(app.DevicePanel);
            app.HPFresetDropDownLabel.HorizontalAlignment = 'right';
            app.HPFresetDropDownLabel.Position = [49 211 59 22];
            app.HPFresetDropDownLabel.Text = 'HPF reset';

            % Create HPFresetDropDown
            app.HPFresetDropDown = uidropdown(app.DevicePanel);
            app.HPFresetDropDown.Items = {'On', 'Off - switch open', 'Off - shorted to gnd'};
            app.HPFresetDropDown.ValueChangedFcn = createCallbackFcn(app, @update_HPFreset, true);
            app.HPFresetDropDown.Position = [123 211 100 22];
            app.HPFresetDropDown.Value = 'On';

            % Create MUXsettingDropDownLabel
            app.MUXsettingDropDownLabel = uilabel(app.DevicePanel);
            app.MUXsettingDropDownLabel.HorizontalAlignment = 'right';
            app.MUXsettingDropDownLabel.Position = [39 297 70 22];
            app.MUXsettingDropDownLabel.Text = 'MUX setting';

            % Create MUXsettingDropDown
            app.MUXsettingDropDown = uidropdown(app.DevicePanel);
            app.MUXsettingDropDown.Items = {'Off', 'On'};
            app.MUXsettingDropDown.ValueChangedFcn = createCallbackFcn(app, @update_MUX_setting, true);
            app.MUXsettingDropDown.Tooltip = {'hello'};
            app.MUXsettingDropDown.Position = [124 297 100 22];
            app.MUXsettingDropDown.Value = 'Off';

            % Create AnalogoutputDropDownLabel
            app.AnalogoutputDropDownLabel = uilabel(app.DevicePanel);
            app.AnalogoutputDropDownLabel.HorizontalAlignment = 'right';
            app.AnalogoutputDropDownLabel.Position = [28 180 79 22];
            app.AnalogoutputDropDownLabel.Text = 'Analog output';

            % Create AnalogoutputDropDown
            app.AnalogoutputDropDown = uidropdown(app.DevicePanel);
            app.AnalogoutputDropDown.Items = {'Off', 'On - Tones', 'On - Clicks', 'On - Clicks 10s'};
            app.AnalogoutputDropDown.ValueChangedFcn = createCallbackFcn(app, @analog_output_update, true);
            app.AnalogoutputDropDown.Position = [123 180 100 22];
            app.AnalogoutputDropDown.Value = 'Off';

            % Create DeMUXplotCheckBox
            app.DeMUXplotCheckBox = uicheckbox(app.DevicePanel);
            app.DeMUXplotCheckBox.ValueChangedFcn = createCallbackFcn(app, @DeMUX_plot_option, true);
            app.DeMUXplotCheckBox.Text = 'DeMUX plot';
            app.DeMUXplotCheckBox.Position = [124 267 100 24];

            % Create OversamplefactorEditFieldLabel
            app.OversamplefactorEditFieldLabel = uilabel(app.DevicePanel);
            app.OversamplefactorEditFieldLabel.HorizontalAlignment = 'right';
            app.OversamplefactorEditFieldLabel.Position = [20 332 104 22];
            app.OversamplefactorEditFieldLabel.Text = 'Oversample factor';

            % Create OversamplefactorEditField
            app.OversamplefactorEditField = uieditfield(app.DevicePanel, 'numeric');
            app.OversamplefactorEditField.Position = [199 332 30 23];
            app.OversamplefactorEditField.Value = 1;

            % Create AnalogsamplerateEditFieldLabel
            app.AnalogsamplerateEditFieldLabel = uilabel(app.DevicePanel);
            app.AnalogsamplerateEditFieldLabel.HorizontalAlignment = 'right';
            app.AnalogsamplerateEditFieldLabel.Position = [13 366 110 22];
            app.AnalogsamplerateEditFieldLabel.Text = 'Analog sample rate';

            % Create AnalogsamplerateEditField
            app.AnalogsamplerateEditField = uieditfield(app.DevicePanel, 'numeric');
            app.AnalogsamplerateEditField.Position = [149 366 80 22];
            app.AnalogsamplerateEditField.Value = 1280000;

            % Create CalibrationDropDownLabel
            app.CalibrationDropDownLabel = uilabel(app.DevicePanel);
            app.CalibrationDropDownLabel.HorizontalAlignment = 'right';
            app.CalibrationDropDownLabel.Position = [38 148 69 22];
            app.CalibrationDropDownLabel.Text = 'Calibration';

            % Create CalibrationDropDown
            app.CalibrationDropDown = uidropdown(app.DevicePanel);
            app.CalibrationDropDown.Items = {'Off', 'On'};
            app.CalibrationDropDown.ValueChangedFcn = createCallbackFcn(app, @calibration_status_update, true);
            app.CalibrationDropDown.Position = [123 146 99 25];
            app.CalibrationDropDown.Value = 'Off';

            % Create HPFdriftremoveCheckBox
            app.HPFdriftremoveCheckBox = uicheckbox(app.DevicePanel);
            app.HPFdriftremoveCheckBox.Text = 'HPF drift remove';
            app.HPFdriftremoveCheckBox.Position = [122 115 113 20];

            % Create GaincorrectCheckBox
            app.GaincorrectCheckBox = uicheckbox(app.DevicePanel);
            app.GaincorrectCheckBox.ValueChangedFcn = createCallbackFcn(app, @update_gaincorrect, true);
            app.GaincorrectCheckBox.Text = 'Gain correct';
            app.GaincorrectCheckBox.Position = [122 88 106 22];

            % Create FilterCheckBox
            app.FilterCheckBox = uicheckbox(app.DevicePanel);
            app.FilterCheckBox.ValueChangedFcn = createCallbackFcn(app, @update_filter, true);
            app.FilterCheckBox.Text = 'Filter';
            app.FilterCheckBox.Position = [122 62 106 20];

            % Create HPF3dBEditFieldLabel
            app.HPF3dBEditFieldLabel = uilabel(app.DevicePanel);
            app.HPF3dBEditFieldLabel.HorizontalAlignment = 'right';
            app.HPF3dBEditFieldLabel.Position = [122 37 58 22];
            app.HPF3dBEditFieldLabel.Text = 'HPF  -3dB';

            % Create HPF3dBEditField
            app.HPF3dBEditField = uieditfield(app.DevicePanel, 'numeric');
            app.HPF3dBEditField.Position = [195 40 40 17];
            app.HPF3dBEditField.Value = 10;

            % Create LPF3dBEditFieldLabel
            app.LPF3dBEditFieldLabel = uilabel(app.DevicePanel);
            app.LPF3dBEditFieldLabel.HorizontalAlignment = 'right';
            app.LPF3dBEditFieldLabel.Position = [121 13 59 22];
            app.LPF3dBEditFieldLabel.Text = 'LPF  -3dB';

            % Create LPF3dBEditField
            app.LPF3dBEditField = uieditfield(app.DevicePanel, 'numeric');
            app.LPF3dBEditField.Position = [195 16 40 19];
            app.LPF3dBEditField.Value = 1000;

            % Create DeMUXshiftEditFieldLabel
            app.DeMUXshiftEditFieldLabel = uilabel(app.DevicePanel);
            app.DeMUXshiftEditFieldLabel.HorizontalAlignment = 'right';
            app.DeMUXshiftEditFieldLabel.Position = [121 245 71 22];
            app.DeMUXshiftEditFieldLabel.Text = 'DeMUX shift';

            % Create DeMUXshiftEditField
            app.DeMUXshiftEditField = uieditfield(app.DevicePanel, 'numeric');
            app.DeMUXshiftEditField.Position = [199 246 25 19];

            % Create NeuroCrownRecordingLabel
            app.NeuroCrownRecordingLabel = uilabel(app.LiveDataAcquisitionUIFigure);
            app.NeuroCrownRecordingLabel.FontSize = 20;
            app.NeuroCrownRecordingLabel.Position = [27 669 232 32];
            app.NeuroCrownRecordingLabel.Text = 'NeuroCrown Recording';

            % Create LiveViewPanel
            app.LiveViewPanel = uipanel(app.LiveDataAcquisitionUIFigure);
            app.LiveViewPanel.Position = [282 14 664 618];

            % Create LiveAxes
            app.LiveAxes = uiaxes(app.LiveViewPanel);
            xlabel(app.LiveAxes, 'Time (s)')
            ylabel(app.LiveAxes, 'Voltage (V)')
            app.LiveAxes.XTickLabelRotation = 0;
            app.LiveAxes.YTickLabelRotation = 0;
            app.LiveAxes.ZTickLabelRotation = 0;
            app.LiveAxes.Position = [6 26 638 554];

            % Create AutoscaleYSwitchLabel
            app.AutoscaleYSwitchLabel = uilabel(app.LiveViewPanel);
            app.AutoscaleYSwitchLabel.HorizontalAlignment = 'center';
            app.AutoscaleYSwitchLabel.Position = [9 589 70 22];
            app.AutoscaleYSwitchLabel.Text = 'Autoscale Y';

            % Create AutoscaleYSwitch
            app.AutoscaleYSwitch = uiswitch(app.LiveViewPanel, 'slider');
            app.AutoscaleYSwitch.ValueChangedFcn = createCallbackFcn(app, @AutoscaleYSwitchValueChanged, true);
            app.AutoscaleYSwitch.Position = [102 590 45 20];
            app.AutoscaleYSwitch.Value = 'On';

            % Create YminEditFieldLabel
            app.YminEditFieldLabel = uilabel(app.LiveViewPanel);
            app.YminEditFieldLabel.HorizontalAlignment = 'right';
            app.YminEditFieldLabel.Position = [186 589 33 22];
            app.YminEditFieldLabel.Text = 'Ymin';

            % Create YminEditField
            app.YminEditField = uieditfield(app.LiveViewPanel, 'numeric');
            app.YminEditField.ValueChangedFcn = createCallbackFcn(app, @YmaxminValueChanged, true);
            app.YminEditField.Position = [226 589 52 22];
            app.YminEditField.Value = -1;

            % Create YmaxEditFieldLabel
            app.YmaxEditFieldLabel = uilabel(app.LiveViewPanel);
            app.YmaxEditFieldLabel.HorizontalAlignment = 'right';
            app.YmaxEditFieldLabel.Position = [291 589 36 22];
            app.YmaxEditFieldLabel.Text = 'Ymax';

            % Create YmaxEditField
            app.YmaxEditField = uieditfield(app.LiveViewPanel, 'numeric');
            app.YmaxEditField.ValueChangedFcn = createCallbackFcn(app, @YmaxminValueChanged, true);
            app.YmaxEditField.Position = [334 589 52 22];
            app.YmaxEditField.Value = 1;

            % Create TimewindowsEditFieldLabel
            app.TimewindowsEditFieldLabel = uilabel(app.LiveViewPanel);
            app.TimewindowsEditFieldLabel.HorizontalAlignment = 'right';
            app.TimewindowsEditFieldLabel.Position = [431 589 92 22];
            app.TimewindowsEditFieldLabel.Text = 'Time window (s)';

            % Create TimewindowEditField
            app.TimewindowEditField = uieditfield(app.LiveViewPanel, 'numeric');
            app.TimewindowEditField.Position = [527 589 32 22];
            app.TimewindowEditField.Value = 1;

            % Create xlimEditFieldLabel
            app.xlimEditFieldLabel = uilabel(app.LiveViewPanel);
            app.xlimEditFieldLabel.HorizontalAlignment = 'right';
            app.xlimEditFieldLabel.Position = [565 588 26 22];
            app.xlimEditFieldLabel.Text = 'xlim';

            % Create xlimEditField
            app.xlimEditField = uieditfield(app.LiveViewPanel, 'numeric');
            app.xlimEditField.Position = [596 588 41 22];
            app.xlimEditField.Value = 0.05;

            % Show the figure after all components are created
            app.LiveDataAcquisitionUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = LiveDataAcquisition

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.LiveDataAcquisitionUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.LiveDataAcquisitionUIFigure)
        end
    end
end