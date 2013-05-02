function obj = createGeneric(className, ~, varargin)
    constructor = str2func(className);
    
    obj = constructor(varargin{:});
end