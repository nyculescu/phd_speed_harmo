function mainTrafficOptimization()
    addpath 'D:\phd_ws\speed_harmo\phd_speed_harmo\matlab\system_monitoring'

    % Set the maximum values for random data generation
    maxDensity = 50;
    maxEnv = 10;
    maxRoad = 5;
    numSegments = 5; % Number of road segments
    numLanes = 2; % Number of lanes per each segment
    
    sensorData = struct();
    [densityRange, speedRange] = initSystemConditionObserver(numSegments, numLanes, sensorData);

    % Define how often to update the data (in seconds)
    updateInterval = 3;
    cycle = 0; % Initialize

    %% The main loop code
    while true
        [rho, env_conditions, road_conditions] = generateTrafficData(maxDensity, maxEnv, maxRoad, cycle, numSegments, numLanes);
        % Call the optimization routine with the new data
        v_lim_opt = runOptimization(rho, numSegments, numLanes);

        displayGridRhoValue(v_lim_opt, numSegments, numLanes);
        
        runSystemConditionObserver(numSegments, numLanes, sensorData, densityRange, speedRange);

        cycle = cycle + 0.1; % Increment cycle for next iteration
        % Wait for the next update
        pause(updateInterval);
    end
end

function displayGridRhoValue(v_lim_opt, numSegments, numLanes)
% Display the optimized speed limits
    disp('Optimal speed limit:');
    disp(v_lim_opt);

    % Plot the optimized speed limits for each lane
    % Create or refresh the figure
    clf; % Clear the current figure

    % Generate x based on the number of segments
    x = linspace(0, 10, numSegments); % Assuming a 10 km road segment

    for segment = 1:numSegments
        for lane = 1:numLanes
            subplot(numSegments, numLanes, (segment - 1) * numLanes + lane);
            plot(x, ones(size(x)) * v_lim_opt(segment, lane), 'b-', 'LineWidth', 2);
            xlabel('Position on Road [km]');
            ylabel('Rec Spd [km/h]'); % Recommended Speed
            ylim([0, 130]); % Set the y-axis limits
            grid on;

            % Add a subtitle
            title(['Segment ', num2str(segment), ', Lane ', num2str(lane)]);
        end
    end
    % Set a common title for all subplots
    sgtitle('Optimal Speed Limit Distribution for Multi-Lane Road');
end