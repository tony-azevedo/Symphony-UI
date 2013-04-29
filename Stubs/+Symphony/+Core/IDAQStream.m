classdef IDAQStream < Symphony.Core.ITimelineProducer
   
    properties (Abstract)
        Configuration
        Name
        SampleRate
        Active
        MeasurementConversionTarget
    end

end