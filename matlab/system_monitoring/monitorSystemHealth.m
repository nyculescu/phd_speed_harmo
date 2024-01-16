% System Health Monitoring Module
function [isSystemHealthy, healthReport] = monitorSystemHealth(sensorStatus)
    % Check the operational status of each sensor
    isSystemHealthy = true;
    healthReport = struct();
    % Simulate sensor failures
    if rand < 0.05 % 5% chance of failure
        isSystemHealthy = false;
        healthReport.issue = 'Sensor Failure';
        healthReport.failedSensor = 'Sensor ID';
    end
end