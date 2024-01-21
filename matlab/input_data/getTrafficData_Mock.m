function [RsuData] = getTrafficData_Mock(numSegments, numLanes, ...
    trafficData, environmentalData, roadSurfaceData, speedBounds)
    % This function slightly adjusts traffic, environmental, and road surface data
    % to simulate dynamic changes over time (cycles).

    % Define maximum change per cycle
    maxSpeedChange = 1; % km/h
    maxFlowChange = 2; % vehicles
    maxDensityChange = 1; % percentage points

    maxTempChange = 1; % degrees Celsius
    maxWindChange = 1; % km/h
    maxHumidityChange = 1; % percentage points
    maxPrecipitationChange = 2; % mm/h
    maxVisibilityChange = 1; % km

    maxSurfaceTempChange = 1; % degrees Celsius
    maxMoistureChange = 2; % percentage points
    maxIcingChange = 0.05; % cm
    maxSalinityChange = 0.01; % g/L

    % Adjust traffic data
    for i = 1:numSegments
        for j = 1:numLanes
            ix = uint32(i); jx = uint32(j);
            trafficData.speed(ix, jx) = adjustWithinRange(trafficData.speed(ix, jx), maxSpeedChange, 0, speedBounds.maxSpeed(ix, jx));
            trafficData.flow(ix, jx) = adjustWithinRange(trafficData.flow(ix, jx), maxFlowChange, 0, 2600);
            trafficData.density(ix, jx) = adjustWithinRange(trafficData.density(ix, jx), maxDensityChange, 0, 40);
        end
    end

    % Adjust environmental data
    for i = 1:numSegments
        environmentalData.temperature(i) = adjustWithinRange(environmentalData.temperature(i), maxTempChange, -20, 50);
        environmentalData.windSpeed(i) = adjustWithinRange(environmentalData.windSpeed(i), maxWindChange, 0, 100);
        environmentalData.humidity(i) = adjustWithinRange(environmentalData.humidity(i), maxHumidityChange, 0, 100);
        environmentalData.precipitation(i) = adjustWithinRange(environmentalData.precipitation(i), maxPrecipitationChange, 0, 100);
        environmentalData.visibility(i) = adjustWithinRange(environmentalData.visibility(i), maxVisibilityChange, 0, 10);
    end

    % Adjust road surface data
    for i = 1:numSegments
        roadSurfaceData.surfaceTemperature(i) = adjustWithinRange(roadSurfaceData.surfaceTemperature(i), maxSurfaceTempChange, -30, 60);
        roadSurfaceData.moisture(i) = adjustWithinRange(roadSurfaceData.moisture(i), maxMoistureChange, 0, 100);
        if roadSurfaceData.surfaceTemperature(i) < 0
            roadSurfaceData.icing(i) = adjustWithinRange(roadSurfaceData.icing(i), maxIcingChange, 0, 100);
        end
        roadSurfaceData.salinity(i) = adjustWithinRange(roadSurfaceData.salinity(i), maxSalinityChange, 0, 100);
    end

    RsuData.traffic = trafficData;
    RsuData.environmental = environmentalData;
    RsuData.roadSurface = roadSurfaceData;
end

function newValue = adjustWithinRange(value, maxChange, minLimit, maxLimit)
    % Randomly adjust the value within the specified range
    change = maxChange * (2 * rand - 1); % Change can be positive or negative
    newValue = value + change;
    % Ensure the new value is within limits
    newValue = min(max(newValue, minLimit), maxLimit);
end
