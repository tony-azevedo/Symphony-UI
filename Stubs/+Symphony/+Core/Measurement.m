classdef Measurement < handle
   
    properties (SetAccess = private)
        Quantity
        Exponent
        BaseUnit
    end
    
    properties (Dependent, SetAccess = private)
        DisplayUnit
    end
    
    properties (Constant)
        UNITLESS = '';
    end
    
    properties (Constant, Access = private)
        BaseUnits = {'Y', 'Z', 'E', 'P', 'T', 'G', 'M', 'k', 'h', 'da', 'd', 'c', 'm', 'µ', 'n', 'p', 'f', 'a', 'z', 'y', ''};
        BaseExps = [24, 21, 18, 15, 12, 9, 6, 3, 2, 1, -1, -2, -3, -6, -9, -12, -15, -18, -21, -24, 0];
    end
        
    methods
        
        function obj = Measurement(quantity, arg1, arg2)
            obj = obj@handle();
            
            obj.Quantity = quantity;

            if nargin == 2
                % e.g. Measurement(10, 'mV')
                [obj.BaseUnit, obj.Exponent] = splitUnit(arg1);
            elseif nargin == 3
                % e.g. Measurement(10, -3, 'V')
                if ~ismember(arg1, Symphony.Core.Measurement.BaseExps)
                    error('Symphony:Core:Measurement', 'Unknown measurement exponent: %d', arg1);
                end
                obj.Exponent = arg1;
                obj.BaseUnit = arg2;
            end
        end
        
        
        function q = QuantityInBaseUnit(obj)
            q = obj.Quantity * 10 ^ obj.Exponent;
        end
        
        
        function du = get.DisplayUnit(obj)
            expInd = Symphony.Core.Measurement.BaseExps == obj.Exponent;
            du = [Symphony.Core.Measurement.BaseUnits{expInd} obj.BaseUnit];
        end
        
    end
    
    
    methods (Static)
        
        function m = FromArray(array, unit)
            m = NET.createGeneric('System.Collections.Generic.List', {'Symphony.Core.Measurement'}, length(array));
            for i=1:length(array)
                m.Add(Symphony.Core.Measurement(array(i), unit));
            end
        end
        
        
        function a = ToQuantityArray(list)
            a = zeros(1, list.Count);
            for i = 1:list.Count
                a(i) = list.Item(i-1).Quantity;
            end
        end
        
        
        function u = HomogenousBaseUnits(list)
            u = list.Item(0).BaseUnit;
        end
        
        
        function u = HomogenousDisplayUnits(list)
            u = list.Item(0).DisplayUnit;
        end
        
    end
    
end


function [u, e] = splitUnit(unitString)
    if length(unitString) < 2
        u = unitString;
        e = 0;
        return
    end
    
    for i = 1:length(Symphony.Core.Measurement.BaseUnits)
        baseUnit = Symphony.Core.Measurement.BaseUnits{i};
        if strncmp(unitString, baseUnit, length(baseUnit)) && length(unitString) > length(baseUnit)
            u = unitString(length(baseUnit) + 1:end);
            e = Symphony.Core.Measurement.BaseExps(i);
            return
        end
    end
    
    error('Symphony:Core:Measurement', 'Unknown measurement units %s', unitString);
end
