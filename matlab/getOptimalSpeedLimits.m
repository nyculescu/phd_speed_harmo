function [optimalSpeedLimits] = getOptimalSpeedLimits(mainLoopCycle, ...
    numSegments, numLanes, RsuData, speedBounds, segmentLength)
    % This function calculates the optimal speed limits for road segments
    % to minimize traffic flow, considering various constraints.

    % Define Optimization Problem
    opts = optimoptions('fmincon', 'Algorithm', 'sqp');

    % Define the objective function
    objectiveFunction = @(x) OSL_calculateTotalFlow(numSegments, numLanes, RsuData, speedBounds);

    % Calculate initialGuess based on adjusted speeds
    initialGuess = zeros(numSegments, numLanes);
    for i = 1:numSegments
        for j = 1:numLanes
            baseSpeed = speedBounds.maxSpeed(i, j); % Base speed for calculation
            % initialGuess(i, j) = OSL_adjustSpeedForConditions(RsuData, i, baseSpeed);
        end
    end

    % Define the nonlinear constraints
    nonlcon = @(x) OSL_systemConstraints(numSegments, numLanes, RsuData, speedBounds);

    % Solve Optimization Problem
    % maxSpeed is fed as initial guess and also as highest bounds
    [optimalSpeedLimits, ~] = fmincon(objectiveFunction, initialGuess, ...
        [], [], [], [], speedBounds.minSpeed, speedBounds.maxSpeed, nonlcon, opts);
end

%% Total Flow
function totalFlow = OSL_calculateTotalFlow(numSegments, numLanes, RsuData, speedBounds)
    % This function calculates the total flow based on the given speed limits,
    % traffic, environmental, and road surface conditions.

    % Initialize total flow
    totalFlow = 0;
    adjustedSpeed = 130;

    % Iterate over all segments and lanes to calculate the flow
    for i = numSegments
        for j = numLanes
            baseSpeed = speedBounds.maxSpeed(i, j); % Assume max speed as base
            % adjustedSpeed = OSL_adjustSpeedForConditions(RsuData, i, baseSpeed);
            density = RsuData.traffic.density(i, j); 
            
            % Flow calculation using adjusted speed
            flow = density * adjustedSpeed;
            totalFlow = totalFlow + flow;
        end
    end
    
    % disp('Total flow');
    % disp(totalFlow);
end

% function adjustedSpeed = OSL_adjustSpeedForConditions(RsuData, segment, maxSpeed)
%     baseSpeed = maxSpeed;
% 
%     moderateRain = 2.5; % Recommended to reduce speed by 10-15 km/h
%     heavyRain = 7.5; % Reduce speed more substantially by 20-30 km/h
%     extremeRain = 50; % Extremely hazardous conditions
%     baseSpeedReducedByRain = false;
% 
%     % Example: Adjust speed based on rainfall
%     if RsuData.environmental.precipitation(segment, 1) > moderateRain
%         baseSpeed = baseSpeed - max(10, min(15, normrnd(12.5,3))); % normrnd samples normal distribution, which we constrain within 10-15
%         baseSpeedReducedByRain = true;
%     elseif RsuData.environmental.precipitation(segment, 1) > heavyRain
%         baseSpeed = baseSpeed - max(20, min(30, normrnd(25,3)));
%         baseSpeedReducedByRain = true;
%     elseif RsuData.environmental.precipitation(segment, 1) > extremeRain
%         baseSpeed = 5;
%         baseSpeedReducedByRain = true;
%     end
% 
%     % Example: Adjust speed based on road icing
%     baseSpeed = baseSpeed - adjustSpeedForIcing(RsuData, baseSpeedReducedByRain, baseSpeed);
% 
%     adjustedSpeed = baseSpeed;
% end

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
function [c, ceq] = OSL_systemConstraints(numSegments, numLanes, ...
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

    % Constraint: Wind speed constraints
    for i = 1:numSegments
        if RsuData.environmental.windSpeed(i) > 90 % Extreme winds
            for j = 1:numLanes
                c(end+1) = 0;
            end
        elseif RsuData.environmental.windSpeed(i) > 50 % Heavy winds
            for j = 1:numLanes
                c(end+1) = speedBounds.maxSpeed(i,j) - max(20, min(30, normrnd(25,3)));
            end   
        elseif RsuData.environmental.windSpeed(i) > 30 % Moderate winds
            for j = 1:numLanes
                c(end+1) = speedBounds.maxSpeed(i,j) - max(10, min(20, normrnd(15,3)));
            end   
        end
    end

    % Constraint: Moisture constraints
    for i = 1:numSegments
        if RsuData.roadSurface.moisture(i) > 20 % Extreme Moisture, Precipitable water: >20 mm
            for j = 1:numLanes
                c(end+1) = 0;
            end
        elseif RsuData.roadSurface.moisture(i) > 10 % Heavy Moisture, Large water pools, 10-30cm deep
            for j = 1:numLanes
                c(end+1) = speedBounds.maxSpeed(i,j) - max(25, min(30, normrnd(27.5,3)));
            end   
        elseif RsuData.roadSurface.moisture(i) > 5 % Moderate Moisture, Visible water puddles
            for j = 1:numLanes
                c(end+1) = speedBounds.maxSpeed(i,j) - max(10, min(20, normrnd(15,3)));
            end   
        elseif RsuData.roadSurface.moisture(i) > 1.5 % Light Moisture
            for j = 1:numLanes
                c(end+1) = speedBounds.maxSpeed(i,j) - max(5, min(10, normrnd(7,3)));
            end   
        end
    end

    % Constraint: Icing constraints
    for i = 1:numSegments
        if RsuData.roadSurface.icing(i) > 2 % Extreme/Severe Icing
            for j = 1:numLanes
                c(end+1) = 0; % Travel not advised
            end 
        elseif RsuData.roadSurface.icing(i) > 1 % Heavy Moisture, Large water pools, 10-30cm deep
            for j = 1:numLanes
                c(end+1) = speedBounds.maxSpeed(i,j) - 30;
            end   
        elseif RsuData.roadSurface.icing(i) > 0.5 % Moderate Moisture, Visible water puddles
            for j = 1:numLanes
                c(end+1) = speedBounds.maxSpeed(i,j) - 20;
            end   
        elseif RsuData.roadSurface.icing(i) > 0.05 % Light Moisture
            for j = 1:numLanes
                c(end+1) = speedBounds.maxSpeed(i,j) - max(0, min(10, normrnd(5,3)));
            end   
        end
    end

    % Constraint: Traffic flow constraints
    for i = 1:numSegments
        for j = 1:numLanes
            % Adjust speed based on vehicle count
            if RsuData.traffic.flow(i, j) > 2600
                c(end+1) = speedBounds.maxSpeed(i,j) - 60; % Speed should be less than 60 km/h in heavy traffic
            end
        end
    end

    % Constraint: Adjusting speed constraint for rainfall
    for i = 1:numSegments
        if RsuData.environmental.precipitation(i) > 50 % Extremely hazardous conditions
            for j = 1:numLanes
                c(end+1) = 0; % Travel not advised
            end 
        elseif RsuData.environmental.precipitation(i) > 7.5 % Heavy Moisture, Large water pools, 10-30cm deep
            for j = 1:numLanes
                c(end+1) = speedBounds.maxSpeed(i,j) - max(20, min(30, normrnd(25,3)));
            end   
        elseif RsuData.environmental.precipitation(i) > 2.5 % Moderate Moisture, Visible water puddles
            for j = 1:numLanes
                c(end+1) = speedBounds.maxSpeed(i,j) - max(10, min(15, normrnd(12.5,3)));
            end
        end
    end
    % disp('Inequality Constraints');
    % disp(c);
    % disp('Equality Constraints');
    % disp(ceq);
end


