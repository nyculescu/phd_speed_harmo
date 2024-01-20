function [trafficData, environmentalData, roadSurfaceData, speedBounds] = initTrafficData_Mock(numSegments, numLanes)
    % This function generates mock data for traffic, environmental, and road surface conditions
    % with variability between road segments.

    % Speed limit bounds
    speedBounds = struct();
    speedBounds.maxSpeed = 130 * ones(numSegments, numLanes); % Maximum speed in km/h %FIXME: for now, all lanes have 130 as max pseed limit
    speedBounds.minSpeed = 5 * ones(numSegments, numLanes);

    % Initialize data structures
    trafficData = struct('speed', zeros(numSegments, numLanes), ...
                         'flow', zeros(numSegments, numLanes), ...
                         'density', zeros(numSegments, numLanes));
    environmentalData = struct('temperature', zeros(numSegments, 1), ...
                               'windSpeed', zeros(numSegments, 1), ...
                               'humidity', zeros(numSegments, 1), ...
                               'precipitation', zeros(numSegments, 1), ...
                               'visibility', zeros(numSegments, 1));
    roadSurfaceData = struct('surfaceTemperature', zeros(numSegments, 1), ...
                             'moisture', zeros(numSegments, 1), ...
                             'icing', zeros(numSegments, 1), ...
                             'salinity', zeros(numSegments, 1));
        
    [environmentalData, roadSurfaceData] = initEnvironmentAndSurface(numSegments, environmentalData, roadSurfaceData);
    
    trafficData = initTrafficFlow(numSegments, numLanes, trafficData, speedBounds);
end

function newValue = adjustWithinRange(value, maxChange, minLimit, maxLimit)
    % Randomly adjust the value within the specified range
    change = maxChange * (2 * rand - 1); % Change can be positive or negative
    newValue = value + change;
    % Ensure the new value is within limits
    newValue = min(max(newValue, minLimit), maxLimit);
end

%% Generate Environmental and Road Surface mock data for each segment
function [environmentalData, roadSurfaceData] = initEnvironmentAndSurface(numSegments, environmentalData, roadSurfaceData)
    % Environmental Data
    minTemperature = -40;       % Minimum temperature in Celsius
    maxTemperature = 45;        % Maximum temperature in Celsius
    maxWindSpeed = 75;          % Maximum wind speed in km/h
    maxHumidity = 100;          % Maximum humidity percentage
    maxPrecipitation = 100;     % Maximum precipitation in mm/h
    maxVisibility = 10;         % Maximum visibility in km
    baseTemperature = minTemperature + (maxTemperature - minTemperature) * rand;
    baseWindSpeed = maxWindSpeed * rand;
    baseHumidity = maxHumidity * rand;
    basePrecipitation = maxPrecipitation * rand;

    % Road Surface Data
    minSurfaceTemp = -30;       % Minimum surface temperature in Celsius
    maxSurfaceTemp = 60;        % Maximum surface temperature in Celsius
    maxMoistureLevel = 100;     % Maximum moisture level percentage
    maxIcing = 100;             % Maximum icing percentage
    maxSalinity = 25;           % Maximum salinity percentage
    baseMoisture = 0;
    baseIcing = 0;
    
    if basePrecipitation < 10
        if baseTemperature > 40
            baseSurfaceTemperature = baseTemperature + 10;
            baseVisibility = 100;
        elseif baseTemperature > 35
            baseSurfaceTemperature = baseTemperature + 8.5;
            baseVisibility = 100;
        elseif baseTemperature > 30
            baseSurfaceTemperature = baseTemperature + 6;
            baseVisibility = 100;
        elseif baseTemperature > 25
            baseSurfaceTemperature = baseTemperature + 4.5;
            baseVisibility = 75 + (100-75).*rand(1,1);
        elseif baseTemperature > 20
            baseSurfaceTemperature = baseTemperature + 3;
            baseVisibility = 50 + (100-50).*rand(1,1);
        elseif baseTemperature > 10
            baseSurfaceTemperature = baseTemperature + 1.5;
            baseVisibility = 35 + (100-35).*rand(1,1);
            baseMoisture = 5;
        else
            baseSurfaceTemperature = baseTemperature;
            baseMoisture = 10;
            baseVisibility = 25 + (100-25).*rand(1,1);
            baseIcing = 10 * basePrecipitation * 1 / baseSurfaceTemperature;
        end
    else
        baseMoisture = 10 + (100-10).*rand(1,1);
        baseSurfaceTemperature = baseTemperature;
        baseVisibility = 25 + (100-25).*rand(1,1);
        baseIcing = abs(10 * basePrecipitation * 1 / baseSurfaceTemperature);
    end

    baseSalinity = maxSalinity * rand;
    if basePrecipitation > 10 % Threshold for heavy rain
        baseSalinity = baseSalinity * 0.8; % Reduce salinity by 20%
    end

    if baseWindSpeed > 50 % Threshold for high wind
        baseVisibility = baseVisibility * 0.01 * baseWindSpeed; % Reduce visibility
    end

    if baseSurfaceTemperature < 0
        baseIcing = baseIcing * 1.25; % Increase icing by 25%
    end
    
    if baseSalinity > 5
        baseIcing = baseIcing * 0.75; % Reduce icing by 25%
    end

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
    end
end

%% Generate Traffic Flow mock data for each segment
function trafficData = initTrafficFlow(numSegments, numLanes, trafficData, speedBounds)
    for i = 1:numSegments
        ix = uint32(i);

        % The variables of flow, density, and space mean speed are related
        % definitionally as flow = density x space mean speed
    
        % Assuming a normal distribution centered around half the maxDensity
        maxDensity = 40; % Maximum occupancy [vehicles/km/lane]
        baseDensity = getDensity(maxDensity);

        % Speed Calculation considering different traffic conditions
        baseSpeed = getSpeedBasedOnDensity(maxDensity, baseDensity, speedBounds, ix);

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

function baseSpeed = getSpeedBasedOnDensity(maxDensity, baseDensity, speedBounds, segment) 
    jamDensity = maxDensity; % Density at which traffic is jammed
    % Calculate speed using Greenshields' linear model
    baseSpeed = speedBounds.maxSpeed(segment, 1) * (1 - baseDensity / jamDensity);
    % Introduce variability in speed
    speedVariability = randn() * 5; % Adding variability with a standard deviation of 5 km/h
    baseSpeed = baseSpeed + speedVariability;
    % Ensure the speed is not negative or exceeding maxSpeed
    baseSpeed = max(min(baseSpeed, speedBounds.maxSpeed(segment, 1)), 0);
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
