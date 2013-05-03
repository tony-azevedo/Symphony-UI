classdef List < handle
   
    properties (SetAccess = private)
        Count
    end
    
    properties (Access = private)     
        Items
        ItemCount
    end
    
    methods
        
        function obj = List(capacity)            
            if nargin == 0
                capacity = 10;
            end
            
            obj.Items = cell(1, capacity);
            obj.ItemCount = 0;
        end
        
        
        function Add(obj, item)
            obj.ItemCount = obj.ItemCount + 1;
            obj.Items{obj.ItemCount} = item;
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
                obj.Items{index + 1} = value;
            end
            
            i = obj.Items{index + 1};   % index is zero based
        end
        
        
        function c = get.Count(obj)
            c = obj.ItemCount;
        end
        
        
        function l = Concat(obj, other)
            l = System.Collections.Generic.List(obj.ItemCount + other.ItemCount);
            l.Items = [obj.Items(1:obj.ItemCount) other.Items];
            l.ItemCount = obj.ItemCount + other.ItemCount;
        end
        
        
        function l = Take(obj, itemCount)
            l = System.Collections.Generic.List(itemCount);
            l.Items = obj.Items(1:itemCount);
            l.ItemCount = itemCount;
        end
        
        
        function l = Skip(obj, itemCount)
            l = System.Collections.Generic.List(obj.ItemCount - itemCount);
            l.Items = obj.Items(itemCount+1:end);
        end
        
        
        function i = IndexOf(obj, item)
            i = find(cellfun(@(c)isequal(c, item), obj.Items), 1, 'first');
            
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
                
                if enum.State + 1 > obj.ItemCount
                    b = false;
                    return;
                end
                
                enum.Current = obj.Items{enum.State + 1};
                enum.State = enum.State + 1;
                b = true;
            end
        end
        
    end
    
end