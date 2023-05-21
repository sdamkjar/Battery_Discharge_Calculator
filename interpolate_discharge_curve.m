% File: interpolate_discharge_curve.m
% Date: 19-May-2023
% Author: Stefan Damkjar
%
% Copyright 2023 Stefan Damkjar
% 
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
% 
%     http://www.apache.org/licenses/LICENSE-2.0
% 
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%
%
% This function accepts a discharge rate and a temperature as inputs and
% creates a new discharge curve by interpolating between the available
% curves based on the inputs.
%
% Inputs:
%   discharge_rate: The discharge rate coefficient (0.2 to 2)
%   temperature: The temperature in units of degC (-20 degC to +40)
% 
% Returns:
%   Interpolated discharge curve as a table with 'Discharged_Capacity_mAh'
%   and 'Voltage_V' columns.
%
% Example usage:
%   discharge_rate = 1.5;  % Desired discharge rate
%   temperature = 10;  % Desired temperature in degC
% 
%   % Interpolate the discharge curve for the given rate and temperature
%   interpolated_curve = interpolate_discharge_curve(discharge_rate, temperature);
% 
%   % Plot the interpolated discharge curve
%   plot(interpolated_curve.Discharged_Capacity_mAh, interpolated_curve.Voltage_V);
%   xlabel('Discharged Capacity (mAh)');
%   ylabel('Voltage (V)');
%   title('Interpolated Discharge Curve');
function interpolated_curve = interpolate_discharge_curve(discharge_rate, temperature)

    % Load the discharge curves data
    curves = load('dischargeCurves.mat');
        
    % Get the baseline curve at 1C and 25degC
    baseline_curve = curves.curve_1C_25degC.Voltage_V;

    % Interpolate the curve based on temperature
    curve_from_temperature = interpolate_discharge_curve_from_temperature(temperature);

    % Interpolate the curve based on discharge rate
    curve_from_discharge_rate = interpolate_discharge_curve_from_discharge_rate(discharge_rate);

    % Compute scaling factors based on temperature and discharge rate curves
    temperature_scaling_factor = curve_from_temperature.Voltage_V ./ baseline_curve;
    discharge_rate_scaling_factor = curve_from_discharge_rate.Voltage_V ./ baseline_curve;

    % Compute the interpolated voltage curve by applying scaling factors
    interpolated_voltage = baseline_curve .* temperature_scaling_factor;
    interpolated_voltage = interpolated_voltage .* discharge_rate_scaling_factor;

    % Create the interpolated curve table
    interpolated_curve = table(0:0.01:3200, interpolated_voltage, 'VariableNames', {'Discharged_Capacity_mAh', 'Voltage_V'});
end

% This function accepts a discharge rate coefficient as an input and
%     creates a new discharge curve by interpolating between the available
%     curves. The discharge rate coefficient is a unit-less value that gets
%     multiplied by the battery capacity.
%
% Inputs:
%   discharge_rate: The discharge rate coefficient (0.2 to 2)
% 
% Returns:
%   Interpolated discharge curve as a table with 'Discharged_Capacity_mAh'
%       and 'Voltage_V' columns.
%
% Example usage:
%   discharge_rate = 1.5;  % Desired discharge rate

% 
%   % Interpolate the discharge curve for the given rate
%   interpolated_curve = interpolate_discharge_curve_from_discharge_rate(discharge_rate);
% 
%   % Plot the interpolated discharge curve
%   plot(interpolated_curve.Discharged_Capacity_mAh, interpolated_curve.Voltage_V);
%   xlabel('Discharged Capacity (mAh)');
%   ylabel('Voltage (V)');
%   title('Interpolated Discharge Curve');
function interpolated_curve = interpolate_discharge_curve_from_discharge_rate(discharge_rate)
    % Available discharge curves
    curves = load('dischargeCurves.mat');
    
    curves = [curves.curve_0_2C_25degC.Voltage_V', curves.curve_0_5C_25degC.Voltage_V', curves.curve_1C_25degC.Voltage_V', curves.curve_2C_25degC.Voltage_V'];

    % Discharge rates corresponding to given curves
    discharge_rates = [0.2, 0.5, 1, 2];
    
    % Check if discharge_rate is within the valid range
    if discharge_rate < min(discharge_rates) || discharge_rate > max(discharge_rates)
        error('Invalid discharge rate coefficient. Please provide a discharge rate coefficient between 0.2 and 2 (inclusive).');
    end

    % Find the discharge rate with data to the given rate
    [~, index] = min(abs(discharge_rates - discharge_rate));

    if discharge_rate == discharge_rates(index)
        % If the given rate matches one of the given rates exactly,
        % return the corresponding curve
        interpolated_voltage = curves(:, index);
        
    else
        % If the given rate lies between two given rates,
        % interpolate the curve using linear interpolation
        if discharge_rate > discharge_rates(index)
            lower_curve = curves(:, index - 1);
            upper_curve = curves(:, index);
        else
            lower_curve = curves(:, index);
            upper_curve = curves(:, index + 1);
        end
        
        % Compute interpolation factor
        interpolation_factor = (discharge_rate - discharge_rates(index)) / (discharge_rates(index + 1) - discharge_rates(index));
        
        % Perform linear interpolation between the two curves
        interpolated_voltage = lower_curve + (upper_curve - lower_curve) * interpolation_factor;
        
    end
    interpolated_curve = table(0:0.01:3200, interpolated_voltage', 'VariableNames', {'Discharged_Capacity_mAh', 'Voltage_V'});
end


% This function accepts a temperature as an input and creates a new
%     discharge curve by interpolating between the available curves.
%
% Inputs:
%   temperature: The temperature in units of degC (-20 degC to +40 degC)
% 
% Returns:
%   Interpolated discharge curve as a table with 'Discharged_Capacity_mAh'
%       and 'Voltage_V' columns.
%
% Example usage:
%   temperature = 10;  % Desired temperature in degC
% 
%   % Interpolate the discharge curve for the given temperature
%   interpolated_curve = interpolate_discharge_curve_from_temperature(temperature);
% 
%   % Plot the interpolated discharge curve
%   plot(interpolated_curve.Discharged_Capacity_mAh, interpolated_curve.Voltage_V);
%   xlabel('Discharged Capacity (mAh)');
%   ylabel('Voltage (V)');
%   title('Interpolated Discharge Curve');
function interpolated_curve = interpolate_discharge_curve_from_temperature(temperature)
    % Available discharge curves
    curves = load('dischargeCurves.mat');
    
    curves = [curves.curve_1C_neg20degC.Voltage_V', curves.curve_1C_neg10degC.Voltage_V', curves.curve_1C_0degC.Voltage_V', curves.curve_1C_25degC.Voltage_V', curves.curve_1C_40degC.Voltage_V'];

    % Temperatures corresponding to given curves
    temperatures = [-20 -10 0 25 40];
    
    % Check if temperature is within the valid range
    if temperature < min(temperatures) || temperature > max(temperatures)
        error('Invalid temperature. Please provide a temperature between -20 degC and +40 degC (inclusive).');
    end

    % Find the nearest temperature with data to the given temperature
    [~, index] = min(abs(temperatures - temperature));

    if temperature == temperatures(index)
        % If the given rate matches one of the given rates exactly,
        % return the corresponding curve
        interpolated_voltage = curves(:, index);
        
    else
        % If the given rate lies between two given rates,
        % interpolate the curve using linear interpolation
        if temperature > temperatures(index)
            lower_curve = curves(:, index + 1);
            upper_curve = curves(:, index);
        else
            lower_curve = curves(:, index);
            upper_curve = curves(:, index - 1);
        end
        
        % Compute interpolation factor
        interpolation_factor = (temperature - temperatures(index)) / (temperatures(index + 1) - temperatures(index));
        
        % Perform linear interpolation between the two curves
        interpolated_voltage = lower_curve + (upper_curve - lower_curve) * interpolation_factor;
        
    end
    interpolated_curve = table(0:0.01:3200, interpolated_voltage', 'VariableNames', {'Discharged_Capacity_mAh', 'Voltage_V'});
end