function [optimalSpeedLimits] = getOptimalSpeedLimits(mainLoopCycle, ...
    numSegments, numLanes, RsuData, speedBounds, segmentLength)
    % This function calculates the optimal speed limits for road segments
    % to minimize traffic flow, considering various constraints.

    % Define Optimization Problem
    opts = optimoptions('fmincon', 'Algorithm', 'sqp');

    % Define the objective function
    objectiveFunction = @(x) calculateTotalFlow(numSegments, numLanes, RsuData, speedBounds);

    % Calculate initialGuess based on adjusted speeds
    initialGuess = zeros(numSegments, numLanes);
    for i = 1:numSegments
        for j = 1:numLanes
            baseSpeed = speedBounds.maxSpeed(i, j); % Base speed for calculation
            initialGuess(i, j) = adjustSpeedForConditions(RsuData, i, baseSpeed);
        end
    end

    % Define the nonlinear constraints
    nonlcon = @(x) systemConstraints(numSegments, numLanes, RsuData, speedBounds);

    % Solve Optimization Problem
    % maxSpeed is fed as initial guess and also as highest bounds
    [optimalSpeedLimits, ~] = fmincon(objectiveFunction, initialGuess, ...
        [], [], [], [], speedBounds.minSpeed, speedBounds.maxSpeed, nonlcon, opts);
end

%% Total Flow
function totalFlow = calculateTotalFlow(numSegments, numLanes, RsuData, speedBounds)
    % This function calculates the total flow based on the given speed limits,
    % traffic, environmental, and road surface conditions.

    % Initialize total flow
    totalFlow = 0;

    % Iterate over all segments and lanes to calculate the flow
    for i = numSegments
        for j = numLanes
            baseSpeed = speedBounds.maxSpeed(i, j); % Assume max speed as base
            adjustedSpeed = adjustSpeedForConditions(RsuData, i, baseSpeed);
            density = RsuData.traffic.density(i, j); 
            
            % Flow calculation using adjusted speed
            flow = density * adjustedSpeed;
            totalFlow = totalFlow + flow;
        end
    end
    
    % disp('Total flow');
    % disp(totalFlow);
end

function adjustedSpeed = adjustSpeedForConditions(RsuData, segment, maxSpeed)
    rainThreshold = 25;
    baseSpeed = maxSpeed;
    iceThreshold = 0.5;
    rainSpeedReductionFactor = 0.75;
    iceSpeedReductionFactor = 0.75;
    % Example: Adjust speed based on rainfall
    if RsuData.environmental.precipitation(segment, 1) > rainThreshold
        baseSpeed = baseSpeed * rainSpeedReductionFactor;
    end

    % Example: Adjust speed based on road icing
    if RsuData.roadSurface.icing(segment,1) > iceThreshold
        baseSpeed = baseSpeed * iceSpeedReductionFactor;
    end

    adjustedSpeed = baseSpeed;
end

% function adjustedSpeed = adjustSpeedForConditions(currentSpeed, environmentalFactors, roadSurfaceFactors)
%     % Adjust the speed based on environmental and road surface conditions
%     % Implement a realistic model based on environmental and road surface factors.
% 
%     % Placeholder for environmental and road surface adjustments
%     % Adjust this logic based on your specific model or empirical data
%     % Example: Decrease speed for adverse conditions
%     if environmentalFactors(4) > 70 % Heavy rainfall
%         currentSpeed = currentSpeed * 0.8;
%     end
%     if roadSurfaceFactors(3) > 25 % High icing
%         currentSpeed = currentSpeed * 0.7;
%     end
% 
%     % Calculate adjusted speed
%     adjustedSpeed = currentSpeed; % This is a simplified placeholder
% end


%% System Constraints
function [c, ceq] = systemConstraints(numSegments, numLanes, ...
    RsuData, speedBounds)
    % This function defines the nonlinear constraints for the optimization problem.
    % c: Inequality constraints (c <= 0)
    % ceq: Equality constraints (ceq == 0)

    % Initialize constraints
    c = [];
    ceq = [];

    % Constraint: Speed limits - Ensure speed is within legal limits
    for i = 1:numSegments
        for j = 1:numLanes
            ix = uint32(i); jx = uint32(j);
            c(end+1) = RsuData.traffic.speed(ix, jx) - speedBounds.maxSpeed(ix, jx);   % v_opt should not exceed maxSpeedLimit
            c(end+1) = speedBounds.minSpeed(ix, jx) - RsuData.traffic.speed(ix, jx);   % v_opt should not be below minSpeedLimit
        end
    end

    % % Constraint: Environmental constraints
    % for i = 1:numSegments
    %     ix = uint32(i);
    %     if RsuData.environmental.precipitation(ix) > 50 % Arbitrary threshold for heavy rainfall
    %         for j = 1:numLanes
    %             jx = uint32(j);
    %             c(end+1) = speedBounds.maxSpeed(ix,jx) - 80; % Speed should be less than 80 km/h under heavy rain
    %         end
    %     end
    % end

    % Constraint: Road surface constraints
    for i = 1:numSegments
        ix = uint32(i);
        % Example: Adjust speed in segments with poor road conditions
        if RsuData.roadSurface.moisture(ix) > 50 || RsuData.roadSurface.icing(ix) > 50 % High moisture or icing
            for j = 1:numLanes
                jx = uint32(j);
                c(end+1) = speedBounds.maxSpeed(ix,jx) - 70; % Speed should be less than 70 km/h in these conditions
            end
        end
    end

    % Constraint: Traffic constraints
    for i = 1:numSegments
        for j = 1:numLanes
            ix = uint32(i); jx = uint32(j);
            % Adjust speed based on vehicle count
            if RsuData.traffic.flow(ix, jx) > 100 % Arbitrary threshold for heavy traffic
                c(end+1) = speedBounds.maxSpeed(ix,jx) - 60; % Speed should be less than 60 km/h in heavy traffic
            end
        end
    end

    % Constraint: Adjusting speed constraint for rainfall
    for i = 1:numSegments
        ix = uint32(ix); 
        rainIntensity = RsuData.environmental.precipitation(ix);
        for j = 1:numLanes
            jx = uint32(j);
            rainSpeedReduction = max(30, speedBounds.maxSpeed(ix,jx) - rainIntensity); % Reduce speed limit as rain intensity increases
            c(end+1) = RsuData.traffic.speed(ix,jx) - rainSpeedReduction;
        end
    end
    % disp('Inequality Constraints');
    % disp(c);
    % disp('Equality Constraints');
    % disp(ceq);
end


