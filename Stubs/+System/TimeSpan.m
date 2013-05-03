classdef TimeSpan
    
    properties (SetAccess = private)
        Ticks
    end
    
    properties (Dependent, SetAccess = private)
        TotalSeconds
    end
    
    methods
        
        function obj = TimeSpan(ticks)
            obj.Ticks = ticks;
        end
        
        
        function s = get.TotalSeconds(obj)
            s = obj.Ticks * 100e-9;
        end
        
        %% Operators
        
        function r = minus(a, b)
            r = System.TimeSpan(a.Ticks - b.Ticks);
        end
        
        
        function r = ne(a, b)
            r = a.Ticks ~= b.Ticks;
        end
        
        
        function r = plus(a, b)
            r = System.TimeSpan(a.Ticks + b.Ticks);            
        end
        
        
        function r = lt(a, b)
            r = a.Ticks < b.Ticks;
        end
        
        
        function r = le(a, b)
            r = a.Ticks <= b.Ticks;
        end
        
        
        function r = eq(a, b)
            r = a.Ticks == b.Ticks;
        end
        
        
        function r = gt(a, b)
            r = a.Ticks > b.Ticks;
        end
        
        
        function r = ge(a, b)
            r = a.Ticks >= b.Ticks;
        end
        
    end
    
    methods (Static)
        
        function obj = Zero()
            obj = System.TimeSpan(0);
        end
        
        
        function obj = FromSeconds(secs)
            obj = System.TimeSpan(secs / 100e-9);
        end
        
    end
    
end

