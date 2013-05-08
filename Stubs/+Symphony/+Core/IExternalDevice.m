classdef IExternalDevice < Symphony.Core.ITimelineProducer
   
    properties (Abstract)
        Controller
        Background
        Name
        Manufacturer
    end
    
    properties (Abstract, SetAccess = private)
        Streams
    end
    
    methods (Abstract)
        device = BindStream(obj, arg1, arg2);
        outData = PullOutputData(obj, stream, duration);
        PushInputData(obj, stream, inData);
    end
end