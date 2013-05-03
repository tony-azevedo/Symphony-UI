% This class does not exist in the .NET framework. It's a convenience to avoid writing
% IEnumerable implementing classes.

classdef Enumerable < handle
    
    properties (Access = private)
        getEnumeratorFunc
    end
    
    methods
        
        function obj = Enumerable(getEnumeratorFunc)
            obj.getEnumeratorFunc = getEnumeratorFunc;
        end
        
        
        function e = GetEnumerator(obj)
            e = obj.getEnumeratorFunc();
        end
        
    end
    
end

