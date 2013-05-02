classdef Enumerator < handle
    % HACK: This class does not accurately represent the one in .NET. It is designed to avoid writing 
    % a bunch of separate enumerator classes because MATLAB has no concept of nested types.
    
    properties
        Current
        State
    end
    
    properties (Access = private)
        moveNextFunc
    end
    
    methods
        
        function obj = Enumerator(moveNextFunc)
            obj.moveNextFunc = moveNextFunc;
        end
        
        
        function b = MoveNext(obj)
            b = obj.moveNextFunc();
        end

    end
    
end

