function mainTrafficOptimization()
    % Set the maximum values for random data generation
    maxDensity = 50;
    maxEnv = 10;
    maxRoad = 5;

    % Define how often to update the data (in seconds)
    updateInterval = 3;
    cycle = 0; % Initialize

    % Run the script continuously or for a specific number of iterations
    while true
        % Your main loop code
        [rho, env_conditions, road_conditions] = generateTrafficData(maxDensity, maxEnv, maxRoad, cycle);
        % Call the optimization routine with the new data
        v_lim_opt = runOptimization(rho);
    
        % Here, you can add additional code to process the results, plot data, etc.
        
        cycle = cycle + 0.1; % Increment cycle for next iteration
        % Wait for the next update
        pause(updateInterval);
    end
end