% Creates a single stimulus composed of mean + flash for multiple LEDs
% Implements SymphonyProtocol
%
%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html
%
%  Modified by TA 9.8.12 from LED Family to create a single LED pulse protocol
classdef ThreeChannelLED < SymphonyProtocol

    properties (Constant, Hidden)
        identifier = 'helsinki.yliopisto.pal'
        version = 1
        displayName = 'Three Channel LED'
		rigIdentifier = 'RetinaElectrophysiology'
    end
    
    properties
        stimPoints = uint16(100);
        prePoints = uint16(1000);
        tailPoints = uint16(4000);
        stimAmplitude = 0.5;
        lightMean = 0.0;
        preSynapticHold = -60;
        numberOfAverages = uint8(5);
        interpulseInterval = 0.6;
        continuousRun = false;
        TTL1 = {'A','B'};
        
        % the channels variable
        CHANNELS = {'Ch1','Ch2','Ch3'};
    end
    
    properties (Hidden)
        % Required for Logging functionality
        % if no property value will appear in the log file
        propertiesToLog = { ...
            'prePoints' ...
            'tailPoints' ...
            'lightMean' ...
            'stimAmplitude' ...
            'preSynapticHold' ...
        };     
        
        % variables to determin how many channels the protocol has
        channels = 3;
        selectedChannel = 1         % The channel selected within the protocol        
    end
    
    properties (Dependent = true, SetAccess = private) % these properties are inherited - i.e., not modifiable
        % ampOfLastStep;  
    end
    
    methods

        function obj = ThreeChannelLED(varargin)
%             obj = obj@SymphonyProtocol();
        end
        
        function [stimulus, lightAmplitude] = stimulusForEpoch(obj, ~) % epoch Num is usually required
            % Calculate the light amplitude for this epoch.
            % phase = single(mod(epochNum - 1, obj.stepsInFamily));               % Frank's clever way to determine which flash in a family to deliver
            lightAmplitude = obj.getProtocolPropertiesValue('stimAmplitude');
            % Create the stimulus
            pP = obj.getProtocolPropertiesValue('prePoints');
            sP = obj.getProtocolPropertiesValue('stimPoints');
            
            stimulus = ones(1, pP...
                             + sP...
                             + obj.getProtocolPropertiesValue('tailPoints'))...
                             * obj.getProtocolPropertiesValue('lightMean');
            stimulus(pP + 1:pP + sP) = lightAmplitude;
        end
        
        
        function stimulus = sampleStimuli(obj) % Return a cell array
            % you can only create one stimulus with this protocol TA
            stimulus{1} = obj.stimulusForEpoch();
        end
        
        
        function prepareRig(obj)
            % Call the base class method to set the DAQ sample rate.
            prepareRig@SymphonyProtocol(obj);
            
            ttl1 = 5;
            if strcmp(obj.getProtocolPropertiesValue('TTL1'),'A')
                ttl1 = 0;
            end
            
            obj.setDeviceBackground([obj.getProtocolPropertiesValue('CHANNELS') 'AORB'], ttl1, '_unitless_');
            obj.setDeviceBackground(obj.getProtocolPropertiesValue('CHANNELS'), obj.getProtocolPropertiesValue('lightMean'), 'V', 'lightMean');

            if strcmp(obj.rigConfig.multiClampMode('Amplifier_Ch1'), 'IClamp')
                obj.setDeviceBackground('Amplifier_Ch1', double(obj.getProtocolPropertiesValue('preSynapticHold')) * 1e-12, 'A');
            else
                % multiClampMode is 'VClamp'
                obj.setDeviceBackground('Amplifier_Ch1', double(obj.getProtocolPropertiesValue('preSynapticHold')) * 1e-3, 'V');
            end
        end
        
        
        function prepareRun(obj)
            % Call the base class method which clears all figures.
            prepareRun@SymphonyProtocol(obj);

            obj.openFigure('Response');
            obj.openFigure('Mean Response', 'GroupByParams', {'lightAmplitude'});
            obj.openFigure('Response Statistics', 'StatsCallback', @responseStatistics);
        end
        
        
        function prepareEpoch(obj)
            % Call the base class method which sets up default backgrounds and records responses.
            prepareEpoch@SymphonyProtocol(obj);
            
            [stimulus, lightAmplitude] = obj.stimulusForEpoch(obj.epochNum);
            obj.addParameter('lightAmplitude', lightAmplitude);
            obj.setDeviceBackground(obj.getProtocolPropertiesValue('CHANNELS'), obj.getProtocolPropertiesValue('lightMean'), 'V');
            if strcmp(obj.multiClampMode, 'VClamp')
                obj.setDeviceBackground('Amplifier_Ch1', double(obj.getProtocolPropertiesValue('preSynapticHold')) * 1e-3, 'V');
            else
                obj.setDeviceBackground('Amplifier_Ch1', double(obj.getProtocolPropertiesValue('preSynapticHold')) * 1e-12, 'A');
            end 
            obj.addStimulus(obj.getProtocolPropertiesValue('CHANNELS'), sprintf('%s stimulus',obj.getProtocolPropertiesValue('CHANNELS')), stimulus, 'V');    %
        end
        
        
        function stats = responseStatistics(obj)
            r = obj.response();
            
            % baseline mean and var
            if ~isempty(r)
                stats.mean = mean(r(1:obj.getProtocolPropertiesValue('prePoints')));
                stats.var = var(r(1:obj.getProtocolPropertiesValue('prePoints')));
            else
                stats.mean = 0;
                stats.var = 0;
            end
        end
        
        
        function completeEpoch(obj)
            % Call the base class method which updates the figures.
            completeEpoch@SymphonyProtocol(obj);
            
            % Pause for the inter-pulse interval.
            pause on
            pause(obj.interpulseInterval);
        end
        
        
        function keepGoing = continueRun(obj)   
            % First check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@SymphonyProtocol(obj);
            
            if keepGoing
                keepGoing = obj.epochNum < obj.getProtocolPropertiesValue('numberOfAverages');
            end
        end
        
        
%         function amp = get.ampOfLastStep(obj)   % The product of the number of steps in family, the first step amplitude, and the 'scale factor'
%             amp = obj.baseLightAmplitude * obj.ampStepScale ^ (obj.stepsInFamily - 1);
%         end

    end
end