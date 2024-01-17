% The function won't report any error at this point - assuming the init
% will be successful 
function [densityRange, speedRange] = initSensorData_Mock(numSegments, numLanes, sensorData)
    % Traffic density (vehicles per km per lane)
    densityRange = [20, 100]; % Minimum and maximum density
    sensorData.density = randi(densityRange, numSegments, numLanes);
    
    % Speed (km/h per lane)
    speedRange = [40, 120]; % Minimum and maximum speed
    sensorData.speed = randi(speedRange, numSegments, numLanes);
    
    % Environmental conditions (arbitrary scale 0 to 10)
    sensorData.environment = rand(numSegments, 1) * 10;
end