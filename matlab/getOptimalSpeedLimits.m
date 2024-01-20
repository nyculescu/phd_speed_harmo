function [optimalSpeedLimits] = getOptimalSpeedLimits(mainLoopCycle, ...
    numSegments, numLanes, RsuData, speedBounds)
    % This function calculates the optimal speed limits for road segments
    % to minimize traffic flow, considering various constraints.

    % Define Optimization Problem
    opts = optimoptions('fmincon', 'Algorithm', 'sqp');

    % Define the objective function
    objectiveFunction = @(x) calculateTotalFlow(numSegments, numLanes, RsuData);

    % Define the nonlinear constraints
    nonlcon = @(x) systemConstraints(numSegments, numLanes, RsuData, speedBounds);

    % Solve Optimization Problem
    % maxSpeed is fed as initial guess and also as highest bounds
    [optimalSpeedLimits, ~] = fmincon(objectiveFunction, speedBounds.maxSpeed, ...
        [], [], [], [], speedBounds.minSpeed, speedBounds.maxSpeed, nonlcon, opts);
end

%% Total Flow
function totalFlow = calculateTotalFlow(numSegments, numLanes, RsuData)
    % This function calculates the total flow based on the given speed limits,
    % traffic, environmental, and road surface conditions.

    % Initialize total flow
    totalFlow = 0;

    % Constants and Parameters
    jamDensity = 200;    % vehicles per km, theoretical maximum density
    segmentLength = 10;  % km, as per the requirement

    % Iterate over all segments and lanes to calculate the flow
    for i = numSegments
        for j = numLanes
            % Extract data for the current segment and lane
            currentSpeed = RsuData.traffic.speed(i, j);
            vehicleCount = RsuData.traffic.volume(i, j); % Use volume for vehicle count
            environmentalFactors = [RsuData.environmental.temperature(i), ...
                RsuData.environmental.windSpeed(i), RsuData.environmental.humidity(i), ...
                RsuData.environmental.precipitation(i), RsuData.environmental.visibility(i)];
            roadSurfaceFactors = [RsuData.roadSurface.surfaceTemperature(i), ...
                RsuData.roadSurface.moisture(i), RsuData.roadSurface.icing(i), ...
                RsuData.roadSurface.salinity(i)];

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
    
    disp('Total flow');
    disp(totalFlow);
end

function adjustedSpeed = adjustSpeedForConditions(currentSpeed, environmentalFactors, roadSurfaceFactors)
    % Adjust the speed based on environmental and road surface conditions
    % Implement a realistic model based on environmental and road surface factors.

    % Placeholder for environmental and road surface adjustments
    % Adjust this logic based on your specific model or empirical data
    % Example: Decrease speed for adverse conditions
    if environmentalFactors(4) > 70 % Heavy rainfall
        currentSpeed = currentSpeed * 0.8;
    end
    if roadSurfaceFactors(3) > 25 % High icing
        currentSpeed = currentSpeed * 0.7;
    end

    % Calculate adjusted speed
    adjustedSpeed = currentSpeed; % This is a simplified placeholder
end


%% System Constraints
function [c, ceq] = systemConstraints(numSegments, numLanes, ...
    RsuData, speedBounds)
    % This function defines the nonlinear constraints for the optimization problem.
    % c: Inequality constraints (c <= 0)
    % ceq: Equality constraints (ceq == 0)

    % Initialize constraints
    c = [];
    ceq = [];

    % Constraint 1: Speed limits - Ensure speed is within legal limits
    for i = 1:numSegments
        for j = 1:numLanes
            ix = uint32(i); jx = uint32(j);
            c(end+1) = RsuData.traffic.speed(ix, jx) - speedBounds.maxSpeed(ix, jx);   % v_opt should not exceed maxSpeedLimit
            c(end+1) = speedBounds.minSpeed(ix, jx) - RsuData.traffic.speed(ix, jx);   % v_opt should not be below minSpeedLimit
        end
    end

    % Constraint 2: Environmental constraints
    for i = 1:numSegments
        ix = uint32(i);
        if RsuData.environmental.precipitation(ix) > 50 % Arbitrary threshold for heavy rainfall
            for j = 1:numLanes
                jx = uint32(j);
                c(end+1) = RsuData.traffic.speed(ix,jx) - 80; % Speed should be less than 80 km/h under heavy rain
            end
        end
    end

    % Constraint 3: Road surface constraints
    for i = 1:numSegments
        ix = uint32(i);
        % Example: Adjust speed in segments with poor road conditions
        if RsuData.roadSurface.moisture(ix) > 50 || RsuData.roadSurface.icing(ix) > 50 % High moisture or icing
            for j = 1:numLanes
                jx = uint32(j);
                c(end+1) = RsuData.traffic.speed(ix,jx) - 70; % Speed should be less than 70 km/h in these conditions
            end
        end
    end

    % Constraint 4: Traffic constraints
    for i = 1:numSegments
        for j = 1:numLanes
            ix = uint32(i); jx = uint32(j);
            % Adjust speed based on vehicle count
            if RsuData.traffic.volume(ix, jx) > 100 % Arbitrary threshold for heavy traffic
                c(end+1) = RsuData.traffic.speed(ix,jx) - 60; % Speed should be less than 60 km/h in heavy traffic
            end
        end
    end

    % Constraint 5: Adjusting speed constraint for rainfall
    for i = 1:numSegments
        ix = uint32(ix); 
        rainIntensity = RsuData.environmental.precipitation(ix);
        rainSpeedReduction = max(30, 120 - rainIntensity); % Reduce speed limit as rain intensity increases
        for j = 1:numLanes
            jx = uint32(j);
            c(end+1) = RsuData.traffic.speed(ix,jx) - rainSpeedReduction;
        end
    end
    % disp('Inequality Constraints');
    % disp(c);
    % disp('Equality Constraints');
    % disp(ceq);
end


