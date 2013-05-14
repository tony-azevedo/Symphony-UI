function StartSymphony()

    if verLessThan('matlab', '7.12')
        error('Symphony requires MATLAB 7.12.0 (R2011a) or later');
    end

    % Add base directories to the path.
    symphonyPath = mfilename('fullpath');
    parentDir = fileparts(symphonyPath);
    addpath(fullfile(parentDir, 'Dependencies'));
    addpath(fullfile(parentDir, 'Simulations'));
    addpath(fullfile(parentDir, 'Utilities'));
    addpath(fullfile(parentDir, 'StimGL'));

    % Load the Symphony .NET framework.
    addSymphonyFramework();

    % Declare or retrieve the current Symphony instance.
    persistent symphonyInstance;

    if isempty(symphonyInstance) || ~isvalid(symphonyInstance)
        config = SymphonyConfiguration();
        
        % Run the built-in configuration function.
        config = symphonyrc(config);

        % Run the user-specific configuration function.
        up = userpath;
        up = regexprep(up, '[;:]$', ''); % Remove semicolon/colon at end of user path
        if exist(fullfile(up, 'symphonyrc.m'), 'file')
            rc = funcAtPath('symphonyrc', up);
            config = rc(config);
        end

        % Create the Symphony instance
        symphonyInstance = SymphonyUI(config);
    else
        symphonyInstance.showMainWindow();
    end
end