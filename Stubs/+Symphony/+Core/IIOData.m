classdef IIOData < handle
   
    properties (Abstract)
        Data                     % GenericList
        SampleRate               % Measurement
        Duration
    end
    
end