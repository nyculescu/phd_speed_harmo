function [trafficData, environmentalData, roadSurfaceData, thresholds] = initInputDataWithSynthVal(numSegments, numLanes)
    % This function generates mock data for traffic, environmental, and road surface conditions
    % with variability between road segments.
    
    thresholds.speed.max = 130 * ones(numSegments, numLanes); % Maximum speed in km/h %FIXME: for now, all lanes have 130 as max pseed limit. To be included into RsuData.speed;
    thresholds.speed.min = 5 * ones(numSegments, numLanes);
    thresholds.flow.max = 2600;

    [environmentalData, roadSurfaceData] = initEnvironmentAndSurface(numSegments, thresholds);
    
    trafficData = initTrafficFlow(numSegments, numLanes, thresholds, ...
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
function [environmentalData, roadSurfaceData] = initEnvironmentAndSurface(numSegments, thresholds)
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
    
    thresholds.env.temp.min         = -20; % km/h
    thresholds.env.temp.max         = 50;
    thresholds.env.temp.moderate    = thresholds.env.temp.max;
    thresholds.env.temp.heavy       = thresholds.env.temp.max;
    thresholds.env.temp.extreme     = thresholds.env.temp.max;
    thresholds.env.temp.likeliness  = 15;

    thresholds.env.wind.min           = 0;
    thresholds.env.wind.max           = 110;
    thresholds.env.wind.moderate      = 48;
    thresholds.env.wind.heavy         = 72;
    thresholds.env.wind.extreme       = 86.4;
    thresholds.env.wind.likeliness    = 14; % [5-25] km/h

    thresholds.env.humid.min        = 0;
    thresholds.env.humid.max        = 100;
    thresholds.env.humid.moderate   = 0;
    thresholds.env.humid.heavy      = 0;
    thresholds.env.humid.extreme    = 0;
    thresholds.env.humid.likeliness = 0;

    thresholds.env.precip.min        = 0; % mm/h
    thresholds.env.precip.max        = 50;
    thresholds.env.precip.moderate   = 2.5; % reduce speed by 10-17%
    thresholds.env.precip.heavy      = 7.6; % reduce speed by 19-27%
    thresholds.env.precip.extreme    = 50; % reduce speed at 5 km/h
    thresholds.env.precip.likeliness = 1; 

    thresholds.env.visib.min = 5000; % meters
    thresholds.env.visib.max = 0;
    thresholds.env.visib.moderate   = 1000; % 200-1000 meters: Reduce the speed by 1/3
    thresholds.env.visib.heavy      = 200; % 50-200 m: limit the speed at 50 km/h
    thresholds.env.visib.extreme    = 50; % <50 m: stop the vehicle or maybe 5 km/h
    thresholds.env.visib.likeliness = 700;

    baseTemperature = randi([thresholds.env.temp.min, thresholds.env.temp.max]); % Temperature in Celsius;
    baseWindSpeed = randi([thresholds.env.wind.min, thresholds.env.wind.max]); % Wind speed in km/h
    basePrecipitation = max(thresholds.env.precip.min, min(thresholds.env.precip.max, abs(randn)*5 + 2.5)); % Precipitation in mm/h
    baseHumidity = deriveHumidity(baseTemperature, basePrecipitation);
    baseVisibility = deriveVisibility(thresholds.env, baseWindSpeed, basePrecipitation);

    baseSurfaceTemperature = adjustSurfaceTemp(baseTemperature, -20, 55);
    baseMoisture = adjustMoisture(basePrecipitation, baseSurfaceTemperature);
    baseSalinity = adjustSalinity(basePrecipitation, 15); % [g/L]
    baseIcing = adjustIcing(baseSurfaceTemperature, baseSalinity, 2); % [cm]

    for i = 1:numSegments
        environmentalData.temperature(i) = adjustWithinRange(baseTemperature, 1, -20, 50);
        environmentalData.windSpeed(i) = adjustWithinRange(baseWindSpeed, 2.5, 0, 100);
        environmentalData.precipitation(i) = adjustWithinRange(basePrecipitation, 0.5, 0, 100);
        environmentalData.humidity(i) = adjustWithinRange(baseHumidity, 2.5, 0, 100);
        environmentalData.visibility(i) = adjustWithinRange(baseVisibility, 2.5, 0, 100);
    
        % Road Surface Data
        roadSurfaceData.moisture(i) = adjustWithinRange(baseMoisture, 2.5, 0, 30);
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

function visibility = deriveVisibility(environmentalDataThresholds, windSpeed, precipitation)
    % Define the wind and precipitation coefficients
    windCoef = 0.5;
    precipCoef = 0.5;
    
    % Compute the reduction factors
    windEffect = min(exp(windCoef * environmentalDataThresholds.wind.heavy), exp(windCoef * windSpeed));
    precipEffect = min(exp(precipCoef * environmentalDataThresholds.precip.heavy), exp(precipCoef * precipitation));
    
    % Map the wind and precipitation effects into [0-2] range
    windEffectMapped = (windEffect / environmentalDataThresholds.wind.heavy) * 2;
    precipEffectMapped = (precipEffect / environmentalDataThresholds.precip.heavy) * 2;
    
    % Compute the visibility adjustment
    visibilityAdjustment = environmentalDataThresholds.visib.likeliness * (windEffectMapped - precipEffectMapped);
    
    % Ensure the visibility adjustment is within the specified range
    visibility = max(0, min(2000, visibilityAdjustment));
end

function surfaceTemp = adjustSurfaceTemp(temperature, minSurfaceTemp, maxSurfaceTemp)
    % Adjust surface temperature
    surfaceTemp = temperature + (rand * 5 - 2.5); % Example adjustment
    surfaceTemp = max(min(surfaceTemp, maxSurfaceTemp), minSurfaceTemp);
end

function moisture = adjustMoisture(precipitation, baseSurfaceTemperature)
    % Adjust moisture level
    k1 = max(0, min(1, normrnd(0.75,3)));
    k2 = max(0, min(1, normrnd(0.75,3)));
    moisture = k1 * precipitation * (1 - exp(-k2*baseSurfaceTemperature));
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
function trafficData = initTrafficFlow(numSegments, numLanes, thresholds, precipitation, icing)
    trafficData = struct('speed', zeros(numSegments, numLanes), ...
                         'flow', zeros(numSegments, numLanes), ...
                         'density', zeros(numSegments, numLanes));
    for i = 1:numSegments
        % The variables of flow, density, and space mean speed are related
        % definitionally as flow = density x space mean speed
    
        % Assuming a normal distribution centered around half the maxDensity
        maxDensity = 40; % Maximum density [vehicles/km/lane] % FIXME: to be included into RsuData.density
        baseDensity = getDensity(maxDensity);

        % Speed Calculation considering different traffic conditions
        baseSpeed = getSpeedBasedOnDensity(maxDensity, baseDensity, thresholds.speed, i, precipitation, icing);

        % Flow Calculation with variability
        % maxFlow = 40; % Not required
        baseFlow = baseDensity * baseSpeed * (1 + randn() * 0.1); % Add 10% variability

        % Traffic jam thresholds
        if baseFlow > thresholds.flow.max || baseDensity >= 40 || baseSpeed < 50
            trafficJam = 1;
        else
            trafficJam = 0;
        end

        for j = 1:numLanes
            % Adjust values for each lane, ensuring lane 1 < lane 2 < lane 3
            % laneDifferenceFlow = 2 + 3 * rand; % x to y vehicles/h/lane difference
            laneDifferenceDensity = (0.01 + 7) * rand; % x to y difference vehicles/km/lane
            laneDifferenceSpeed = (2/laneDifferenceDensity)^2; % x to y km/h difference
            
            trafficData.optimalSpeed(i, j) = 95 - j*5; % FIXME: fabriccated values

            trafficData.speed(i, j) = adjustWithinRange(baseSpeed + (j-1) * laneDifferenceSpeed, 5, 0, thresholds.speed.max(i,j));
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
    baseSpeed = speedBounds.max(segment, 1) * (1 - baseDensity / jamDensity);
    
    % Introduce variability in speed
    % speedVariability = randn() * 5; % Adding variability with a standard deviation of 5 km/h
    % baseSpeed = baseSpeed + speedVariability;
    
    % Adjust speed for environmental and road surface conditions
    baseSpeed = adjustSpeedForConditions(baseSpeed, precipitation, icing);
    
    % Ensure the speed is not negative or exceeding maxSpeed
    baseSpeed = max(min(baseSpeed, speedBounds.max(segment, 1)), 0);
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

