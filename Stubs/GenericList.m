classdef GenericList < handle
   
    properties
        Items
        itemCount
    end
    
    methods
        
        function obj = GenericList(capacity)
            obj = obj@handle();
            
            if nargin == 0
                capacity = 10;
            end
            
            obj.Items = cell(1, capacity);
            obj.itemCount = 0;
        end
        
        
        function Add(obj, item)
            obj.itemCount = obj.itemCount + 1;
            obj.Items{obj.itemCount} = item;
        end
        
        
        function AddRange(obj, list)
            obj.Items = [obj.Items(1:obj.itemCount) list.Items(1:list.itemCount)];
            obj.itemCount = obj.itemCount + list.itemCount;
        end
        
        
        function i = Item(obj, index)
            if index < 0 || index >= obj.itemCount
                error('Out of range')
            end
            
            i = obj.Items{index + 1};   % index is zero based
        end
        
        
        function c = Count(obj)
            c = obj.itemCount;
        end
        
        
        function l = Concat(obj, other)
            l = GenericList(obj.Count + other.Count);
            l.AddRange(obj);
            l.AddRange(other);
        end
        
        
        function l = Take(obj, count)
            l = GenericList(count);
            l.Items = obj.Items(1:count);
            l.itemCount = count;
        end
        
        
        function l = Skip(obj, count)
            l = GenericList(obj.Count - count);
            l.Items = obj.Items(count+1:end);
        end
        
    end
    
end