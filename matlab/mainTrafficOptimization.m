function mainTrafficOptimization()
    addpath '..\system_monitoring'

    % Set the maximum values for random data generation
    maxDensity = 50;
    maxEnv = 10;
    maxRoad = 5;
    numSegments = 5; % Number of road segments % FIXME: make it global
    numLanes = 2; % Number of lanes per each segment % FIXME: make it global

    % Traffic density (vehicles per km per lane)
    densityRange = [20, 100]; % Minimum and maximum density
    sensorData.density = randi(densityRange, numSegments, numLanes);
    
    % Speed (km/h per lane)
    speedRange = [40, 120]; % Minimum and maximum speed
    sensorData.speed = randi(speedRange, numSegments, numLanes);
    
    % Environmental conditions (arbitrary scale 0 to 10)
    sensorData.environment = rand(numSegments, 1) * 10;

    % Define how often to update the data (in seconds)
    updateInterval = 3;
    cycle = 0; % Initialize

    % Initialize and simulate sensorStatus
    sensorStatus = struct();
    % Functional status (1 for functional, 0 for faulty)
    for i = 1:numSegments
        for j = 1:numLanes
            % Simulate a 10% chance of a sensor being faulty
            if rand < 0.1
                sensorStatus(i,j).functional = 0;
            else
                sensorStatus(i,j).functional = 1;
            end
        end
    end

    %% The main loop code
    while true
        [rho, env_conditions, road_conditions] = generateTrafficData(maxDensity, maxEnv, maxRoad, cycle);
        % Call the optimization routine with the new data
        v_lim_opt = runOptimization(rho);
    
        % Update sensor data
        sensorData.density = randi(densityRange, numSegments, numLanes);
        sensorData.speed = randi(speedRange, numSegments, numLanes);
        sensorData.environment = rand(numSegments, 1) * 10;
    
        % Update sensor status (simulating changes over time)
        for i = 1:numSegments
            for j = 1:numLanes
                if rand < 0.1
                    sensorStatus(i,j).functional = 0; % Simulating a sensor fault
                else
                    sensorStatus(i,j).functional = 1; % Sensor is functional
                end
            end
        end
        % Perform checks
        [isDataValid, anomalyReport] = checkDataIntegrity(sensorData);
        [isSystemHealthy, healthReport] = monitorSystemHealth(sensorStatus);
        [isSystemSecure, securityReport] = monitorCybersecurity(sensorData);
        % Handle any detected issues
        handleSystemFailure(isDataValid, isSystemHealthy, isSystemSecure);
        % Add a pause or a wait mechanism for real-time simulation
        pause(1); % Pause for 1 second before next cycle

        cycle = cycle + 0.1; % Increment cycle for next iteration
        % Wait for the next update
        pause(updateInterval);
    end
end