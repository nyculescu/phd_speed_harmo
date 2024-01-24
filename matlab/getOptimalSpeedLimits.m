function [optimalSpeedLimits] = getOptimalSpeedLimits(mainLoopCycle, ...
    numSegments, numLanes, RsuData, thresholds, segmentLength)
    % This function calculates the optimal speed limits for road segments
    % to minimize traffic flow, considering various constraints.

    % Define Optimization Problem
    opts = optimoptions('fmincon', 'Algorithm', 'sqp');

    % The objective function - Calculate the whole flow over Segments x Lanes
    objectiveFunction = @(x) -sum(sum(RsuData.traffic.speed .* RsuData.traffic.density));
    
    optimalSpeedLimits = zeros(numSegments, numLanes);
    for i = 1:numSegments
        for j = 1:numLanes
            initialGuess = RsuData.traffic.speed(i,j);
            
            % Define the nonlinear constraints
            nonlcon = @(x) OSL_systemConstraints(x, numSegments, numLanes, RsuData, thresholds);
        
            % Solve Optimization Problem
            [optimalSpeedLimit, ~] = fmincon(objectiveFunction, initialGuess, ...
                [], [], [], [], thresholds.speed.min(i, j), thresholds.speed.max(i, j), nonlcon, opts);

            optimalSpeedLimits(i, j) = optimalSpeedLimit;
        end
    end
end

function [c, ceq] = OSL_systemConstraints(x, segment, lane, RsuData, thresholds)
    c = [];
    ceq = [];

    % Constraint for speed safety limits
    c(end+1) = x - thresholds.speed.max(segment, lane);
    c(end+1) = thresholds.speed.min(segment, lane) - x;

    % Constants (these could be adjusted based on empirical data or standards)
    % Ensure that the speed does not lead to overly high density
    maxDensity = thresholds.flow.max / RsuData.traffic.optimalSpeed(segment, lane);

    currentDensity = RsuData.traffic.density(segment, lane);
    c(end+1) = currentDensity - maxDensity;

    % No equality constraints in this example
    ceq = [];
end

%% Speed related Constraints
% function [c, ceq] = OSL_speedConstraints(segment, lane, ...
%     RsuData, speedBounds)
%     % This function defines the nonlinear constraints for the optimization problem.
%     % c: Inequality constraints (c <= 0)
%     % ceq: Equality constraints (ceq == 0)
% 
%     % Initialize constraints
%     c = [];
%     ceq = [];
% 
%     % Constraint: Speed limits - Ensure speed is within legal limits
%     c(end+1) = RsuData.traffic.speed(segment, lane) - speedBounds.max(segment, lane);   % v_opt should not exceed maxSpeedLimit
%     c(end+1) = speedBounds.min(segment, lane) - RsuData.traffic.speed(segment, lane);   % v_opt should not be below minSpeedLimit
% 
%     % Constraint: Wind speed constraints
%     if RsuData.environmental.windSpeed(segment) > 90 % Extreme winds
%         c(end+1) = 0;
%     elseif RsuData.environmental.windSpeed(segment) > 50 % Heavy winds
%         c(end+1) = speedBounds.max(segment, lane) - max(20, min(30, normrnd(25,3)));
%     elseif RsuData.environmental.windSpeed(segment) > 30 % Moderate winds
%         c(end+1) = speedBounds.max(segment,lane) - max(10, min(20, normrnd(15,3)));
%     end
% 
%     % Constraint: Moisture constraints
%     if RsuData.roadSurface.moisture(segment) > 20 % Extreme Moisture, Precipitable water: >20 mm
%         c(end+1) = 0;
%     elseif RsuData.roadSurface.moisture(segment) > 10 % Heavy Moisture, Large water pools, 10-30cm deep
%         c(end+1) = speedBounds.max(segment,lane) - max(25, min(30, normrnd(27.5,3)));
%     elseif RsuData.roadSurface.moisture(segment) > 5 % Moderate Moisture, Visible water puddles
%         c(end+1) = speedBounds.max(segment,lane) - max(10, min(20, normrnd(15,3)));
%     elseif RsuData.roadSurface.moisture(segment) > 1.5 % Light Moisture
%         c(end+1) = speedBounds.max(segment,lane) - max(5, min(10, normrnd(7,3)));
%     end
% 
%     % Constraint: Icing constraints
%     if RsuData.roadSurface.icing(segment) > 2 % Extreme/Severe Icing
%         c(end+1) = 0; % Travel not advised
%     elseif RsuData.roadSurface.icing(segment) > 1 % Heavy Moisture, Large water pools, 10-30cm deep
%         c(end+1) = speedBounds.max(segment,lane) - 30;
%     elseif RsuData.roadSurface.icing(segment) > 0.5 % Moderate Moisture, Visible water puddles
%         c(end+1) = speedBounds.max(segment, lane) - 20;
%     elseif RsuData.roadSurface.icing(segment) > 0.05 % Light Moisture
%         c(end+1) = speedBounds.max(segment, lane) - max(0, min(10, normrnd(5,3)));
%     end
% 
%     % Constraint: Traffic flow constraints
%     % Adjust speed based on vehicle count
%     if RsuData.traffic.flow(segment, lane) > 2600
%         c(end+1) = speedBounds.max(segment, lane) - 60; % Speed should be less than 60 km/h in heavy traffic
%     end
% 
%     % Constraint: Adjusting speed constraint for rainfall
%     if RsuData.environmental.precipitation(segment) > 50 % Extremely hazardous conditions
%         c(end+1) = 0; % Travel not advised
%     elseif RsuData.environmental.precipitation(segment) > 7.5 % Heavy Moisture, Large water pools, 10-30cm deep
%         c(end+1) = speedBounds.max(segment, lane) - max(20, min(30, normrnd(25,3)));
%     elseif RsuData.environmental.precipitation(segment) > 2.5 % Moderate Moisture, Visible water puddles
%         c(end+1) = speedBounds.max(segment, lane) - max(10, min(15, normrnd(12.5,3)));
%     end
% end

