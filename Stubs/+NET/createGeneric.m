function obj = createGeneric(className, paramTypes, varargin)
    if strcmp(className, 'System.Collections.Generic.Dictionary')
        obj = GenericDictionary();
    elseif strcmp(className, 'System.Collections.Generic.List')
        obj = GenericList(varargin{:});
    else
        error('Unknown generic type ''%s''', className);
    end
end
