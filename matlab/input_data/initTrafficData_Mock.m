function [trafficData, environmentalData, roadSurfaceData, speedBounds] = initTrafficData_Mock(numSegments, numLanes)
    % This function generates mock data for traffic, environmental, and road surface conditions
    % with variability between road segments.

    % Speed limit bounds
    speedBounds = struct();
    speedBounds.maxSpeed = 130 * ones(numSegments, numLanes); % Maximum speed in km/h %FIXME: for now, all lanes have 130 as max pseed limit. To be included into RsuData.speed
    speedBounds.minSpeed = 5 * ones(numSegments, numLanes);
        
    [environmentalData, roadSurfaceData] = initEnvironmentAndSurface(numSegments);
    
    trafficData = initTrafficFlow(numSegments, numLanes, speedBounds, ...
        environmentalData.precipitation, roadSurfaceData.icing);
end

function newValue = adjustWithinRange(value, maxChange, minLimit, maxLimit)
    % Randomly adjust the value within the specified range
    change = maxChange * (2 * rand - 1); % Change can be positive or negative
    newValue = value + change;
    % Ensure the new value is within limits
    newValue = min(max(newValue, minLimit), maxLimit);
end

%% Generate Environmental and Road Surface mock data for each segment
function [environmentalData, roadSurfaceData] = initEnvironmentAndSurface(numSegments)
    % Initialize structures
    environmentalData = struct('temperature', zeros(numSegments, 1), ...
                               'windSpeed', zeros(numSegments, 1), ...
                               'humidity', zeros(numSegments, 1), ...
                               'precipitation', zeros(numSegments, 1), ...
                               'visibility', zeros(numSegments, 1));
    roadSurfaceData = struct('surfaceTemperature', zeros(numSegments, 1), ...
                             'moisture', zeros(numSegments, 1), ...
                             'icing', zeros(numSegments, 1), ...
                             'salinity', zeros(numSegments, 1));

    baseTemperature = randi([-20, 50]); % Temperature in Celsius;
    baseWindSpeed = randi([0, 100]); % Wind speed in km/h
    basePrecipitation = randi([0, 20]); % Precipitation in mm/h
    baseHumidity = deriveHumidity(baseTemperature, basePrecipitation);
    baseVisibility = deriveVisibility(baseWindSpeed, basePrecipitation);

    baseSurfaceTemperature = adjustSurfaceTemp(baseTemperature, -20, 55);
    baseMoisture = adjustMoisture(basePrecipitation, 100);
    baseSalinity = adjustSalinity(basePrecipitation, 15); % [g/L]
    baseIcing = adjustIcing(baseSurfaceTemperature, baseSalinity, 1); % [cm]

    for i = 1:numSegments
        environmentalData.temperature(i) = adjustWithinRange(baseTemperature, 1, -20, 50);
        environmentalData.windSpeed(i) = adjustWithinRange(baseWindSpeed, 2.5, 0, 100);
        environmentalData.precipitation(i) = adjustWithinRange(basePrecipitation, 3, 0, 100);
        environmentalData.humidity(i) = adjustWithinRange(baseHumidity, 2.5, 0, 100);
        environmentalData.visibility(i) = adjustWithinRange(baseVisibility, 2.5, 0, 100);
    
        % Road Surface Data
        roadSurfaceData.moisture(i) = adjustWithinRange(baseMoisture, 2.5, 0, 100);
        roadSurfaceData.surfaceTemperature(i) = adjustWithinRange(baseSurfaceTemperature, 1.0, -20, 55);
        if (roadSurfaceData.surfaceTemperature(i) < 0)
            roadSurfaceData.icing(i) = adjustWithinRange(baseIcing, 0.05, 0, 1);
        else
            roadSurfaceData.icing(i) = 0;
        end
        roadSurfaceData.salinity(i) = adjustWithinRange(baseSalinity, 2.5, 0, 30);
    end

    % Assume roadSurfaceData is derived similarly or provided separately
end

function humidity = deriveHumidity(temperature, precipitation)
    % Example logic: Higher precipitation increases humidity
    humidity = min(100, max(0, 60 + precipitation - temperature / 2));
end

function visibility = deriveVisibility(windSpeed, precipitation)
    % Example logic: Higher wind speed or precipitation reduces visibility
    visibility = max(0.2, 10 - precipitation / 2 - windSpeed / 10);
end

function surfaceTemp = adjustSurfaceTemp(temperature, minSurfaceTemp, maxSurfaceTemp)
    % Adjust surface temperature
    surfaceTemp = temperature + (rand * 5 - 2.5); % Example adjustment
    surfaceTemp = max(min(surfaceTemp, maxSurfaceTemp), minSurfaceTemp);
end

function moisture = adjustMoisture(precipitation, maxMoisture)
    % Adjust moisture level
    moisture = precipitation * 5; % Example adjustment
    moisture = min(moisture, maxMoisture);
end

function icing = adjustIcing(baseSurfaceTemp, baseSalinity, maxIcing)
    % Calculates freezing point based on water salinity 
    freezingPoint0 = 0; % Freshwater freezing point 
    slope = -0.05; % Example change
    freezingPoint = freezingPoint0 + slope * baseSalinity; 
    
    if (baseSurfaceTemp < freezingPoint)
        % Calculate icing rate 
        deltaT = abs(freezingPoint - baseSurfaceTemp);
        icingFactor = exp(-deltaT/3);  
        icing = maxIcing * icingFactor;
    else   
        icing = 0;
    end
end

function salinity = adjustSalinity(precipitation, maxSalinity)
    % Adjust salinity level
    salinity = maxSalinity * (1 - precipitation / 20); % Example adjustment
    salinity = max(salinity, 0);
end

%% Generate Traffic Flow mock data for each segment
function trafficData = initTrafficFlow(numSegments, numLanes, speedBounds, precipitation, icing)
    trafficData = struct('speed', zeros(numSegments, numLanes), ...
                         'flow', zeros(numSegments, numLanes), ...
                         'density', zeros(numSegments, numLanes));
    for i = 1:numSegments
        ix = uint32(i);

        % The variables of flow, density, and space mean speed are related
        % definitionally as flow = density x space mean speed
    
        % Assuming a normal distribution centered around half the maxDensity
        maxDensity = 40; % Maximum density [vehicles/km/lane] % FIXME: to be included into RsuData.density
        baseDensity = getDensity(maxDensity);

        % Speed Calculation considering different traffic conditions
        baseSpeed = getSpeedBasedOnDensity(maxDensity, baseDensity, speedBounds, ix, precipitation, icing);

        % Flow Calculation with variability
        % maxFlow = 40; % Not required
        baseFlow = baseDensity * baseSpeed * (1 + randn() * 0.1); % Add 10% variability

        % Traffic jam thresholds
        if baseFlow > 2600 || baseDensity >= 40 || baseSpeed < 50
            trafficJam = 1;
        else
            trafficJam = 0;
        end

        for j = 1:numLanes
            jx = uint32(j);
            % Adjust values for each lane, ensuring lane 1 < lane 2 < lane 3
            % laneDifferenceFlow = 2 + 3 * rand; % x to y vehicles/h/lane difference
            laneDifferenceDensity = (0.01 + 7) * rand; % x to y difference vehicles/km/lane
            laneDifferenceSpeed = (2/laneDifferenceDensity)^2; % x to y km/h difference
                        
            trafficData.speed(i, j) = adjustWithinRange(baseSpeed + (j-1) * laneDifferenceSpeed, 5, 0, speedBounds.maxSpeed(ix,jx));
            trafficData.density(i, j) = adjustWithinRange(baseDensity + (j-1) * laneDifferenceDensity, 5, 0, maxDensity);
            trafficData.flow(i, j) = trafficData.speed(i, j) * trafficData.density(i, j);
        end
    end
end

function baseDensity = getDensity(maxDensity) 
    meanDensity = maxDensity / 2;
    stdDensity = maxDensity / 6; % Standard deviation
    baseDensity = max(normrnd(meanDensity, stdDensity), 0);
    baseDensity = min(baseDensity, maxDensity); % Ensuring density is within realistic bounds
end

% Greenshields' linear model is a basic but commonly used approach in traffic flow theory. 
% This model suggests a linear relationship between speed and density, 
% with the speed decreasing as density increases. speed = maxSpeed * (1 - baseDensity / jamDensity)
function baseSpeed = getSpeedBasedOnDensity(maxDensity, baseDensity, speedBounds, segment, precipitation, icing) 
    jamDensity = maxDensity; % Density at which traffic is jammed
    % Calculate speed using Greenshields' linear model
    baseSpeed = speedBounds.maxSpeed(segment, 1) * (1 - baseDensity / jamDensity);
    
    % Introduce variability in speed
    % speedVariability = randn() * 5; % Adding variability with a standard deviation of 5 km/h
    % baseSpeed = baseSpeed + speedVariability;
    
    % Adjust speed for environmental and road surface conditions
    baseSpeed = adjustSpeedForConditions(baseSpeed, precipitation, icing);
    
    % Ensure the speed is not negative or exceeding maxSpeed
    baseSpeed = max(min(baseSpeed, speedBounds.maxSpeed(segment, 1)), 0);
end

function adjustedSpeed = adjustSpeedForConditions(baseSpeed, precipitation, icing)
    % Define reduction factors and thresholds
    rainSpeedReductionFactor = 0.8; % Speed reduction in heavy rain
    iceSpeedReductionFactor = 0.7; % Speed reduction on icy roads
    rainThreshold = 10; % mm/h, threshold for heavy rain
    iceThreshold = 0.1; % threshold for significant icing

    % Adjust speed based on rainfall
    if precipitation > rainThreshold
        baseSpeed = baseSpeed * rainSpeedReductionFactor;
    end

    % Adjust speed based on road icing
    if icing > iceThreshold
        baseSpeed = baseSpeed * iceSpeedReductionFactor;
    end

    % Additional adjustments can be added here based on other environmental or road surface factors

    % Ensure the adjusted speed is not lower than a minimum threshold
    minSpeedLimit = 30; % Define a reasonable minimum speed limit
    adjustedSpeed = max(baseSpeed, minSpeedLimit);
end


% Obsolete: adjusting the logistic model parameters doesn't yield satisfactory results
function baseSpeed = getSpeedBasedOnDensity_old(maxDensity, baseDensity, speedBounds) 
    k = -0.05; % The Sensitivity Factor determines how quickly speed decreases as density approaches the critical value.
    criticalDensity = 0.75 * maxDensity; % The density at which traffic conditions start to significantly affect speed
    % The logistic function is often used in traffic flow models to represent the transition from free flow to congested conditions as density increases
    speedReductionFactor = @(d) 1./(1 + exp(k*(d - criticalDensity)));
    baseSpeed = speedBounds.maxSpeed(ix,1) * speedReductionFactor(baseDensity);
    baseSpeed = baseSpeed + randn() * 2; % Adds Gaussian noise to the base speed. This step introduces variability, simulating real-world unpredictability in speeds.
end
