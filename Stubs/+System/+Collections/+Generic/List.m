% Use ArrayList if performance is not critical (e.g. you're not adding a large number of elements).

classdef List < handle
   
    properties
        Items   % Exposing because calling the Add method in a for loop is slow.
        ItemCount
    end
    
    properties (SetAccess = private)
        Count
    end
    
    properties (Access = private)
        Type
    end
    
    methods
        
        function obj = List(type, capacity)            
            if nargin < 2
                capacity = 10;
            end
            
            % Preallocate
            type = type{1};
            constructor = str2func(type);
            if capacity > 0
                items(1, capacity) = constructor();
            else
                items(1, 1) = constructor();
            end
            
            obj.Type = type;
            obj.Items = items;
            obj.ItemCount = 0;
        end
        
        
        function Add(obj, item)
            obj.ItemCount = obj.ItemCount + 1;
            obj.Items(obj.ItemCount) = item;
        end
        
        
        function AddRange(obj, list)
            obj.Items = [obj.Items(1:obj.ItemCount) list.Items];
            obj.ItemCount = obj.ItemCount + list.ItemCount;
        end
        
        
        function i = Item(obj, index, value)
            if index < 0 || index >= obj.ItemCount
                error('Out of range')
            end
            
            if nargin > 2
                obj.Items(index + 1) = value;
            end
            
            i = obj.Items(index + 1);   % index is zero based
        end
        
        
        function c = get.Count(obj)
            c = obj.ItemCount;
        end
        
        
        function l = Concat(obj, other)
            l = NET.createGeneric(class(obj), {obj.Type}, obj.ItemCount + other.ItemCount);
            l.Items = [obj.Items(1:obj.ItemCount) other.Items];
            l.ItemCount = obj.ItemCount + other.ItemCount;
        end
        
        
        function l = Take(obj, count)
            % Preallocating appears to slow things down.
            %l = NET.createGeneric(class(obj), {obj.Type}, count);
            l = NET.createGeneric(class(obj), {obj.Type});
            l.Items = obj.Items(1:count);
            l.ItemCount = count;
        end
        
        
        function l = Skip(obj, count)
            % Preallocating appears to slow things down.
            %l = NET.createGeneric(class(obj), {obj.Type}, obj.ItemCount - count);            
            l = NET.createGeneric(class(obj), {obj.Type});
            l.Items = obj.Items(count+1:end);
            l.ItemCount = obj.ItemCount - count;
        end
        
        
        function i = IndexOf(obj, item)
            i = -1;
            
            for index = 1:obj.ItemCount
                if isequal(obj.Items(index), item)
                    i = index - 1; % index is zero based
                    break;
                end
            end
        end
        
        
        function b = Contains(obj, item)
            b = obj.IndexOf(item) ~= -1;
        end
        
        
        function enum = GetEnumerator(obj)
            enum = Enumerator(@MoveNext);
            enum.State = 0;
            
            function b = MoveNext()
                enum.Current = [];
                
                if enum.State + 1 > obj.ItemCount
                    b = false;
                    return;
                end
                
                enum.Current = obj.Items(enum.State + 1);
                enum.State = enum.State + 1;
                b = true;
            end
        end
        
    end
    
end