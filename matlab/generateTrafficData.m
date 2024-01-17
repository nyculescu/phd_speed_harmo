% The function uses 3D arrays to store data for each segment and lane. 
% The first dimension is for the segments, 
% the second for the lanes, 
% and the third for the conditions (density, environment, road surface)
function [rho, env_conditions, road_conditions] = generateTrafficData(maxDensity, maxEnv, maxRoad, cycle, numSegments, numLanes)
    % Initialize arrays
    % Lane-Specific Conditions
    % The traffic density (rho) is calculated for each lane. 
    % TODO: introduce lane-specific variations or patterns as required.
    rho = zeros(numSegments, numLanes);

    % Shared Environmental and Road Conditions
    % In this example, environmental and road conditions are assumed to be 
    % the same across all lanes of a segment. 
    % TODO: these can also be made lane-specific.
    env_conditions = zeros(numSegments, numLanes);
    road_conditions = zeros(numSegments, numLanes);

    % Define segments for specific scenarios like bottlenecks or incidents
    bottleneckSegments = 1:2; % Example: segments 1 to 2 are a bottleneck area
    incidentSegments = 2:3;   % Example: segments 2 to 3 have an incident
    eventSegments = 2:3;
    congestionSegments = 4:5;

    %% Generate cyclic traffic density with specific conditions
    % Simulate different scenarios for each lane
    for i = 1:numSegments
        for j = 1:numLanes
            % Traffic density variations
            if ismember(i, bottleneckSegments) || ismember(i, incidentSegments) || ismember(i, congestionSegments)
                rho(i, j) = maxDensity * 0.8 + sin(cycle + j) * (maxDensity * 0.2);
            elseif ismember(i, eventSegments)
                rho(i, j) = maxDensity * 0.7 + sin(cycle + j) * (maxDensity * 0.3);
            else
                rho(i, j) = maxDensity * 0.5 + sin(cycle + j) * (maxDensity * 0.5);
            end

            % Environmental conditions (assumed same across lanes)
            env_conditions(i, j) = rand * maxEnv;

            % Road conditions (assumed same across lanes)
            road_conditions(i, j) = rand * maxRoad;
        end
    end
end

%% Cyclic Traffic Density: The function now generates traffic density (rho) in a cyclic manner, with variations over time. 
% The sin function is used to create this cyclic pattern.
% Special Conditions for Specific Segments: For bottleneck or incident segments, the density is set higher to simulate congested conditions. You can adjust the bottleneckSegments and incidentSegments arrays to target specific segments of the road.
% Environmental and Road Conditions: These are still generated randomly, but you can add similar logic to these as well, depending on how you want these conditions to affect traffic.
% Cycle Parameter: The cycle parameter in the function allows the cyclic pattern to change over time. You can pass a time step or a counter variable from your main simulation loop to this parameter to simulate the progression of time.