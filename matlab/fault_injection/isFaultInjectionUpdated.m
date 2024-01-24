function isFaultInjectionUpdated(faultInj)
    % Iterate through each element in the faultInj array
    for i = 1:length(faultInj)
        % Check if the current element has been updated
        if ~isnan(faultInj(i))
            disp(['Using fault ', num2str(i), ': ', num2str(faultInj(i))]);
            % Use the current fault value in your main logic
            % ...

            % Reset the current fault value if necessary
            faultInj(i) = NaN;
        end
    end
end
