% File: calculate_energy_change.m
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
% This function calculates the net change in energy stored in the battery,
% given the discharge rate, temperature, initial voltage, and final voltage.
%
% Inputs:
%   discharge_rate: The discharge rate coefficient (0.2 to 2)
%   temperature: The temperature in units of degC (-20 degC to +40)
%   initial_voltage: The initial voltage of the battery
%   final_voltage: The final voltage of the battery
%   pack_config: Optional argument for specifying the battery pack configuration (e.g., '1s2p', '3s4p')
%
% Returns:
%   energy_change: The net change in energy stored in the battery (in units of Wh)
%
% Example usage:
%   discharge_rate = 1.5;  % Desired discharge rate
%   temperature = 10;  % Desired temperature in degC
%   initial_voltage = 3.7;  % Initial voltage of the battery
%   final_voltage = 3.3;  % Final voltage of the battery
%   pack_config = '1s2p';  % Battery pack configuration
%
%   energy_change = calculate_energy_change(discharge_rate, temperature, initial_voltage, final_voltage, pack_config);
function energy_change = calculate_energy_change(discharge_rate, temperature, initial_voltage, final_voltage, varargin)

    % Check if battery pack configuration is provided
    if ~isempty(varargin)
        pack_config = varargin{1};
        % Parse the battery pack configuration
        [series, parallel] = parse_battery_pack_config(pack_config);
        
        % Adjust initial and final voltages based on the series value
        initial_voltage = initial_voltage / series;
        final_voltage = final_voltage / series;
    else
        parallel = 1;  % Default parallel value
    end

    % Interpolate the discharge curve for the given temperature and discharge rate coefficient
    interpolated_curve = interpolate_discharge_curve(discharge_rate, temperature);

    % Find the corresponding discharged capacity for the initial and final voltages
    initial_discharged_capacity = find_discharged_capacity(interpolated_curve, initial_voltage);
    final_discharged_capacity = find_discharged_capacity(interpolated_curve, final_voltage);

    conversion_factor = 1 / 1000; % Conversion factor from mAh to Ah
    
    initial_energy = initial_discharged_capacity * parallel * initial_voltage * conversion_factor;
    final_energy = final_discharged_capacity * parallel * final_voltage * conversion_factor;
    energy_change = final_energy - initial_energy;
    
end


% This function parses the battery pack configuration string and extracts the values for series and parallel.
%
% Inputs:
%   pack_config: The battery pack configuration string (e.g., '1s2p', '3s4p')
%
% Returns:
%   series: The value for the series configuration
%   parallel: The value for the parallel configuration
%
% Example usage:
%   pack_config = '1s2p';  % Battery pack configuration
%   [series, parallel] = parse_battery_pack_config(pack_config);
function [series, parallel] = parse_battery_pack_config(pack_config)
    pattern = '(\d+)s(\d+)p';  % Regular expression pattern
    
    % Match the pattern in the battery pack configuration string
    matches = regexp(pack_config, pattern, 'tokens');
    
    if isempty(matches)
        error('Invalid battery pack configuration. Please provide a valid configuration (e.g., "2s2p").');
    end
    
    series = str2double(matches{1}{1});
    parallel = str2double(matches{1}{2});
end


% This function finds the discharged capacity corresponding to a given
% voltage in a discharge curve. If the discharge curve is not monotonic, it
% ignores the portion of the curve before the maximum voltage.
%
% Inputs:
%   discharge_curve: The discharge curve as a table with 'Discharged_Capacity_mAh' and 'Voltage_V' columns
%   voltage: The voltage for which to find the discharged capacity
%
% Returns:
%   discharged_capacity: The discharged capacity corresponding to the given voltage
%
% Example usage:
%   discharge_curve = interpolate_discharge_curve(discharge_rate, temperature);  % The discharge curve
%   voltage = 3.5;  % The voltage for which to find the discharged capacity
%
%   discharged_capacity = find_discharged_capacity(discharge_curve, voltage);
function discharged_capacity = find_discharged_capacity(discharge_curve, voltage)
    
    voltage_values = discharge_curve.Voltage_V;
    discharged_capacity_values = discharge_curve.Discharged_Capacity_mAh;
    
    % Check if the voltage input is within the range of voltage values
    if voltage < min(voltage_values) || voltage > max(voltage_values)
        error('Invalid voltage value. Please provide a voltage within the range of the discharge curve.');
    end
    
    % Find the index of the maximum voltage value
    [~, max_index] = max(voltage_values);

    % Find the index of the voltage value that is closest to the given voltage
    % If the discharge curve is not monotonic, ignore the portion of the curve before
    % the maximum voltage value
    [~, matching_index] = min(abs(voltage_values(max_index:length(voltage_values)) - voltage));

    discharged_capacity = discharged_capacity_values(matching_index);
end