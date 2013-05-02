classdef IIOData < handle
   
    properties (Abstract)
        Data                     % List
        SampleRate               % Measurement
        Duration
    end
    
end