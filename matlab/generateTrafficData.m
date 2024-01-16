function [rho, env_conditions, road_conditions] = generateTrafficData(maxDensity, maxEnv, maxRoad, cycle)
    % Number of road segments
    numSegments = 100;

    % Initialize arrays
    rho = zeros(1, numSegments);
    env_conditions = zeros(1, numSegments);
    road_conditions = zeros(1, numSegments);

    % Define segments for specific scenarios like bottlenecks or incidents
    bottleneckSegments = 40:50; % Example: segments 40 to 50 are a bottleneck area
    incidentSegments = 70:80;   % Example: segments 70 to 80 have an incident

    % Generate cyclic traffic density with specific conditions
    for i = 1:numSegments
        if ismember(i, bottleneckSegments) || ismember(i, incidentSegments)
            % Higher density at bottlenecks and incident areas
            rho(i) = maxDensity * 0.8 + sin(cycle) * (maxDensity * 0.2);
        else
            % Normal cyclic variation in other areas
            rho(i) = maxDensity * 0.5 + sin(cycle) * (maxDensity * 0.5);
        end
    end

    % Generate environmental and road conditions
    % Here you can introduce more complexity based on your scenario
    env_conditions = rand(1, numSegments) * maxEnv;
    road_conditions = rand(1, numSegments) * maxRoad;

    % Optionally, add specific conditions for environmental and road scenarios
    % For example, lower visibility in bottleneck areas during certain cycles
end

%% Cyclic Traffic Density: The function now generates traffic density (rho) in a cyclic manner, with variations over time. 
% The sin function is used to create this cyclic pattern.
% Special Conditions for Specific Segments: For bottleneck or incident segments, the density is set higher to simulate congested conditions. You can adjust the bottleneckSegments and incidentSegments arrays to target specific segments of the road.
% Environmental and Road Conditions: These are still generated randomly, but you can add similar logic to these as well, depending on how you want these conditions to affect traffic.
% Cycle Parameter: The cycle parameter in the function allows the cyclic pattern to change over time. You can pass a time step or a counter variable from your main simulation loop to this parameter to simulate the progression of time.