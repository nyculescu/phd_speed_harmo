function launchFaultInjectionUI(faultInj)
    % Check if the UI already exists
    existingFig = findall(0, 'Type', 'figure', 'Name', 'Fault Injection Interface');
    if ~isempty(existingFig)
        % If UI exists, delete it
        delete(existingFig);
    end

    % Create figure
    fig = uifigure('Name', 'Fault Injection Interface');

    % Create a grid layout
    gl = uigridlayout(fig, [5, 3]);
    gl.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit'};  % Set row height to fit the content
    gl.ColumnWidth = {'fit', 'fit', 'fit'};  % Set column width to fit the content

    % Create a 'Check/Uncheck All' checkbox
    checkAllCheckbox = uicheckbox(gl, 'Text', 'Check/Uncheck All', ...
        'ValueChangedFcn', @(src, event) toggleAllCheckboxes(src.Value));
    checkAllCheckbox.Layout.Row = 1;
    checkAllCheckbox.Layout.Column = [1, 3];  % Span across all columns

    % Create the first row of UI elements
    label1 = uilabel(gl, 'Text', 'Enter fault value 0:');
    label1.Layout.Row = 2;
    label1.Layout.Column = 1;

    faultInput1 = uieditfield(gl, 'numeric', 'Tooltip', 'Change value and press enter');
    faultInput1.Layout.Row = 2;
    faultInput1.Layout.Column = 2;

    checkbox1 = uicheckbox(gl, 'Text', '');
    checkbox1.Layout.Row = 2;
    checkbox1.Layout.Column = 3;

    % Create the second row of UI elements
    label2 = uilabel(gl, 'Text', 'Enter fault value 1:');
    label2.Layout.Row = 3;
    label2.Layout.Column = 1;

    faultInput2 = uieditfield(gl, 'numeric', 'Tooltip', 'Change value and press enter');
    faultInput2.Layout.Row = 3;
    faultInput2.Layout.Column = 2;

    checkbox2 = uicheckbox(gl, 'Text', '');
    checkbox2.Layout.Row = 3;
    checkbox2.Layout.Column = 3;

    % Create a general submit button
    submitButton = uibutton(gl, 'Text', 'Submit All', ...
        'ButtonPushedFcn', @(btn,event) submitAllValues());
    submitButton.Layout.Row = 4;
    submitButton.Layout.Column = [1, 3];  % Span across all columns

    % Function to toggle all checkboxes
    function toggleAllCheckboxes(value)
        checkbox1.Value = value;
        checkbox2.Value = value;
        % Include similar lines for other checkboxes if you have more
    end

    % Callback function for the general submit button
    function submitAllValues()
        if checkbox1.Value
            value1 = faultInput1.Value;
            disp(['Fault 0 value submitted: ', num2str(value1)]);
            faultInj(1) = value1;
        end
        
        if checkbox2.Value
            value2 = faultInput2.Value;
            disp(['Fault 1 value submitted: ', num2str(value2)]);
            faultInj(2) = value2;
        end

        % Reset checkboxes
        checkbox1.Value = false;
        checkbox2.Value = false;
        checkAllCheckbox.Value = false; % Reset 'Check/Uncheck All' checkbox as well
    end
end