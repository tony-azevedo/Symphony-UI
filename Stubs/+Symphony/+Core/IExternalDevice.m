classdef IExternalDevice < Symphony.Core.ITimelineProducer
   
    properties (Abstract)
        Name
        Controller
        Background
        Streams
        Manufacturer
    end
    
    methods (Abstract)
        device = BindStream(obj, arg1, arg2);
    end
end