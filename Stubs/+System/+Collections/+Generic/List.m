classdef List < handle
   
    properties (SetAccess = private)
        Count
    end
    
    properties       
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
        
        
        function i = Item(obj, index, value)
            if index < 0 || index >= obj.itemCount
                error('Out of range')
            end
            
            if nargin > 2
                obj.items{index + 1} = value;
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
        
        
        function i = IndexOf(obj, item)
            i = find(cellfun(@(c)isequal(c, item), obj.items), 1, 'first');
            
            if isempty(i)
                i = -1;
            else
                i = i - 1;  % index is zero based
            end
        end
        
        
        function b = Contains(obj, item)
            b = obj.IndexOf(item) ~= -1;
        end
        
        
        function enum = GetEnumerator(obj)
            enum = System.Collections.Generic.Enumerator(@MoveNext);
            enum.State = 0;
            
            function b = MoveNext()
                enum.Current = [];
                
                if enum.State + 1 > obj.itemCount
                    b = false;
                    return;
                end
                
                enum.Current = obj.items{enum.State + 1};
                enum.State = enum.State + 1;
                b = true;
            end
        end
        
    end
    
end