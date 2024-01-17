% This function will retrieve the local data from an external storage
% Locally stored conditions
% - Traffic conditions, including current and forecasted traffic information
% - Road surface and Environmental conditions
% - Traffic incident information
% - Information on diversions and alternate routes
% - Closures
% - Special traffic restrictions (lane/shoulder use, weight restrictions, width restrictions, HOV requirements)
% - The definition of the road network itself

% FIXME: The function's output is not the same as the requirements. To be refactored in the future
% TODO: Add implementation to this function. Currently it is a mock fnc
function [densityRange, speedRange] = initLocalData(numSegments, numLanes, localData)
    % Traffic density (vehicles per km per lane)
    densityRange = [20, 100]; % Minimum and maximum density
    localData.density = randi(densityRange, numSegments, numLanes);
    
    % Speed (km/h per lane)
    speedRange = [40, 120]; % Minimum and maximum speed
    localData.speed = randi(speedRange, numSegments, numLanes);
    
    % Environmental conditions (arbitrary scale 0 to 10)
    localData.environment = rand(numSegments, 1) * 10;
end