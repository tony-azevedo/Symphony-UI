function obj = createGeneric(className, paramTypes, varargin) %#ok<INUSL>
    constructor = str2func(className);
    obj = constructor(varargin{:});
end