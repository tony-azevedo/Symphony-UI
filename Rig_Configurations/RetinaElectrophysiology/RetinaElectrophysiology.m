%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html
%
% Modified 27-Aug-2012 TWA to create new Color Rig

classdef RetinaElectrophysiology < RigConfiguration
    
    properties (Constant)
        displayName = 'Retina Electrophysiology'
    end
    
    properties
        maxVoltage = 10;
        minVoltage = 0;
    end
    
    methods (Static)
        function solutionControllerChange( ~ , eventData )
            h = eventData.AffectedObject;
            if(~strcmp(h.deviceStatus,''))
                h.updateGUI();
            end
        end           
    end
    
    methods
        
        % Initializing a superclass from a subclass requires the subclass
        % to handle the input variables
        function rc = RetinaElectrophysiology(varargin)
            if nargin == 1
                allowMultiClampDevices = varargin{1};
            else
                allowMultiClampDevices = 1; 
            end
            rc = rc@RigConfiguration(allowMultiClampDevices);
        end
        
        function createDevices(obj)
            obj.addMultiClampDevice('Amplifier_Ch1', 1, 'ANALOG_OUT.0', 'ANALOG_IN.0');
            
            obj.addDevice('Ch1', 'ANALOG_OUT.1', '');   % output only
            obj.addDevice('Ch2', 'ANALOG_OUT.2', '');   % output only
            obj.addDevice('Ch3', 'ANALOG_OUT.3', '');   % output only
            
            obj.addDevice('Ch1AORB', 'DIGITAL_OUT.1', '');   % output only
            obj.addDevice('Ch2AORB', 'DIGITAL_OUT.1', '');   % output only
            obj.addDevice('Ch3AORB', 'DIGITAL_OUT.1', '');   % output only
            
            obj.addDevice('HeatSync', '', 'ANALOG_IN.2');   % input only
            
            obj.addCustomDevice('SolutionController','SolutionController', {{'port',7} , {'channels',5}});
            
            changeFunctionHandle =  @( metaProp , eventData )obj.solutionControllerChange( metaProp , eventData );
            % obj.addCustomDeviceListener('SolutionController', 'deviceStatus', 'PostSet', changeFunctionHandle);
        end 
    end
end