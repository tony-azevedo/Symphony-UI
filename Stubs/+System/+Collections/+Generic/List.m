classdef List < handle
   
    properties (SetAccess = private)
        Count
    end
    
    properties (Access = private)       
        items
        itemCount
    end
    
    methods
        
        function obj = List(capacity)            
            if nargin == 0
                capacity = 10;
            end
            
            obj.items = cell(1, capacity);
            obj.itemCount = 0;
        end
        
        
        function Add(obj, item)
            obj.itemCount = obj.itemCount + 1;
            obj.items{obj.itemCount} = item;
        end
        
        
        function AddRange(obj, list)
            obj.items = [obj.items(1:obj.itemCount) list.items];
            obj.itemCount = obj.itemCount + list.itemCount;
        end
        
        
        function i = Item(obj, index)
            if index < 0 || index >= obj.itemCount
                error('Out of range')
            end
            
            i = obj.items{index + 1};   % index is zero based
        end
        
        
        function c = get.Count(obj)
            c = obj.itemCount;
        end
        
        
        function l = Concat(obj, other)
            l = System.Collections.Generic.List(obj.itemCount + other.itemCount);
            l.items = [obj.items(1:obj.itemCount) other.items];
            l.itemCount = obj.itemCount + other.itemCount;
        end
        
        
        function l = Take(obj, itemCount)
            l = System.Collections.Generic.List(itemCount);
            l.items = obj.items(1:itemCount);
            l.itemCount = itemCount;
        end
        
        
        function l = Skip(obj, itemCount)
            l = System.Collections.Generic.List(obj.itemCount - itemCount);
            l.items = obj.items(itemCount+1:end);
        end
        
    end
    
end