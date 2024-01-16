% Function: runOptimization
% Purpose: To optimize the speed limits along a road segment based on traffic density and other constraints.
% Inputs:
%   rho - Array representing the traffic density at different segments of the road.
function v_lim_opt = runOptimization(rho)
    numLanes = 2; % Number of lanes per each segment % FIXME: make it global
    numSegments = 5; % FIXME: make it global

    % This function calculates the optimal speed limit for each road segment based
    % on the current traffic density. It uses a nonlinear optimization routine
    % provided by MATLAB's fmincon function.

    % Define target density and target speed
    % These values represent the desired traffic conditions and are used in 
    % the objective function to measure the deviation of actual conditions from these targets.
    rho_target = 30 * ones(numSegments, numLanes); % Target vehicles per kilometer, an example value
    v_target = 80 * ones(numSegments, numLanes); % Target speed in km/h, an example value

    % Weight for speed deviation cost in the objective function
    % This weight determines the relative importance of speed deviation in the cost calculation.
    alpha = ones(numSegments, numLanes); % Adjustable based on desired emphasis on speed deviation

    % Spatial coordinates for the road segment
    % This divides a 10 km road segment into 100 parts for analysis.
    x = linspace(0, 10, 100); % Road segment divided into 100 parts
    
    % Time coordinates for the simulation
    % This represents a 1-hour period divided into 60 minutes.
    t = linspace(0, 1, 60); % 1 hour divided into 60 minutes
    
    % Set optimization options for fmincon
    % These options configure the optimization algorithm's behavior.
    options = optimoptions('fmincon', 'Display', 'iter-detailed', 'Algorithm', 'sqp', ...
                       'MaxIterations', 1000, 'MaxFunctionEvaluations', 5000, ...
                       'Diagnostics', 'on', 'StepTolerance', 1e-6, ...
                       'ConstraintTolerance', 1e-3);
    
    % Initial guess for the speed limit
    % This provides a starting point for the optimization algorithm.
    v_lim0 = 70 * ones(numSegments, numLanes); % Initial guess: 70 km/h for all lanes and segments
    
    % Run the optimization using fmincon
    % The function finds the speed limit that minimizes the objective function
    % while satisfying the defined constraints.
    [v_lim_opt, J_min] = fmincon(@(v_lim) sum(objectiveFunction(v_lim, rho_target, v_target, alpha, x, t, rho), 'all'), ...
        v_lim0, [], [], [], [], [], [], ...
        @(v_lim) constraints(v_lim, x, t, rho), ...
        options);
    v_lim_opt = round(v_lim_opt);

    
    % Display the optimized speed limits
    disp('Optimal speed limit:');
    disp(v_lim_opt);
    
    % Determine the actual number of lanes and segments
    [numSegments, numLanes] = size(v_lim_opt);
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
            ylim([v_lim_opt(segment, lane)-10, v_lim_opt(segment, lane)+10]); % Set the y-axis limits
            grid on;

            % Add a subtitle
            title(['Segment ', num2str(segment), ', Lane ', num2str(lane)]);
        end
    end
    % Set a common title for all subplots
    sgtitle('Optimal Speed Limit Distribution for Multi-Lane Road');

end


% Function: LWRmodel
% Purpose: To model the traffic flow using the Lighthill–Whitham–Richards (LWR) model.
% Inputs:
%   t - Time variable
%   rho - Traffic density
%   parameters - Structure containing model parameters like speed-density relationship

function rho_dot = LWRmodel(t, rho, parameters)
    % Extract parameters for the traffic model
    V = parameters.V; % Speed as a function of density
    L = parameters.L; % Length of the road segment

    % Calculate the derivative of rho (change in density over time)
    rho_dot = -diff([V(rho).*rho; 0])/L;
end

% Function: objectiveFunction
% Purpose: To define the objective function for the optimization problem.
% Inputs:
%   v_lim - Variable speed limits being optimized
%   rho_target, v_target - Target traffic density and speed
%   alpha - Weight for speed deviation cost
%   x, t - Spatial and temporal coordinates
function J = objectiveFunction(v_lim, rho_target, v_target, alpha, x, t, rho)
    % Calculate the cost function based on deviation from target density and speed for each lane and segment.
    J = zeros(size(v_lim, 1), size(v_lim, 2));
    for i = 1:size(v_lim, 1)
        for j = 1:size(v_lim, 2)
            J(i,j) = sum(sum((rho(i,j) - rho_target(i,j)).^2 + alpha.*(v_lim(i,j) - v_target(i,j)).^2));
        end
    end
end

% Function: constraints
% Purpose: To define constraints for the optimization problem.
% Inputs:
%   v_lim - Variable speed limits
%   x, t, rho - Spatial coordinates, time, and traffic density

function [c, ceq] = constraints(v_lim, x, t, rho)
    % This function defines the constraints for the optimization problem.
    % It includes both inequality and equality constraints.

    % Initialize constraints for each lane and segment
    numLanes = size(v_lim, 1);
    numSegments = size(v_lim, 2);

    c = zeros(numLanes * numSegments * 4, 1); % Inequality constraints
    ceq = zeros(numLanes * numSegments * 3, 1); % Equality constraints

    % Maximum and minimum speed limits
    max_speed_limit = 120; % Upper bound for speed limit in km/h
    min_speed_limit = 30;  % Lower bound for speed limit in km/h

    % Traffic Density Constraints
    max_density = 50; % Upper limit for traffic density (vehicles per km)
    min_density = 5;  % Lower limit for traffic density (vehicles per km)

    idx = 1; % Index for constraints
    for lane = 1:numLanes
        for segment = 1:numSegments
            % Inequality constraints (c)

            % c1 and c2 ensure that the speed limit does not exceed max_speed_limit and does not fall below min_speed_limit, respectively.
            c(idx) = v_lim(lane, segment) - max_speed_limit;
            idx = idx + 1;
            c(idx) = min_speed_limit - v_lim(lane, segment);
            idx = idx + 1;

            % c3 and c4 ensure that the traffic density does not exceed max_density and does not fall below min_density, respectively.
            c(idx) = rho(lane, segment) - max_density;
            idx = idx + 1;
            c(idx) = min_density - rho(lane, segment);
            idx = idx + 1;

            % Equality constraints (ceq)
            % You can implement equality constraints for each lane and segment as needed.
            % Placeholder for potential future use.

            % Increment the index for equality constraints
            idx = idx + 1;
        end
    end

    % Diagnostic display of constraint values for debugging and analysis
    % disp('Constraint values:');
    % disp(['c: ', num2str(c)]);
    % disp(['ceq: ', num2str(ceq)]);
end



function visibility_factor = calculateVisibilityFactor()
    % This function generates a random visibility factor.
    % It simulates varying environmental conditions 
    % that might affect visibility on the road.

    % Generate a random number between 0.0 and 1.0
    % This number represents the visibility factor, 
    % where 1 is perfect visibility and 0 is no visibility.
    random_value = rand;

    % Round the random value to the nearest 0.1 for simplicity
    visibility_factor = round(random_value, 1);
end

% Define an equality constraint for adjusting speed limits based on low visibility
function eq_constraint = speedLimitAdjustmentConstraint(v_lim, x, t)
    visibility_factor = calculateVisibilityFactor(); % Get the current visibility factor

    % Define the constraint equation for adjusting speed limits based on low visibility
    % In this example, we reduce the speed limit by 30% under low visibility conditions.
    adjusted_speed_limit = v_lim - (0.3 * visibility_factor);

    % Ensure that the adjusted speed limit is equal to the calculated value
    eq_constraint = adjusted_speed_limit - v_lim;
end

% This constraint ensures that the average speed across all road segments 
% does not fall below a certain threshold, promoting overall traffic flow.
function ceq1 = maintainMinimumAverageSpeed(v_lim, minAvgSpeed) % Maintaining a Minimum Average Speed Across Segments
    % Calculate the average speed across all segments
    avgSpeed = mean(v_lim);

    % The equality constraint ensures that the average speed 
    % is equal to the minimum average speed
    ceq1 = avgSpeed - minAvgSpeed;
end

% To avoid abrupt changes in speed limits between adjacent road segments, 
% this constraint ensures the difference in speed limits between any 
% two consecutive segments is within a specified range.
function ceq2 = smoothSpeedTransitions(v_lim, maxSpeedDiff) % Ensuring Smooth Speed Transitions Between Adjacent Segments
    % Calculate the difference in speed limits between adjacent segments
    speedDiff = diff(v_lim);

    % The equality constraint ensures that the maximum difference is not exceeded
    ceq2 = max(abs(speedDiff)) - maxSpeedDiff;
end

% This constraint can be used to ensure a more uniform distribution of 
% traffic density across the road segments.
function ceq3 = equalizeTrafficDensity(rho, targetDensity) % Equalizing Traffic Density Across Segments
    % Calculate the deviation of density from the target density for each segment
    densityDeviation = rho - targetDensity;

    % The equality constraint ensures that the sum of deviations is zero
    ceq3 = sum(densityDeviation);
end


%% Reasons this is an automatic control system
% 1. Dynamic Input and Output: Your system dynamically adjusts speed limits based on varying traffic conditions. The inputs (traffic density, environmental conditions) are continually changing, and your system responds by computing new outputs (optimized speed limits).
% 2. Feedback Mechanism: Even though the feedback is not explicit in the classical control system sense, the system uses the latest data (like a feedback) to adjust the speed limits. This resembles a feedback loop where the system's actions are based on its current state and external conditions.
% 3. Automation: The system operates automatically without human intervention, continuously processing data and making decisions based on predefined algorithms and models.
% 4. Objective Fulfillment: The system aims to achieve specific objectives (traffic flow optimization, reduction of congestion), similar to how a control system maintains a desired state or output.
%% Key Characteristics in Control Systems Perspective:
% Set Point: The target speed (v_target) and target density (rho_target) can be considered as set points that the system tries to achieve or maintain.
% Control Algorithm: The optimization process, which includes the objective function and constraints, acts as the control algorithm, determining the action (speed limits) required to achieve the desired state.
% Disturbances: Real-time variations in traffic density, environmental conditions, and road conditions are akin to disturbances in control systems, which the system must adapt to.
% Stability and Robustness: Like in control systems, ensuring stability (consistent, reliable operation over time) and robustness (effectiveness under varying conditions) is crucial.

%% Further Development Considerations:
% Real-Time Data Integration: For real-world applications, integrating real-time data feeds for traffic and environmental conditions would be essential.
% Safety and Reliability: In an automatic control system, especially one that deals with public safety like traffic management, ensuring safety and reliability is paramount.
% System Tuning: Just as control systems often require tuning (like PID tuning), your system may need adjustments in parameters and algorithms based on real-world performance and data.
% Scalability and Adaptation: Consider how the system can scale or be adapted for different traffic environments or conditions.


