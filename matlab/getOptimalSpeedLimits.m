function [optimalSpeedLimits] = getOptimalSpeedLimits(mainLoopCycle, ...
    numSegments, numLanes, RsuData)
    % This function calculates the optimal speed limits for road segments
    % to minimize traffic flow, considering various constraints.

    % Define Optimization Problem
    opts = optimoptions('fmincon', 'Algorithm', 'sqp');
    initialGuess = 50 * ones(numSegments, numLanes); % Initial guess for speed limits
    lb = 30 * ones(numSegments, numLanes); % Lower bounds for speed limits
    ub = 120 * ones(numSegments, numLanes); % Upper bounds for speed limits

    % Define the objective function
    objectiveFunction = @(v_opt) calculateTotalFlow(v_opt, RsuData.traffic, ...
        RsuData.environmental, RsuData.roadSurface);

    % Define the nonlinear constraints
    nonlcon = @(v_opt) systemConstraints(v_opt, RsuData.traffic, RsuData.environmental, ...
        RsuData.roadSurface);

    % Solve Optimization Problem
    [optimalSpeedLimits, ~] = fmincon(objectiveFunction, initialGuess, ...
        [], [], [], [], lb, ub, nonlcon, opts);
end

%% Total Flow
function totalFlow = calculateTotalFlow(v_opt, trafficData, environmentalData, ...
    roadSurfaceData)
    % This function calculates the total flow based on the given speed limits,
    % traffic, environmental, and road surface conditions.

    % Initialize total flow
    totalFlow = 0;

    % Constants and Parameters
    jamDensity = 200;    % vehicles per km, theoretical maximum density
    segmentLength = 10;  % km, as per the requirement

    % Iterate over all segments and lanes to calculate the flow
    for i = 1:size(v_opt, 1)
        for j = 1:size(v_opt, 2)
            % Extract data for the current segment and lane
            currentSpeed = v_opt(i, j);
            vehicleCount = trafficData.volume(i, j); % Use volume for vehicle count
            environmentalFactors = [environmentalData.temperature(i), ...
                environmentalData.windSpeed(i), environmentalData.humidity(i), ...
                environmentalData.precipitation(i), environmentalData.visibility(i)];
            roadSurfaceFactors = [roadSurfaceData.surfaceTemperature(i), ...
                roadSurfaceData.moisture(i), roadSurfaceData.icing(i), ...
                roadSurfaceData.salinity(i)];

            % Adjust speed based on environmental and road surface conditions
            adjustedSpeed = adjustSpeedForConditions(currentSpeed, environmentalFactors, roadSurfaceFactors);

            % Calculate density for the current segment and lane
            density = vehicleCount / segmentLength; % vehicles per km

            % Calculate flow using a simplified model
            if density < jamDensity
                flow = density * adjustedSpeed;
            else
                flow = 0; % At jam density, flow is zero
            end

            % Add the flow of the current segment and lane to the total flow
            totalFlow = totalFlow + flow;
        end
    end
end

function adjustedSpeed = adjustSpeedForConditions(currentSpeed, environmentalFactors, roadSurfaceFactors)
    % Adjust the speed based on environmental and road surface conditions
    % Implement a realistic model based on environmental and road surface factors.

    % Placeholder for environmental and road surface adjustments
    % Adjust this logic based on your specific model or empirical data
    % Example: Decrease speed for adverse conditions
    if environmentalFactors(4) > 50 % Heavy rainfall
        currentSpeed = currentSpeed * 0.8;
    end
    if roadSurfaceFactors(3) > 50 % High icing
        currentSpeed = currentSpeed * 0.7;
    end

    % Calculate adjusted speed
    adjustedSpeed = currentSpeed; % This is a simplified placeholder
end


%% System Constraints
function [c, ceq] = systemConstraints(v_opt, trafficData, environmentalData, roadSurfaceData)
    % This function defines the nonlinear constraints for the optimization problem.
    % c: Inequality constraints (c <= 0)
    % ceq: Equality constraints (ceq == 0)

    % Initialize constraints
    c = [];
    ceq = [];

    % Constants and Parameters
    maxSpeedLimit = 130; % Maximum speed limit in km/h
    minSpeedLimit = 5;  % Minimum speed limit in km/h
    numSegments = size(v_opt, 1);
    numLanes = size(v_opt, 2);

    % Constraint 1: Speed limits - Ensure speed is within legal limits
    for i = 1:numSegments
        for j = 1:numLanes
            c(end+1) = v_opt(i, j) - maxSpeedLimit;   % v_opt should not exceed maxSpeedLimit
            c(end+1) = minSpeedLimit - v_opt(i, j);   % v_opt should not be below minSpeedLimit
        end
    end

    % Constraint 2: Environmental constraints
    for i = 1:numSegments
        if environmentalData.precipitation(i) > 50 % Arbitrary threshold for heavy rainfall
            for j = 1:numLanes
                c(end+1) = v_opt(i, j) - 80; % Speed should be less than 80 km/h under heavy rain
            end
        end
    end

    % Constraint 3: Road surface constraints
    for i = 1:numSegments
        % Example: Adjust speed in segments with poor road conditions
        if roadSurfaceData.moisture(i) > 50 || roadSurfaceData.icing(i) > 50 % High moisture or icing
            for j = 1:numLanes
                c(end+1) = v_opt(i, j) - 70; % Speed should be less than 70 km/h in these conditions
            end
        end
    end

    % Constraint 4: Traffic constraints
    for i = 1:numSegments
        for j = 1:numLanes
            % Adjust speed based on vehicle count
            if trafficData.volume(i, j) > 100 % Arbitrary threshold for heavy traffic
                c(end+1) = v_opt(i, j) - 60; % Speed should be less than 60 km/h in heavy traffic
            end
        end
    end

    % Constraint 5: Adjusting speed constraint for rainfall
    for i = 1:numSegments
        rainIntensity = environmentalData.precipitation(i);
        rainSpeedReduction = max(30, 120 - rainIntensity); % Reduce speed limit as rain intensity increases
        for j = 1:numLanes
            c(end+1) = v_opt(i, j) - rainSpeedReduction;
        end
    end

end


