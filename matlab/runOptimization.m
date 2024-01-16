% Function: runOptimization
% Purpose: To optimize the speed limits along a road segment based on traffic density and other constraints.
% Inputs:
%   rho - Array representing the traffic density at different segments of the road.

function v_lim_opt = runOptimization(rho)
    % This function calculates the optimal speed limit for each road segment based
    % on the current traffic density. It uses a nonlinear optimization routine
    % provided by MATLAB's fmincon function.

    % Define target density and target speed
    % These values represent the desired traffic conditions and are used in 
    % the objective function to measure the deviation of actual conditions from these targets.
    rho_target = 30; % Target vehicles per kilometer, an example value
    v_target = 80; % Target speed in km/h, an example value

    % Weight for speed deviation cost in the objective function
    % This weight determines the relative importance of speed deviation in the cost calculation.
    alpha = 1; % Adjustable based on desired emphasis on speed deviation

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
    v_lim0 = 70 * ones(size(x)); % Initial guess: 70 km/h for all segments
    
    % Run the optimization using fmincon
    % The function finds the speed limit that minimizes the objective function
    % while satisfying the defined constraints.
    [v_lim_opt, J_min] = fmincon(@(v_lim) objectiveFunction(v_lim, rho_target, v_target, alpha, x, t, rho), ...
        v_lim0, [], [], [], [], [], [], ...
        @(v_lim) constraints(v_lim, x, t, rho), ...
        options);
    v_lim_opt = round(v_lim_opt); 
    
    % Display the optimized speed limits
    disp('Optimal speed limit:');
    disp(v_lim_opt);
    
    % Plot the optimized speed limits
    % This provides a visual representation of how speed limits vary along the road segment.
    figure;
    plot(x, v_lim_opt, 'b-', 'LineWidth', 2);
    xlabel('Position on Road (km)');
    ylabel('Optimal Speed Limit (km/h)');
    title('Optimal Speed Limit Distribution Along the Road Segment');
    grid on;
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
    % Calculate the cost function based on deviation from target density and speed.
    J = sum(sum((rho - rho_target).^2 + alpha.*(v_lim - v_target).^2));
end

% Function: constraints
% Purpose: To define constraints for the optimization problem.
% Inputs:
%   v_lim - Variable speed limits
%   x, t, rho - Spatial coordinates, time, and traffic density

function [c, ceq] = constraints(v_lim, x, t, rho)
    % This function defines the constraints for the optimization problem.
    % It includes both inequality and equality constraints.

    % Inequality constraints (c)

    % Maximum and minimum speed limits
    % These constraints ensure that the optimized speed limit stays within realistic and safe bounds.
    max_speed_limit = 120; % Upper bound for speed limit in km/h
    min_speed_limit = 30;  % Lower bound for speed limit in km/h

    % c1 and c2 ensure that the speed limit does not exceed max_speed_limit and does not fall below min_speed_limit, respectively.
    c1 = v_lim - max_speed_limit;
    c2 = min_speed_limit - v_lim;

    % Traffic Density Constraints
    % These constraints manage traffic density to prevent over-congestion or underutilization.
    max_density = 50; % Upper limit for traffic density (vehicles per km)
    min_density = 5;  % Lower limit for traffic density (vehicles per km)

    % c3 and c4 ensure that the traffic density does not exceed max_density and does not fall below min_density, respectively.
    c3 = rho - max_density;
    c4 = min_density - rho;

    % Combine all inequality constraints
    c = [c1; c2; c3; c4];

    % Equality constraints (ceq)
    % Currently, there are no specific equality constraints implemented.
    % Placeholder for potential future use.
    % Equality constraints
    ceq1 = maintainMinimumAverageSpeed(v_lim, 60); % Example: Minimum average speed of 60 km/h
    ceq2 = smoothSpeedTransitions(v_lim, 20);     % Example: Maximum speed difference of 20 km/h
    ceq3 = equalizeTrafficDensity(rho, 25);       % Example: Target density of 25 vehicles per km

    ceq = [ceq1; ceq2; ceq3]; % Combine all equality constraints

    % Diagnostic display of constraint values for debugging and analysis
    disp('Constraint values:');
    disp(['c1: ', num2str(c1)]);
    disp(['c2: ', num2str(c2)]);
    disp(['c3: ', num2str(c3)]);
    disp(['c4: ', num2str(c4)]);
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


