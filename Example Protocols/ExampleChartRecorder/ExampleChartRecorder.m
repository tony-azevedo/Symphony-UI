% This protocol will build up a delay in displaying response data over time. It is NOT intended to be a accurate chart
% recorder. It is intended as a simple demonstation of working with epoch response data as it is recorded (as opposed to 
% after it is recorded like a standard protocol).

classdef ExampleChartRecorder < SymphonyProtocol

    properties (Constant)
        identifier = 'io.github.symphony-das.ExampleChartRecorder'
        version = 1
        displayName = 'Example Chart Recorder'
    end
    
    properties
        amp
        bufferSize = 10
    end
    
    properties (Hidden)
        receivedDataListener
    end
    
    methods           
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@SymphonyProtocol(obj, parameterName);
            
            % Return properties for the specified parameter (see ParameterProperty class).
            switch parameterName
                case 'amp'
                    % Prefer assigning default values in the property block above.
                    % However if a default value cannot be defined as a constant or expression, it must be defined here.
                    p.defaultValue = obj.rigConfig.multiClampDeviceNames();
                case 'bufferSize'
                    p.units = 's';
            end
        end     
        
        
        function init(obj, symphonyConfig, rigConfig)
            % Call the base method.
            init@SymphonyProtocol(obj, symphonyConfig, rigConfig);
            
            % Epochs of indefinite duration, like those produced by this protocol, cannot be saved. 
            obj.allowSavingEpochs = false;
            obj.allowPausing = false;            
        end

        
        function receiveInputData(obj, ~, eventData)
            % The controller receives chunks of input data from devices as an epoch runs. We can store and plot those 
            % chunks as they come in to create a basic chart recorder.
            
            import Symphony.Core.*;
            
            % Extract the data and the device that produced the data for the event.
            chunkOfData = eventData.Data;
            fromDevice = char(eventData.Device.Name);
            
            % We're not interested in any other device data beyond the amp
            if ~strcmpi(fromDevice, obj.amp)
                return
            end
            
            % Convert the data to a Matlab vector.
            chunk = double(Measurement.ToQuantityArray(chunkOfData.Data));
            
            % Retrieve any data we've already collected for this device.
            if isKey(obj.responses, fromDevice)
                response = obj.responses(fromDevice);
            else
                sampleRate = System.Decimal.ToDouble(chunkOfData.SampleRate.QuantityInBaseUnit);
                units = char(Measurement.HomogenousDisplayUnits(chunkOfData.Data));
                response = struct('data', NaN(1, obj.bufferSize * sampleRate), 'sampleRate', sampleRate, 'units', units);
            end
            
            % Shift our existing data left to fit the new chunk and insert the chunk at the end.
            chunkLength = length(chunk);
            response.data = [response.data([chunkLength + 1:end]) chunk];
            
            % Store our new response data and replot it in our figure handler.
            obj.responses(fromDevice) = response;
            obj.updateFigures();
        end

        
        function prepareRun(obj)
            % Call the base method.
            prepareRun@SymphonyProtocol(obj);
            
            % Open a figure to show the amp response.
            obj.openFigure('Response', obj.amp);
                    
            % Add an event listener to call our receiveInputData method when the controller receives new data.
            obj.receivedDataListener = addlistener(obj.rigConfig.controller, 'ReceivedInputData', @(src, data) obj.receiveInputData(src, data));
        end
        
        
        function [stim, units] = stimulus(obj)
            % Create an empty one second stimulus.
            stim = zeros(1, obj.sampleRate);
            
            % Convert the pulse stimulus to appropriate units for the current multiclamp mode.
            if strcmp(obj.rigConfig.multiClampMode(obj.amp), 'VClamp')
                units = 'V';
            else
                units = 'A';
            end
        end
       
        
        function prepareEpoch(obj)
            % Call the base method.
            prepareEpoch@SymphonyProtocol(obj);           
                       
            % Set the amp hold signal.
            if strcmp(obj.rigConfig.multiClampMode(obj.amp), 'VClamp')
                obj.setDeviceBackground(obj.amp, 0, 'V');
            else
                obj.setDeviceBackground(obj.amp, 0, 'A');
            end            
            
            % Add an indefinite empty stimulus just so we can monitor the response.
            [stim, units] = obj.stimulus();
            obj.addStimulus(obj.amp, [obj.amp '_Stimulus'], stim, units, 'indefinite');
        end
        
        
        function recordResponse(obj, ~)  %#ok<INUSD>
            % Responses cannot be recorded for indefinite epochs so we must override this method with an empty implementation.
        end
        
        
        function keepGoing = continueRun(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@SymphonyProtocol(obj);
            
            % Perform only one indefinite epoch.
            if keepGoing
                keepGoing = obj.epochNum < 1;
            end
        end
        
        
        function completeRun(obj)
            % Call the base method.
            completeRun@SymphonyProtocol(obj);
            
            % Delete our event listener (don't forget if you add them you need to delete them!)
            delete(obj.receivedDataListener);
        end
        
    end
    
end