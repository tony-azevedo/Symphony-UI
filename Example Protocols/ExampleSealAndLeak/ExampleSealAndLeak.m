classdef ExampleSealAndLeak < SymphonyProtocol

    properties (Constant)
        identifier = 'io.github.symphony-das.ExampleSealAndLeak'
        version = 1
        displayName = 'Example Seal and Leak'
    end
    
    properties
        amp
        mode = {'seal', 'leak'}
        alternateMode = true
        preTime = 15
        stimTime = 30
        tailTime = 15
        pulseAmplitude = 5
        leakAmpHoldSignal = -60
    end
    
    properties (Hidden, Dependent, SetAccess = private)
        ampHoldSignal
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
                case 'alternateMode'
                    p.description = 'Alternate from seal to leak to seal etc., on each successive run.';
                case {'preTime', 'stimTime', 'tailTime'}
                    p.units = 'ms';
                case {'pulseAmplitude', 'leakAmpHoldSignal'}
                    p.units = 'mV or pA';
            end
        end
                
        
        function s = get.ampHoldSignal(obj)
            if strcmpi(obj.mode, 'seal')
                s = 0;
            else
                s = obj.leakAmpHoldSignal;
            end
        end
        
        
        function init(obj, symphonyConfig, rigConfig)
            % Call the base method.
            init@SymphonyProtocol(obj, symphonyConfig, rigConfig);
            
            % Epochs of indefinite duration, like those produced by this protocol, cannot be saved. 
            obj.allowSavingEpochs = false;
            obj.allowPausing = false;            
        end  
        
        
        function prepareRun(obj)
            % Call the base method.
            prepareRun@SymphonyProtocol(obj);
            
            % Set the amp hold signal.
            if strcmp(obj.rigConfig.multiClampMode(obj.amp), 'VClamp')
                obj.rigConfig.setDeviceBackground(obj.amp, obj.ampHoldSignal * 1e-3, 'V');
            else
                obj.rigConfig.setDeviceBackground(obj.amp, obj.ampHoldSignal * 1e-12, 'A');
            end
        end
        
        
        function [stim, units] = generateStimulus(obj)
            % Convert time to sample points.
            prePts = round(obj.preTime / 1e3 * obj.sampleRate);
            stimPts = round(obj.stimTime / 1e3 * obj.sampleRate);
            tailPts = round(obj.tailTime / 1e3 * obj.sampleRate);
            
            % Create pulse stimulus.           
            stim = ones(1, prePts + stimPts + tailPts) * obj.ampHoldSignal;
            stim(prePts + 1:prePts + stimPts) = obj.pulseAmplitude + obj.ampHoldSignal;
            
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
            % return a sample stimulus for display in the edit parameters window.
            stimuli{1} = obj.generateStimulus();
        end
       
        
        function prepareEpoch(obj, epoch)            
            % With an indefinite epoch protocol we should not call the base class.
            %prepareEpoch@SymphonyProtocol(obj, epoch);
            
            % Set the epoch default background values for each device.
            devices = obj.rigConfig.devices();
            for i = 1:length(devices)
                device = devices{i};
                
                % Set the default epoch background to be the same as the device background.
                if ~isempty(device.OutputSampleRate)
                    epoch.setBackground(char(device.Name), device.Background.Quantity, device.Background.DisplayUnit);
                end
            end
                        
            % Add the amp pulse stimulus to the epoch.
            [stim, units] = obj.generateStimulus();            
            epoch.addStimulus(obj.amp, [obj.amp '_Stimulus'], stim, units, 'indefinite');
        end
        
        
        function keepQueuing = continueQueuing(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepQueuing = continueQueuing@SymphonyProtocol(obj);
            
            % Queue only one indefinite epoch.
            if keepQueuing
                keepQueuing = obj.numEpochsQueued < 1;
            end            
        end
        
        
        function completeRun(obj)
            % Call the base method.
            completeRun@SymphonyProtocol(obj);
            
            if obj.alternateMode
                if strcmpi(obj.mode, 'seal')
                    obj.mode = 'leak';
                else
                    obj.mode = 'seal';
                end
            end
        end

    end
    
end

