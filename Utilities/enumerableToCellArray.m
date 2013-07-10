% Determines whether a .NET generic enumerable sequence contains any elements.

function c = enumerableToCellArray(e, type)
    a = NET.invokeGenericMethod('System.Linq.Enumerable', 'ToArray', {type}, e);
    
    c = cell(1, a.Length);
    for i=1:a.Length
        c{i} = a.GetValue(i-1);
    end
end