function mainTrafficOptimization()
    addpath './system_monitoring'
    addpath './input_data'
    addpath './fault_injection'

    [numSegments, numLanes] = deal(4, 3); % Example values % FIXME: for now, only 4 segments by 3 lanes are generated
    segmentLength = 20;  % km, as per the requirement

    % localData = struct(); % Data stored and/or data predicted by ML-based sub-system
    % The local data is used to fusion (or augment) with or replace the sensor data
    % [densityRange_local, speedRange_local] = initLocalData(numSegments, numLanes, localData);

    mainLoopCycleUpdateInterval = 3; % how often to update the data [seconds]
    mainLoopCycle = 0; % Initialize

    [trafficData, environmentalData, roadSurfaceData, thresholds] = initInputDataWithSynthVal(numSegments, numLanes);
    
    % Shared variable
    faultInj = [NaN, NaN];
    launchFaultInjectionUI(faultInj);

    %% The main loop code
    while true
        faultInjectionManager();

        % Retreieve real-time measured conditions: % FIXME: At this moment, they are mocked 
        % 1. Traffic conditions
        % 2. Environmental conditions
        % 3. Road surface conditions
        % 4. Location and motion information of the vehicles passing the lane. FIXME: not needed at this moment
        RsuData = getInputDataWithSynthVal(numSegments, numLanes, ...
            trafficData, environmentalData, roadSurfaceData, thresholds.speed);

        displayTrafficData(RsuData, mainLoopCycle);
        % Check the System health: operational status of the sensors and the system as a whole, 
        % including fault data and cybersecurity threats
        runSystemConditionObserver(numSegments, numLanes, RsuData, 10, 10);

        % Call the optimization routine
        optimalSpeedLimits = getOptimalSpeedLimits(mainLoopCycle, numSegments, numLanes, RsuData, thresholds, segmentLength);
        
        % Plot the optimized speed limits for each lane
        displayGridOptimalSpeedLimits(optimalSpeedLimits, numSegments, numLanes, mainLoopCycle);
        
        % Wait for the next update
        mainLoopCycle = mainLoopCycle + 1;
        pause(mainLoopCycleUpdateInterval);
    end


end

function displayGridOptimalSpeedLimits(v_lim_opt, numSegments, numLanes, mainLoopCycle)
% Display the optimized speed limits
    % disp_out = ['Optimal speed limit at iteration ', num2str(mainLoopCycle)];
    % disp(disp_out);
    % disp(v_lim_opt);

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
            ylabel('Speed Rec. [km/h]'); % Recommended Speed
            ylim([0, 130]); % Set the y-axis limits
            grid on;

            % Add a subtitle
            title(['Seg. ', num2str(segment), ', Lane ', num2str(lane)]);

            speedLimit = v_lim_opt(segment, lane);
            text(3, 20, [num2str(speedLimit), ' km/h'], 'HorizontalAlignment', 'left'); 
        end
    end
    % Set a common title for all subplots
    sgtitle('Optimal Speed Limit Distribution for Multi-Lane Road');
end

function displayTrafficData(RsuData, mainLoopCycle)
    % Convert structures to tables
    trafficDataTable = struct2table(RsuData.traffic);
    environmentalDataTable = struct2table(RsuData.environmental);
    roadSurfaceDataTable = struct2table(RsuData.roadSurface);
    
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


