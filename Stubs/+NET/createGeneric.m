%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function obj = createGeneric(className, paramTypes, varargin)
    if strcmp(className, 'System.Collections.Generic.Dictionary')
        obj = GenericDictionary();
    elseif strcmp(className, 'System.Collections.Generic.List')
        obj = GenericList(varargin{:});
    else
        error('Unknown generic type ''%s''', className);
    end
end
