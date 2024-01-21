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
    maxPrecipitationChange = 2.5; % mm/h
    maxVisibilityChange = 1; % km

    maxSurfaceTempChange = 1; % degrees Celsius
    maxMoistureChange = 0.25; % percentage points
    maxIcingChange = 0.1; % cm
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
        
        if roadSurfaceData.surfaceTemperature(i) < 0
            roadSurfaceData.icing(i) = adjustWithinRange(roadSurfaceData.icing(i), maxIcingChange, 0, 2);
        else
            % FIXME: this formula is wrong, shall be replaced
            k2 = max(0, min(5, normrnd(1,3))) * 0.001; 
            moistureChange = exp(-k2 * (roadSurfaceData.surfaceTemperature(i) + environmentalData.windSpeed(i) * 0.01));
            roadSurfaceData.moisture(i) = adjustWithinRange(roadSurfaceData.moisture(i), moistureChange, 0, 30); 
            % FIXME: At >30 temps, the moisture is still present
            
            % TODO: simplified model approach that tries to capture some real-world dynamics
            % Factors:
            % - Rainfall rate (R)
            % - Temperature (T)
            % - Road porosity (Pr)
            % - Drainage rate (Dr)
            % 
            % Equations:
            % Moisture Gain Rate = k1 * R * (1 - e^(-k2*T))
            % Moisture Loss Rate = Dr * Current_Moisture
            % 
            % Calculation:
            % - Calculate moisture gain rate based on rainfall, temp
            % - Reduce gain if temp is low
            % - Calculate moisture loss rate via drainage
            % - Integrate moisture over time based on gain - loss
            % 
            % Extend model to include:
            % - Evaporation effects
            % - Surface runoff direction
            % - Groundwater table effects
            % - Frozen ground inhibition of drainage
            % - Spatial variability based on road materials
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
