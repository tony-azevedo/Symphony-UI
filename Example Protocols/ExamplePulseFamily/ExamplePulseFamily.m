classdef ExamplePulseFamily < SymphonyProtocol

    properties (Constant)
        identifier = 'io.github.symphony-das.ExamplePulseFamily'
        version = 1
        displayName = 'Example Pulse Family'
    end
    
    properties
        amp
        preTime = 50
        stimTime = 500
        tailTime = 50
        firstPulseSignal = 100
        incrementPerPulse = 10
        pulsesInFamily = uint16(11)
        preAndTailSignal = -60
        ampHoldSignal = -60
        numberOfAverages = uint16(5)
        interpulseInterval = 0
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
                case {'preTime', 'stimTime', 'tailTime'}
                    p.units = 'ms';
                case {'firstPulseSignal', 'incrementPerPulse', 'preAndTailSignal', 'ampHoldSignal'}
                    p.units = 'mV or pA';
                case 'interpulseInterval'
                    p.units = 's';
            end
        end
        
        
        function prepareRun(obj)
            % Call the base method.
            prepareRun@SymphonyProtocol(obj);
            
            % Set the amp hold signal.
            if strcmp(obj.rigConfig.multiClampMode(obj.amp), 'VClamp')
                obj.setDeviceBackground(obj.amp, obj.ampHoldSignal * 1e-3, 'V');
            else
                obj.setDeviceBackground(obj.amp, obj.ampHoldSignal * 1e-12, 'A');
            end
            
            % Open figures showing the response and mean response of the amp.
            obj.openFigure('Mean Response', obj.amp);
            obj.openFigure('Response', obj.amp);
        end
        
        
        function [stim, units] = generateStimulus(obj, pulseNum)
            % Convert time to sample points.
            prePts = round(obj.preTime / 1e3 * obj.sampleRate);
            stimPts = round(obj.stimTime / 1e3 * obj.sampleRate);
            tailPts = round(obj.tailTime / 1e3 * obj.sampleRate);
            
            % Create pulse stimulus.
            stim = ones(1, prePts + stimPts + tailPts) * obj.preAndTailSignal;
            stim(prePts + 1:prePts + stimPts) = obj.incrementPerPulse * (pulseNum - 1) + obj.firstPulseSignal;
            
            % Convert the pulse stimulus to appropriate units for the current multiclamp mode.
            if strcmp(obj.rigConfig.multiClampMode(obj.amp), 'VClamp')
                stim = stim * 1e-3; % mV to V
                units = 'V';
            else
                stim = stim * 1e-12; % pA to A
                units = 'A';
            end
        end
        
        
        function stimuli = sampleStimuli(obj)
            % Return a sample stimulus for display in the edit parameters window.
            stimuli = cell(obj.pulsesInFamily, 1);
            for i = 1:obj.pulsesInFamily         
                stimuli{i} = obj.generateStimulus(i);
            end
        end
       
        
        function prepareEpoch(obj, epoch)
            % Call the base method.
            prepareEpoch@SymphonyProtocol(obj, epoch);
            
            % Add the amp pulse stimulus to the epoch.
            pulseNum = mod(obj.numEpochsQueued, obj.pulsesInFamily) + 1;
            [stim, units] = obj.generateStimulus(pulseNum);
            epoch.addStimulus(obj.amp, [obj.amp '_Stimulus'], stim, units);
        end
               
               
        function queueEpoch(obj, epoch)            
            % Call the base method to queue the actual epoch.
            queueEpoch@SymphonyProtocol(obj, epoch);
            
            % Do we need to queue an interval epoch?
            if obj.interpulseInterval <= 0
                return;
            end
            
            import Symphony.Core.*;
            
            % Create an interval epoch to perform the inter-pulse interval.
            intervalEpoch = EpochWrapper(Epoch(obj.identifier), @(name)obj.rigConfig.deviceWithName(name));
            intervalEpoch.addParameter('isIntervalEpoch', true);
            
            % We don't care to save interval epochs.
            intervalEpoch.shouldBePersisted = false;
            
            % Set the interval epoch background values to the device background for all devices.
            devices = obj.rigConfig.devices();
            for i = 1:length(devices)
                device = devices{i};
                
                if ~isempty(device.OutputSampleRate)
                    intervalEpoch.setBackground(char(device.Name), device.Background.Quantity, device.Background.DisplayUnit);
                end
            end
            
            % Add a stimulus of duration equal to the inter-pulse interval.            
            [background, units] = intervalEpoch.getBackground(obj.amp);
            pts = round(obj.interpulseInterval * obj.sampleRate);
            interval = ones(1, pts) * background;
            intervalEpoch.addStimulus(obj.amp, 'Interpulse_Interval', interval, units);
            
            % Queue the interval epoch.
            obj.rigConfig.controller.EnqueueEpoch(intervalEpoch.getCoreEpoch);
        end
        
        
        function completeEpoch(obj, epoch)            
            % Don't bother with interval epochs.
            if epoch.containsParameter('isIntervalEpoch')
                return;
            end
                                    
            % Call the base method.
            completeEpoch@SymphonyProtocol(obj, epoch);
        end
        
        
        function keepQueuing = continueQueuing(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepQueuing = continueQueuing@SymphonyProtocol(obj);
            
            % Keep queuing until the requested number of averages have been queued.
            if keepQueuing
                keepQueuing = obj.numEpochsQueued < obj.numberOfAverages * obj.pulsesInFamily;
            end
        end
        
        
        function keepGoing = continueRun(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@SymphonyProtocol(obj);
            
            % Keep going until the requested number of epochs is reached.
            if keepGoing
                keepGoing = obj.numEpochsCompleted < obj.numberOfAverages * obj.pulsesInFamily;
            end
        end
        
    end
    
end