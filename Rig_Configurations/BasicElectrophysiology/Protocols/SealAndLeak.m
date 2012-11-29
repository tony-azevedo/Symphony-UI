%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef SealAndLeak < SymphonyProtocol
    
    properties (Constant, Hidden)
        identifier = 'org.janelia.research.murphy.sealandleak'
        version = 1
        displayName = 'Seal and Leak'
		rigIdentifier = 'BasicElectrophysiology'
    end
    
    properties
        epochDuration = uint32(100)     % milliseconds
        pulseDuration = uint32(50)      % milliseconds
        pulseAmplitude = 5              % picoamperes or millivolts
        background = 0                  % picoamperes or millivolts
        CHANNELS = {'Ch1'};        
    end
    
    properties (Hidden)
        % Two Required variables if you have a header to load.
        % Example below:
        
        % Required if you have a header to load.
        logFileHeaderFile = '';
%        
%         propertiesToLog = { ...
%             'epochDuration' ...
%             'pulseDuration' ...
%             'pulseAmplitude' ...
%         };     

        % variables to determin how many channels the protocol has
        channels = 1;
        selectedChannel = 1         % The channel selected within the protocol
    end
    
    methods        
        function dn = requiredDeviceNames(obj) %#ok<MANU>
            dn = {'Amplifier_Ch1'};
        end
        
        function obj = SealAndLeak(varargin)
            if nargin == 2
                logging = varargin{1};
                logFileFolders = varargin{2};
            else
                logging = 0;
                logFileFolders = {};
            end
            
            obj = obj@SymphonyProtocol(logging,logFileFolders);
            
            obj.allowSavingEpochs = false;
        end

        function prepareRig(obj)
            % Call the base class method to set the DAQ sample rate.
            prepareRig@SymphonyProtocol(obj);
            
%             if strcmp(obj.multiClampMode, 'VClamp')
%                 obj.setDeviceBackground('Amplifier_Ch1', obj.background * 1e-3, 'V');
%             else
%                 obj.setDeviceBackground('Amplifier_Ch1', obj.background * 1e-12, 'A');
%             end
        end
        
        
        function stimulus = stimulusForDevice(obj, deviceName)
            sampleRate = obj.deviceSampleRate(deviceName, 'OUT');
            epochSamples = floor(double(obj.getProtocolPropertiesValue('epochDuration')) / 1000.0 * System.Decimal.ToDouble(sampleRate.Quantity));
            pulseSamples = floor(double(obj.getProtocolPropertiesValue('pulseDuration')) / 1000.0 * System.Decimal.ToDouble(sampleRate.Quantity));
            pulseStart = floor((epochSamples - pulseSamples) / 2.0);    % centered within the epoch
            stimulus = ones(1, epochSamples) * obj.getProtocolPropertiesValue('background');
            stimulus(pulseStart:pulseStart + pulseSamples - 1) = ones(1, pulseSamples) * (obj.getProtocolPropertiesValue('pulseAmplitude') + obj.getProtocolPropertiesValue('background'));
        end
        
        
        function stimuli = sampleStimuli(obj)
            if isempty(obj.rigConfig.deviceWithName('Amplifier_Ch1'))
                stimuli = {};
            else
                if strcmp(obj.multiClampMode, 'VClamp')
                    stimuli = {obj.stimulusForDevice('Amplifier_Ch1') * 1e-3};
                else
                    stimuli = {obj.stimulusForDevice('Amplifier_Ch1') * 1e-12};
                end
            end
        end
        
        
        function prepareRun(obj)
            % Call the base class method which clears all figures.
            prepareRun@SymphonyProtocol(obj);
            
            obj.openFigure('Response');
            obj.openFigure('Mean Response');
        end
        
        
        function prepareEpoch(obj)
            import Symphony.Core.*
            
            % Call the base class method which sets up default backgrounds and records responses.
            prepareEpoch@SymphonyProtocol(obj);
            
            if strcmp(obj.multiClampMode, 'VClamp')
                obj.setDeviceBackground('Amplifier_Ch1', obj.getProtocolPropertiesValue('background') * 1e-3, 'V');
            else
                obj.setDeviceBackground('Amplifier_Ch1', obj.getProtocolPropertiesValue('background') * 1e-12, 'A');
            end
            
            stimulus = obj.stimulusForDevice('Amplifier_Ch1');
            
            if strcmp(obj.multiClampMode, 'VClamp')
                obj.addStimulus('Amplifier_Ch1', 'amp_ch1_stimulus', stimulus * 1e-3, 'V');
            else
                obj.addStimulus('Amplifier_Ch1', 'amp_ch1_stimulus', stimulus * 1e-12, 'A');
            end
        end

    end
end