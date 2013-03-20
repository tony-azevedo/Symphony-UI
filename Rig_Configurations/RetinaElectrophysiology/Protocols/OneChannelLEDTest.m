% Creates a single stimulus composed of mean + flash for multiple LEDs
% Implements SymphonyProtocol
%
%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html
%
%  Modified by TA 9.8.12 from LED Family to create a single LED pulse protocol
classdef OneChannelLEDTest < LEDFamily

    properties (Constant, Hidden)
        displayName = 'One Channel LED Test'
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
        CHANNELS = {'Ch1'};
        TTL1 = {'A','B'};
    end
    
    properties (Hidden)
        % variables to determin how many channels the protocol has
        channels = 1;
        selectedChannel = 1         % The channel selected within the protocol
    end
    
    properties (Dependent = true, SetAccess = private) % these properties are inherited - i.e., not modifiable
        % ampOfLastStep;  
    end
    
    methods
        function obj = OneChannelLEDTest(rigConfig)
            obj = obj@LEDFamily(rigConfig);
        end
    end
end