function mainTrafficOptimization()
    addpath './system_monitoring'
    addpath './input_data'

    [numSegments, numLanes] = deal(4, 3); % Example values

    localData = struct(); % Data stored and/or data predicted by ML-based sub-system
    % The local data is used to fusion (or augment) with or replace the sensor data
    [densityRange_local, speedRange_local] = initLocalData(numSegments, numLanes, localData);

    mainLoopCycleUpdateInterval = 3; % how often to update the data [seconds]
    mainLoopCycle = 0; % Initialize

    [trafficData, environmentalData, roadSurfaceData] = initTrafficData_Mock(numSegments, numLanes);

    %% The main loop code
    while true
        % Retreieve real-time measured conditions: % FIXME: At this moment, they are mocked 
        % 1. Traffic conditions
        % 2. Environmental conditions
        % 3. Road surface conditions
        % 4. Location and motion information of the vehicles passing the lane. FIXME: not needed at this moment
        [trafficData, environmentalData, roadSurfaceData] = getTrafficData_Mock(numSegments, numLanes, trafficData, environmentalData, roadSurfaceData);
        displayTrafficData(trafficData, environmentalData, roadSurfaceData, mainLoopCycle);

        % Call the optimization routine
        v_lim_opt = getOptimalSpeedLimits(mainLoopCycle, numSegments, numLanes, trafficData, environmentalData, roadSurfaceData);
        
        % Plot the optimized speed limits for each lane
        displayGridRhoValue(v_lim_opt, numSegments, numLanes, mainLoopCycle);
        
        % Check the System health: operational status of the sensors and the system as a whole, 
        % including fault data and cybersecurity threats
        RsuData = struct();
        RsuData.traffic = trafficData;
        RsuData.environmental = environmentalData;
        RsuData.roadSurface = roadSurfaceData;
        densityRange_sensor = 10;
        speedRange_sensor = 10;
        runSystemConditionObserver(numSegments, numLanes, RsuData, densityRange_sensor, speedRange_sensor);

        % Wait for the next update
        mainLoopCycle = mainLoopCycle + 1;
        pause(mainLoopCycleUpdateInterval);
    end
end

function displayGridRhoValue(v_lim_opt, numSegments, numLanes, mainLoopCycle)
% Display the optimized speed limits
    disp_out = ['Optimal speed limit at iteration ', num2str(mainLoopCycle)];
    disp(disp_out);
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

function displayTrafficData(trafficData, environmentalData, roadSurfaceData, mainLoopCycle)
    % Convert structures to tables
    trafficDataTable = struct2table(trafficData);
    environmentalDataTable = struct2table(environmentalData);
    roadSurfaceDataTable = struct2table(roadSurfaceData);
    
    disp_out = ['Traffic, Environmental and Road Surface Data Tables at iteration ', num2str(mainLoopCycle)];
    disp(disp_out);

    % Display tables
    disp('Traffic Data Table:');
    disp(trafficDataTable);
    
    disp('Environmental Data Table:');
    disp(environmentalDataTable);
    
    disp('Road Surface Data Table:');
    disp(roadSurfaceDataTable);
end