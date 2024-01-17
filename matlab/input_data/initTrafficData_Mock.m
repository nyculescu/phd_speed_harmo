function [trafficData, environmentalData, roadSurfaceData] = initTrafficData_Mock(numSegments, numLanes)
    % This function generates mock data for traffic, environmental, and road surface conditions
    % with variability between road segments.

    % Constants for data ranges
    % Traffic Data
    maxSpeed = 130;             % Maximum speed in km/h
    maxVolume = 500;            % (Flow) Maximum volume of vehicles per hour per lane, peak flow
    maxOccupancy = 100;         % (Density) Maximum occupancy percentage, vehicles per km, jam density

    % Environmental Data
    minTemperature = -40;       % Minimum temperature in Celsius
    maxTemperature = 45;        % Maximum temperature in Celsius
    maxWindSpeed = 100;         % Maximum wind speed in km/h
    maxHumidity = 100;          % Maximum humidity percentage
    maxPrecipitation = 100;     % Maximum precipitation in mm/h
    maxVisibility = 10;         % Maximum visibility in km

    % Road Surface Data
    minSurfaceTemp = -30;       % Minimum surface temperature in Celsius
    maxSurfaceTemp = 60;        % Maximum surface temperature in Celsius
    maxMoistureLevel = 100;     % Maximum moisture level percentage
    maxIcing = 100;             % Maximum icing percentage
    maxSalinity = 70;           % Maximum salinity percentage

    % Initialize data structures
    trafficData = struct('speed', zeros(numSegments, numLanes), ...
                         'volume', zeros(numSegments, numLanes), ...
                         'occupancy', zeros(numSegments, numLanes));
    environmentalData = struct('temperature', zeros(numSegments, 1), ...
                               'windSpeed', zeros(numSegments, 1), ...
                               'humidity', zeros(numSegments, 1), ...
                               'precipitation', zeros(numSegments, 1), ...
                               'visibility', zeros(numSegments, 1));
    roadSurfaceData = struct('surfaceTemperature', zeros(numSegments, 1), ...
                             'moisture', zeros(numSegments, 1), ...
                             'icing', zeros(numSegments, 1), ...
                             'salinity', zeros(numSegments, 1));
    
    %% Generate mock data for the whole environment containing all the segments and lanes
    % Environmental Data
    baseTemperature = minTemperature + (maxTemperature - minTemperature) * rand;
    baseWindSpeed = maxWindSpeed * rand;
    baseHumidity = maxHumidity * rand;
    basePrecipitation = maxPrecipitation * rand;
    baseVisibility = maxVisibility * rand;
    % Road Surface Data
    baseSurfaceTemperature = minSurfaceTemp + (maxSurfaceTemp - minSurfaceTemp) * rand;
    baseMoisture = maxMoistureLevel * rand;
    baseIcing = maxIcing * rand;
    baseSalinity = maxSalinity * rand;

    % Generate base density (randomly between 0 and maxDensity)
    baseOccupancy = rand * maxOccupancy;

    %% Generate mock data for each segment and lane
    for i = 1:numSegments
        % Environmental Data
        environmentalData.temperature(i) = adjustWithinRange(baseTemperature, 0.25, minTemperature, maxTemperature);
        environmentalData.windSpeed(i) = adjustWithinRange(baseWindSpeed, 2, 0, maxWindSpeed);
        environmentalData.humidity(i) = adjustWithinRange(baseHumidity, 2, 0, maxHumidity);
        environmentalData.precipitation(i) = adjustWithinRange(basePrecipitation, 3, 0, maxPrecipitation);
        environmentalData.visibility(i) = adjustWithinRange(baseVisibility, 1, 0, maxVisibility); % FIXME: 0 means no visibility, so 0 is a maximum

        % Road Surface Data
        roadSurfaceData.surfaceTemperature(i) = adjustWithinRange(baseSurfaceTemperature, 1, minSurfaceTemp, maxSurfaceTemp);
        roadSurfaceData.moisture(i) = adjustWithinRange(baseMoisture, 2, 0, maxMoistureLevel);
        roadSurfaceData.icing(i) = adjustWithinRange(baseIcing, 2.5, 0, maxIcing);
        roadSurfaceData.salinity(i) = adjustWithinRange(baseSalinity, 1, 0, maxSalinity);

        % Initial values for the first lane in each segment
        baseSpeed = rand * maxSpeed * (0.8 + 0.2 * rand); % Random base speed for the first lane
        % baseVolume = rand * maxVolume * (0.8 + 0.2 * rand); % Random base volume for the first lane

        for j = 1:numLanes
            % Adjust values for each lane, ensuring lane 1 < lane 2 < lane 3
            laneDifferenceSpeed = 2 + 3 * rand; % 2 to 5 km/h difference
            % laneDifferenceVolume = 2 + 3 * rand; % Similar logic for volume
            laneDifferenceOccupancy = 1 + 4 * rand; % Similar logic for occupancy
            
            % Flow-Density Relationship (simplified piecewise linear model)
            if baseOccupancy <= maxOccupancy / 2
                trafficData.volume(i, j) = (maxVolume / (maxOccupancy / 2)) * baseOccupancy;
            else
                trafficData.volume(i, j) = maxVolume - (maxVolume / (maxOccupancy / 2)) * (baseOccupancy - maxOccupancy / 2);
            end

            % Speed-Density Relationship (linear model)
            trafficData.speed(i, j) = maxSpeed * (1 - (baseOccupancy / maxOccupancy));
            
            % Setting Volume and Occupancy based on Flow and Density
            trafficData.volume(i, j) = trafficData.volume(i, j); % Assuming flow represents volume
            trafficData.occupancy(i, j) = baseOccupancy / maxOccupancy * 100; % Percentage occupancy

            % Ensure that differences across segments do not exceed 25 km/h
            if j > 1 && i > 1
                previousSegmentSpeed = trafficData.speed(i-1, j);
                baseSpeed = adjustWithinRange(baseSpeed, 25, previousSegmentSpeed - 25, previousSegmentSpeed + 25);
            end

            trafficData.speed(i, j) = adjustWithinRange(baseSpeed + (j-1) * laneDifferenceSpeed, 5, 0, maxSpeed);
            % trafficData.volume(i, j) = adjustWithinRange(baseVolume + (j-1) * laneDifferenceVolume, 10, 0, maxVolume);
            trafficData.occupancy(i, j) = adjustWithinRange(baseOccupancy + (j-1) * laneDifferenceOccupancy, 5, 0, maxOccupancy);
            
            % Calculate traffic density based on volume and speed
            % Ensure speed is not zero to avoid division by zero
            if trafficData.speed(i, j) > 0
                trafficData.occupancy(i, j) = trafficData.volume(i, j) / trafficData.speed(i, j);
            else
                trafficData.occupancy(i, j) = 0; % Assign zero density if speed is zero
            end
        end
    end
end

function newValue = adjustWithinRange(value, maxChange, minLimit, maxLimit)
    % Randomly adjust the value within the specified range
    change = maxChange * (2 * rand - 1); % Change can be positive or negative
    newValue = value + change;
    % Ensure the new value is within limits
    newValue = min(max(newValue, minLimit), maxLimit);
end
