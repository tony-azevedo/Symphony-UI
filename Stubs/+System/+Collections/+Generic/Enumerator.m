% This class does not exist in the .NET framework (as implemented). It's a convenience to avoid writing
% IEnumerator implementing classes.

classdef Enumerator < handle
    
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

