classdef SimonSays < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        GameAreaPanel                  matlab.ui.container.Panel
        GridLayout                     matlab.ui.container.GridLayout
        StatusEditFieldLabel           matlab.ui.control.Label
        StatusText                     matlab.ui.control.EditField
        NextRoundButton                matlab.ui.control.Button
        RepeatSequenceButton           matlab.ui.control.Button
        CheckSequenceButton            matlab.ui.control.Button
        D2Button                       matlab.ui.control.Button
        D3Button                       matlab.ui.control.Button
        D4Button                       matlab.ui.control.Button
        D5Button                       matlab.ui.control.Button
        D6Button                       matlab.ui.control.Button
        D7Button                       matlab.ui.control.Button
        D8Button                       matlab.ui.control.Button
        D9Button                       matlab.ui.control.Button
        D10Button                      matlab.ui.control.Button
        D11Button                      matlab.ui.control.Button
        D12Button                      matlab.ui.control.Button
        D13Button                      matlab.ui.control.Button
        RoundNumberText                matlab.ui.control.NumericEditField
        RoundNumberEditFieldLabel      matlab.ui.control.Label
        MenuPanel                      matlab.ui.container.Panel
        GridLayout2                    matlab.ui.container.GridLayout
        WarningTextBox                 matlab.ui.control.Label
        PasswordEditField              matlab.ui.control.EditField
        PasswordEditFieldLabel         matlab.ui.control.Label
        UsernameEditField              matlab.ui.control.EditField
        UsernameEditFieldLabel         matlab.ui.control.Label
        AttemptsRemainingSpinnerLabel  matlab.ui.control.Label
        AttemptsRemainingSpinner       matlab.ui.control.Spinner
        NumberofRoundsSpinnerLabel     matlab.ui.control.Label
        NumberofRoundsSpinner          matlab.ui.control.Spinner
        StartGameButton                matlab.ui.control.Button
        QuitGameButton                 matlab.ui.control.Button
        MostGloriousTitleOfGloriousness  matlab.ui.control.Label
    end

    
    properties (Access = private)
        % Arduino specific variables
        arduinoBoard;
        % We don't want to initialize the arduino twice
        arduinoInitialized = false;
        
        % User specific variables
        userIndex;
        userSequence = zeros(1, 12);
        userAttempts;
        % we must be in game to do certain actions
        userHasStartedGame = false;
        
        % Game specific variables
        startingRound;
        endingRound;
        currentRound;
        roundSequence = zeros(1, 12);
        
        % note that roundnumber is also the number of leds that must be
        % pressed
        roundNumber;
        
        % a 1 x 12 vector of sounds
        sounds;
        soundsInitialized = false;
    end
    
    methods (Access = private)
        
        function valid = IsValidSession(app)
            
            flagU = app.UsernameEditField.Value == "username";
            flagP = app.PasswordEditField.Value == "password";
            
            flagA = app.AttemptsRemainingSpinner.Value < 1;
            
            if flagU && flagP
                if flagA
                    % if true, issue an error
                    app.StatusText.Value = "Attempts must be greater than 0!";
                    valid = false;
                    return;
                end
                app.WarningTextBox.Text = "";
                app.StatusText.Value = "Starting Game.";
                valid = true;
            else
                % don't write to the status bar, issue
                app.WarningTextBox.Text = "Invalid Username or Password!";
                valid = false;
            end
        end
        
        function InitGame(app)
            % Always handle ui first
            app.AttemptsRemainingSpinner.Enable = "off";
            app.NumberofRoundsSpinner.Enable = "off";
            app.NextRoundButton.Enable = "off";
            app.RepeatSequenceButton.Enable = "off";
            
            % Initialize sounds and the arduino if necessary
            if ~app.arduinoInitialized
                app.StatusText.Value = "Initializing Arduino.";
                % init arduino
                app.arduinoBoard = arduino();
                app.arduinoInitialized = true;
            end
            
            % Probably not necessary but best to do so anyways
            app.ClearArduino();
            
            % Load all sounds into a 1x12 vector
            if ~app.soundsInitialized
                app.StatusText.Value = "Initializing Sounds.";
                pause(0.5); % pause for effect
                
                s01 = audioread("Sounds/1.wav");
                s02 = audioread("Sounds/2.wav");
                s03 = audioread("Sounds/3.wav");
                s04 = audioread("Sounds/4.wav");
                s05 = audioread("Sounds/5.wav");
                s06 = audioread("Sounds/6.wav");
                s07 = audioread("Sounds/7.wav");
                s08 = audioread("Sounds/8.wav");
                s09 = audioread("Sounds/9.wav");
                s10 = audioread("Sounds/10.wav");
                s11 = audioread("Sounds/11.wav");
                s12 = audioread("Sounds/12.wav");
                
                app.sounds = {s01, s02, s03, s04, s05, s06, s07, s08, s09, s10, s11, s12};
                
                app.soundsInitialized = true;
            end
            

            % These variables must be reset everytime:
            
            % User specific variables
            app.userIndex = 1;
            app.userAttempts = app.AttemptsRemainingSpinner.Value;
            app.userHasStartedGame = true;
            
            % Game specific variables
            app.startingRound = 1;
            app.endingRound = app.NumberofRoundsSpinner.Value;
            app.currentRound = app.startingRound;
            
            app.roundNumber = app.startingRound;
            app.RoundNumberText.Value = app.roundNumber;
            
        end
        
        
        function StartGame(app)
            app.StatusText.Value = "Game Start!";
            
            app.EnableInput();
            
            % User cannot start the game twice
            app.StartGameButton.Enable = "off";
            % User can now quit the game
            app.QuitGameButton.Enable = "on";
            
            app.userHasStartedGame = true;
            
            % We just want to start the first round here in start game
            % later rounds will be started by the user using the next round
            % button
            app.CreateRoundSequence();
            app.PlayRoundSequence();
            
            % now it's up to the player
            app.StatusText.Value = "You have 1 input remaining.";
        end
        
        function QuitGame(app)
            % We do not really want to change any variables, that is done
            % in InitGame, we just want to reset the ui
            app.DisableInput();
            
            app.PasswordEditField.Value = "username";
            app.UsernameEditField.Value = "password";
            
            app.AttemptsRemainingSpinner.Value = 0;
            app.NumberofRoundsSpinner.Value = 3;
            
            app.CheckSequenceButton.Enable = "off";
            app.NextRoundButton.Enable = "off";
            app.RepeatSequenceButton.Enable = "off";
            
            app.StartGameButton.Enable = "on";
            app.QuitGameButton.Enable = "off";
            
            app.AttemptsRemainingSpinner.Enable = "on";
            app.NumberofRoundsSpinner.Enable = "on";
           
            app.RoundNumberText.Value = 0;
            
            % Clear the arduino and reset the game status
            app.ClearArduino();
            app.userHasStartedGame = false;
            clear sound;
        end
        
        function CreateRoundSequence(app)
            % Fill in the round sequence with random values
            for i = 1 : 12
                % get a random number [2, 13]
                app.roundSequence(i) = randi(12) + 1;
            end
        end
        
        % should be called after round sequence is generated
        function PlayRoundSequence(app)
            app.QuitGameButton.Enable = "off";
            % Let the user know that the sequence will be played in 2
            % seconds
            app.StatusText.Value = "Playing Sequence in 2 seconds.";
            pause(1);
            app.StatusText.Value = "Playing Sequence in 1 second.";
            pause(1);
            app.StatusText.Value = "Playing Sequence.";
            
            for i = 1 : app.roundNumber
                % turn off the light before, just in case it was already on, so the user can know if it flashed again
                pin = app.roundSequence(i);
                
                writeDigitalPin(app.arduinoBoard, "D" + pin, 0);
                pause(0.25);
                
                % play the sound here because we want to let the user know
                % that that led and sound has been played
                sound(app.sounds{pin - 1}, 44100);
                
                % here we must turn on the led and turn on the led
                writeDigitalPin(app.arduinoBoard, "D" + pin, 1);
                pause(0.25);
            end
            
            app.QuitGameButton.Enable = "on";
        end
        
        function StartNextRound(app)
            app.DisableInput();
            app.RepeatSequenceButton.Enable = "off";
            
            %% clear everything and get ready for the next round
            app.ClearArduino();
            
            % reset the user index
            app.userIndex = 1;
            
            app.roundNumber = app.roundNumber + 1;
            app.RoundNumberText.Value = app.roundNumber;
            
            % Play the new round sequence
            app.PlayRoundSequence();
            
            app.EnableInput();
            
            % now it's up to the player
            app.StatusText.Value = sprintf("You have %d inputs remaining.", app.roundNumber);
        end
        
        function AddToUserSequence(app, number)
            app.DisableInput();
            
            % this function cannot be called unelss we are in a game, so
            % all of the input buttons must be disabled
            
            % turn on the light and play the sound when the user presses
            % the button
            writeDigitalPin(app.arduinoBoard, "D" + number, 0);
            pause(0.25);
            
            % play the sound here because we want to let the user know
            % that that led and sound has been played
            sound(app.sounds{number - 1}, 44100);
            
            % here we must turn on the led and turn on the led
            writeDigitalPin(app.arduinoBoard, "D" + number, 1);
            pause(0.25);
            
            % at the index, place whatever number the user input
            app.userSequence(app.userIndex) = number;
            
            % If we have used all our inputs, then we check if our
            % sequence is correct
            if app.userIndex < app.roundNumber
                
                remaining = (app.roundNumber - app.userIndex);
                if remaining < 2
                    app.StatusText.Value = sprintf("You have 1 input remaining.");
                else
                    app.StatusText.Value = sprintf("You have %d inputs remaining.", remaining);
                end
                
                app.userIndex = app.userIndex + 1;
            else
                app.StatusText.Value = "Input complete! Check Sequence now available.";
                % we have put in all the required inputs
                % enable check button
                app.CheckSequenceButton.Enable = "on";
            end
            
            app.EnableInput();
        end
        
        function CheckSequence(app)
        
            % first check that the user has input all the required buttons
            if app.userIndex == app.roundNumber
                
                % check to see if the sequence is valid
                valid = true;
                for i = 1 : app.roundNumber
                    % If the sequence does not match even once, return false
                    % and exit from the loop
                    if app.userSequence(i) ~= app.roundSequence(i)
                       valid = false;
                       break;
                    end
                end
                
                if valid
                    % if correct sequence, continue to next round
                    app.StatusText.Value = "Correct Sequence! You may continue to next round.";
                    app.NextRoundButton.Enable = "on";
                    
                    if app.roundNumber == app.endingRound
                        % We have beat the game
                        app.DisableInput();
                        
                        app.StatusText.Value = "Congratulations! You have won the game!";
                        app.NextRoundButton.Enable = "off";
                        
                        app.PlayVictoryTheme();
                        
                        app.QuitGame();
                    end
                else 
                    app.StatusText.Value = "Incorrect Sequence! Try again.";
                    
                    % first check that they have attempts remaining
                    app.userAttempts = app.userAttempts - 1;
                    if app.userAttempts < 1
                        app.DisableInput();
                        
                        % we have run out of attempts, end the game
                        app.StatusText.Value = "Game Over! You have run out of attempts.";
                        
                        app.AttemptsRemainingSpinner.Value = 0;
                        
                        app.DisableInput();
                        
                        app.PlayDefeatTheme();
                        
                        app.QuitGame();
                        
                        return;
                    else
                        % we are safe to put this as a value
                        app.AttemptsRemainingSpinner.Value = app.userAttempts;
                    end
                    
                    % if they do, then we have come here, they can press
                    % this button to repeat the sequence
                    app.userIndex = 1;
                    app.RepeatSequenceButton.Enable = "on";
                end
            end
        end
        
        
        function PlayVictoryTheme(app)
            app.QuitGameButton.Enable = "off";
            
            app.ClearArduino();
            
            % Plays a small victory theme and the lights go all random
            % because I have no creativity!
            
            % we basically use the same code to generate a new round
            % sequence and play it
            randomSequence = zeros(1, 24);
            
            for i = 1 : 24
                % get a random number in [2, 13]
                randomSequence(i) = randi(12) + 1;
            end
            
            for i = 1 : 24
                % turn off the light before, just in case it was already on, so the user can know if it flashed again
                pin = randomSequence(i);
                writeDigitalPin(app.arduinoBoard, "D" + pin, 0);
                
                % play the sound here because we want to let the user know
                % that that led and sound has been played
                sound(app.sounds{pin - 1}, 44100);
                
                % here we must turn on the led and turn on the led
                writeDigitalPin(app.arduinoBoard, "D" + pin, 1);
            end
            
            app.ClearArduino();
        end
        
        function PlayDefeatTheme(app)
            app.QuitGameButton.Enable = "off";
            
            % Turn on all lights, then turn off lights row by row
            for i = 2 : 13
                writeDigitalPin(app.arduinoBoard, "D" + i, 1);
            end
            
            % Turn off lights row by row, playing a sound between each row
            for i = 13 : -1 : 2
                if i == 13
                    sound(app.sounds{4}, 44100);
                    pause(0.50);
                elseif i == 10
                    sound(app.sounds{3}, 44100);
                    pause(0.50);
                elseif i == 7
                    sound(app.sounds{2}, 44100);
                    pause(0.5);
                elseif i == 4
                    sound(app.sounds{1}, 44100);
                    pause(0.5);
                end
                
                writeDigitalPin(app.arduinoBoard, "D" + i, 0);
            end
            
            app.ClearArduino();
        end
        
        % % % % % % % % % % % % % % % % % % % % % % %         
        % % % % % % Miscellaneous functions 
        % % % % % % % % % % % % % % % % % % % % % % %         
        
        function EnableInput(app)
            app.SetInput("on");
        end
        
        function DisableInput(app)
            app.SetInput("off");
        end
        
        function SetInput(app, state)
            
            app.D2Button.Enable = state;
            app.D3Button.Enable = state;
            app.D4Button.Enable = state;
            app.D5Button.Enable = state;
            app.D6Button.Enable = state;
            app.D7Button.Enable = state;
            app.D8Button.Enable = state;
            app.D9Button.Enable = state;
            app.D10Button.Enable = state;
            app.D11Button.Enable = state;
            app.D12Button.Enable = state;
            app.D13Button.Enable = state;
            
        end
        
        function ClearArduino(app)
            % Set all pins to 0
            for i = 2 : 13
                writeDigitalPin(app.arduinoBoard, "D" + i, 0);
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: StartGameButton
        function OnStartPressed(app, event)
            
            if app.IsValidSession()
                app.StartGameButton.Enable = "off";
                app.InitGame();
                app.StartGame();
            end
            
        end

        % Button pushed function: QuitGameButton
        function OnQuitPressed(app, event)
            
            app.StatusText.Value = "Quit Game!";
            app.QuitGame();
            
        end

        % Button pushed function: D13Button
        function OnD13Pressed(app, event)
            
            app.AddToUserSequence(13);
            
        end

        % Button pushed function: D12Button
        function OnD12Pressed(app, event)

            app.AddToUserSequence(12);
            
        end

        % Button pushed function: D11Button
        function OnD11Pressed(app, event)
            
            app.AddToUserSequence(11);
            
        end

        % Button pushed function: D10Button
        function OnD10Pressed(app, event)
           
            app.AddToUserSequence(10); 
            
        end

        % Button pushed function: D9Button
        function OnD9Pressed(app, event)
            
            app.AddToUserSequence(9);
            
        end

        % Button pushed function: D8Button
        function OnD8Pressed(app, event)
            
            app.AddToUserSequence(8);
            
        end

        % Button pushed function: D7Button
        function OnD7Pressed(app, event)
            
            app.AddToUserSequence(7);
            
        end

        % Button pushed function: D6Button
        function OnD6Pressed(app, event)
            
            app.AddToUserSequence(6);
            
        end

        % Button pushed function: D5Button
        function OnD5Pressed(app, event)
            
            app.AddToUserSequence(5);
            
        end

        % Button pushed function: D4Button
        function OnD4Pressed(app, event)
            
            app.AddToUserSequence(4);
            
        end

        % Button pushed function: D3Button
        function OnD3Pressed(app, event)
            
            app.AddToUserSequence(3);
            
        end

        % Button pushed function: D2Button
        function OnD2Pressed(app, event)
            
            app.AddToUserSequence(2);
            
        end

        % Button pushed function: CheckSequenceButton
        function OnCheckSequencePressed(app, event)
            app.CheckSequenceButton.Enable = "off";
            % rather than calling this automatically when the user has put
            % in the max number of sequence values, the user will do so
            app.CheckSequence();
        end

        % Button pushed function: NextRoundButton
        function OnNextRoundPressed(app, event)
            % disable the button once pressed
            app.NextRoundButton.Enable = "off";
            %this function may only be called after the first round
            app.StartNextRound();
        end

        % Button pushed function: RepeatSequenceButton
        function OnRepeatSequencePressed(app, event)
            % disable
            app.RepeatSequenceButton.Enable = "off";
            
            % We just want to repeat the same sequence for the user because
            % the failed to replay the sequence
            app.ClearArduino();
            app.PlayRoundSequence();
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Color = [0.0745 0.6235 1];
            app.UIFigure.Position = [100 100 641 485];
            app.UIFigure.Name = 'MATLAB App';

            % Create MostGloriousTitleOfGloriousness
            app.MostGloriousTitleOfGloriousness = uilabel(app.UIFigure);
            app.MostGloriousTitleOfGloriousness.HorizontalAlignment = 'center';
            app.MostGloriousTitleOfGloriousness.WordWrap = 'on';
            app.MostGloriousTitleOfGloriousness.FontName = 'Comic Sans MS';
            app.MostGloriousTitleOfGloriousness.FontSize = 40;
            app.MostGloriousTitleOfGloriousness.Position = [1 406 640 80];
            app.MostGloriousTitleOfGloriousness.Text = 'Simon Says';

            % Create MenuPanel
            app.MenuPanel = uipanel(app.UIFigure);
            app.MenuPanel.TitlePosition = 'centertop';
            app.MenuPanel.Title = 'Menu';
            app.MenuPanel.BackgroundColor = [0.302 0.7451 0.9333];
            app.MenuPanel.FontName = 'Comic Sans MS';
            app.MenuPanel.Position = [8 34 246 373];

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.MenuPanel);
            app.GridLayout2.ColumnWidth = {'1x', '0.75x', '0.75x', '1x'};
            app.GridLayout2.RowHeight = {23, 23, '1x', 23, 23, '1x', 23, '1x', '1x', '1x'};
            app.GridLayout2.ColumnSpacing = 8.21333948771159;
            app.GridLayout2.Padding = [8.21333948771159 10 8.21333948771159 10];
            app.GridLayout2.BackgroundColor = [0.9412 0.9412 0.9412];

            % Create QuitGameButton
            app.QuitGameButton = uibutton(app.GridLayout2, 'push');
            app.QuitGameButton.ButtonPushedFcn = createCallbackFcn(app, @OnQuitPressed, true);
            app.QuitGameButton.FontName = 'Comic Sans MS';
            app.QuitGameButton.Enable = 'off';
            app.QuitGameButton.Layout.Row = 9;
            app.QuitGameButton.Layout.Column = [2 3];
            app.QuitGameButton.Text = 'Quit Game';

            % Create StartGameButton
            app.StartGameButton = uibutton(app.GridLayout2, 'push');
            app.StartGameButton.ButtonPushedFcn = createCallbackFcn(app, @OnStartPressed, true);
            app.StartGameButton.FontName = 'Comic Sans MS';
            app.StartGameButton.Layout.Row = 8;
            app.StartGameButton.Layout.Column = [2 3];
            app.StartGameButton.Text = 'Start Game';

            % Create NumberofRoundsSpinner
            app.NumberofRoundsSpinner = uispinner(app.GridLayout2);
            app.NumberofRoundsSpinner.Limits = [3 12];
            app.NumberofRoundsSpinner.FontName = 'Comic Sans MS';
            app.NumberofRoundsSpinner.Layout.Row = 4;
            app.NumberofRoundsSpinner.Layout.Column = [3 4];
            app.NumberofRoundsSpinner.Value = 3;

            % Create NumberofRoundsSpinnerLabel
            app.NumberofRoundsSpinnerLabel = uilabel(app.GridLayout2);
            app.NumberofRoundsSpinnerLabel.HorizontalAlignment = 'right';
            app.NumberofRoundsSpinnerLabel.Layout.Row = 4;
            app.NumberofRoundsSpinnerLabel.Layout.Column = [1 2];
            app.NumberofRoundsSpinnerLabel.Text = 'Number of Rounds';

            % Create AttemptsRemainingSpinner
            app.AttemptsRemainingSpinner = uispinner(app.GridLayout2);
            app.AttemptsRemainingSpinner.Limits = [0 5];
            app.AttemptsRemainingSpinner.FontName = 'Comic Sans MS';
            app.AttemptsRemainingSpinner.Layout.Row = 5;
            app.AttemptsRemainingSpinner.Layout.Column = [3 4];

            % Create AttemptsRemainingSpinnerLabel
            app.AttemptsRemainingSpinnerLabel = uilabel(app.GridLayout2);
            app.AttemptsRemainingSpinnerLabel.HorizontalAlignment = 'right';
            app.AttemptsRemainingSpinnerLabel.Layout.Row = 5;
            app.AttemptsRemainingSpinnerLabel.Layout.Column = [1 2];
            app.AttemptsRemainingSpinnerLabel.Text = 'Attempts Remaining';

            % Create UsernameEditFieldLabel
            app.UsernameEditFieldLabel = uilabel(app.GridLayout2);
            app.UsernameEditFieldLabel.HorizontalAlignment = 'right';
            app.UsernameEditFieldLabel.Layout.Row = 1;
            app.UsernameEditFieldLabel.Layout.Column = [1 2];
            app.UsernameEditFieldLabel.Text = 'Username';

            % Create UsernameEditField
            app.UsernameEditField = uieditfield(app.GridLayout2, 'text');
            app.UsernameEditField.FontName = 'Comic Sans MS';
            app.UsernameEditField.Layout.Row = 1;
            app.UsernameEditField.Layout.Column = [3 4];

            % Create PasswordEditFieldLabel
            app.PasswordEditFieldLabel = uilabel(app.GridLayout2);
            app.PasswordEditFieldLabel.HorizontalAlignment = 'right';
            app.PasswordEditFieldLabel.Layout.Row = 2;
            app.PasswordEditFieldLabel.Layout.Column = [1 2];
            app.PasswordEditFieldLabel.Text = 'Password';

            % Create PasswordEditField
            app.PasswordEditField = uieditfield(app.GridLayout2, 'text');
            app.PasswordEditField.FontName = 'Comic Sans MS';
            app.PasswordEditField.Layout.Row = 2;
            app.PasswordEditField.Layout.Column = [3 4];

            % Create WarningTextBox
            app.WarningTextBox = uilabel(app.GridLayout2);
            app.WarningTextBox.HorizontalAlignment = 'center';
            app.WarningTextBox.VerticalAlignment = 'top';
            app.WarningTextBox.FontName = 'Comic Sans MS';
            app.WarningTextBox.FontColor = [1 0 0];
            app.WarningTextBox.Layout.Row = 3;
            app.WarningTextBox.Layout.Column = [1 4];
            app.WarningTextBox.Text = '';

            % Create GameAreaPanel
            app.GameAreaPanel = uipanel(app.UIFigure);
            app.GameAreaPanel.TitlePosition = 'centertop';
            app.GameAreaPanel.Title = 'Game Area';
            app.GameAreaPanel.BackgroundColor = [0.302 0.7451 0.9333];
            app.GameAreaPanel.FontName = 'Comic Sans MS';
            app.GameAreaPanel.Position = [260 34 373 373];

            % Create GridLayout
            app.GridLayout = uigridlayout(app.GameAreaPanel);
            app.GridLayout.ColumnWidth = {'1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.GridLayout.RowHeight = {23, '0.5x', '1x', '1x', '1x', '1x', 34, 25};
            app.GridLayout.BackgroundColor = [0.9412 0.9412 0.9412];

            % Create RoundNumberEditFieldLabel
            app.RoundNumberEditFieldLabel = uilabel(app.GridLayout);
            app.RoundNumberEditFieldLabel.HorizontalAlignment = 'right';
            app.RoundNumberEditFieldLabel.Layout.Row = 1;
            app.RoundNumberEditFieldLabel.Layout.Column = [3 4];
            app.RoundNumberEditFieldLabel.Text = 'Round Number';

            % Create RoundNumberText
            app.RoundNumberText = uieditfield(app.GridLayout, 'numeric');
            app.RoundNumberText.FontName = 'Comic Sans MS';
            app.RoundNumberText.Layout.Row = 1;
            app.RoundNumberText.Layout.Column = 5;

            % Create D13Button
            app.D13Button = uibutton(app.GridLayout, 'push');
            app.D13Button.ButtonPushedFcn = createCallbackFcn(app, @OnD13Pressed, true);
            app.D13Button.IconAlignment = 'center';
            app.D13Button.FontName = 'Comic Sans MS';
            app.D13Button.FontColor = [1 0 0];
            app.D13Button.Enable = 'off';
            app.D13Button.Layout.Row = 3;
            app.D13Button.Layout.Column = 1;
            app.D13Button.Text = 'D13';

            % Create D12Button
            app.D12Button = uibutton(app.GridLayout, 'push');
            app.D12Button.ButtonPushedFcn = createCallbackFcn(app, @OnD12Pressed, true);
            app.D12Button.IconAlignment = 'center';
            app.D12Button.FontName = 'Comic Sans MS';
            app.D12Button.FontColor = [1 0 0];
            app.D12Button.Enable = 'off';
            app.D12Button.Layout.Row = 3;
            app.D12Button.Layout.Column = 2;
            app.D12Button.Text = 'D12';

            % Create D11Button
            app.D11Button = uibutton(app.GridLayout, 'push');
            app.D11Button.ButtonPushedFcn = createCallbackFcn(app, @OnD11Pressed, true);
            app.D11Button.IconAlignment = 'center';
            app.D11Button.FontName = 'Comic Sans MS';
            app.D11Button.FontColor = [1 0 0];
            app.D11Button.Enable = 'off';
            app.D11Button.Layout.Row = 3;
            app.D11Button.Layout.Column = 3;
            app.D11Button.Text = 'D11';

            % Create D10Button
            app.D10Button = uibutton(app.GridLayout, 'push');
            app.D10Button.ButtonPushedFcn = createCallbackFcn(app, @OnD10Pressed, true);
            app.D10Button.IconAlignment = 'center';
            app.D10Button.FontName = 'Comic Sans MS';
            app.D10Button.FontColor = [0 1 0];
            app.D10Button.Enable = 'off';
            app.D10Button.Layout.Row = 4;
            app.D10Button.Layout.Column = 1;
            app.D10Button.Text = 'D10';

            % Create D9Button
            app.D9Button = uibutton(app.GridLayout, 'push');
            app.D9Button.ButtonPushedFcn = createCallbackFcn(app, @OnD9Pressed, true);
            app.D9Button.IconAlignment = 'center';
            app.D9Button.FontName = 'Comic Sans MS';
            app.D9Button.FontColor = [0 1 0];
            app.D9Button.Enable = 'off';
            app.D9Button.Layout.Row = 4;
            app.D9Button.Layout.Column = 2;
            app.D9Button.Text = 'D9';

            % Create D8Button
            app.D8Button = uibutton(app.GridLayout, 'push');
            app.D8Button.ButtonPushedFcn = createCallbackFcn(app, @OnD8Pressed, true);
            app.D8Button.IconAlignment = 'center';
            app.D8Button.FontName = 'Comic Sans MS';
            app.D8Button.FontColor = [0 1 0];
            app.D8Button.Enable = 'off';
            app.D8Button.Layout.Row = 4;
            app.D8Button.Layout.Column = 3;
            app.D8Button.Text = 'D8';

            % Create D7Button
            app.D7Button = uibutton(app.GridLayout, 'push');
            app.D7Button.ButtonPushedFcn = createCallbackFcn(app, @OnD7Pressed, true);
            app.D7Button.IconAlignment = 'center';
            app.D7Button.FontName = 'Comic Sans MS';
            app.D7Button.FontColor = [0 0 1];
            app.D7Button.Enable = 'off';
            app.D7Button.Layout.Row = 5;
            app.D7Button.Layout.Column = 1;
            app.D7Button.Text = 'D7';

            % Create D6Button
            app.D6Button = uibutton(app.GridLayout, 'push');
            app.D6Button.ButtonPushedFcn = createCallbackFcn(app, @OnD6Pressed, true);
            app.D6Button.IconAlignment = 'center';
            app.D6Button.FontName = 'Comic Sans MS';
            app.D6Button.FontColor = [0 0 1];
            app.D6Button.Enable = 'off';
            app.D6Button.Layout.Row = 5;
            app.D6Button.Layout.Column = 2;
            app.D6Button.Text = 'D6';

            % Create D5Button
            app.D5Button = uibutton(app.GridLayout, 'push');
            app.D5Button.ButtonPushedFcn = createCallbackFcn(app, @OnD5Pressed, true);
            app.D5Button.IconAlignment = 'center';
            app.D5Button.FontName = 'Comic Sans MS';
            app.D5Button.FontColor = [0 0 1];
            app.D5Button.Enable = 'off';
            app.D5Button.Layout.Row = 5;
            app.D5Button.Layout.Column = 3;
            app.D5Button.Text = 'D5';

            % Create D4Button
            app.D4Button = uibutton(app.GridLayout, 'push');
            app.D4Button.ButtonPushedFcn = createCallbackFcn(app, @OnD4Pressed, true);
            app.D4Button.IconAlignment = 'center';
            app.D4Button.FontName = 'Comic Sans MS';
            app.D4Button.FontColor = [0.9294 0.6941 0.1255];
            app.D4Button.Enable = 'off';
            app.D4Button.Layout.Row = 6;
            app.D4Button.Layout.Column = 1;
            app.D4Button.Text = 'D4';

            % Create D3Button
            app.D3Button = uibutton(app.GridLayout, 'push');
            app.D3Button.ButtonPushedFcn = createCallbackFcn(app, @OnD3Pressed, true);
            app.D3Button.IconAlignment = 'center';
            app.D3Button.FontName = 'Comic Sans MS';
            app.D3Button.FontColor = [0.9294 0.6941 0.1255];
            app.D3Button.Enable = 'off';
            app.D3Button.Layout.Row = 6;
            app.D3Button.Layout.Column = 2;
            app.D3Button.Text = 'D3';

            % Create D2Button
            app.D2Button = uibutton(app.GridLayout, 'push');
            app.D2Button.ButtonPushedFcn = createCallbackFcn(app, @OnD2Pressed, true);
            app.D2Button.IconAlignment = 'center';
            app.D2Button.FontName = 'Comic Sans MS';
            app.D2Button.FontColor = [0.9294 0.6941 0.1255];
            app.D2Button.Enable = 'off';
            app.D2Button.Layout.Row = 6;
            app.D2Button.Layout.Column = 3;
            app.D2Button.Text = 'D2';

            % Create CheckSequenceButton
            app.CheckSequenceButton = uibutton(app.GridLayout, 'push');
            app.CheckSequenceButton.ButtonPushedFcn = createCallbackFcn(app, @OnCheckSequencePressed, true);
            app.CheckSequenceButton.Enable = 'off';
            app.CheckSequenceButton.Layout.Row = 3;
            app.CheckSequenceButton.Layout.Column = [5 7];
            app.CheckSequenceButton.Text = 'Check Sequence';

            % Create RepeatSequenceButton
            app.RepeatSequenceButton = uibutton(app.GridLayout, 'push');
            app.RepeatSequenceButton.ButtonPushedFcn = createCallbackFcn(app, @OnRepeatSequencePressed, true);
            app.RepeatSequenceButton.Enable = 'off';
            app.RepeatSequenceButton.Layout.Row = 4;
            app.RepeatSequenceButton.Layout.Column = [5 7];
            app.RepeatSequenceButton.Text = 'Repeat Sequence';

            % Create NextRoundButton
            app.NextRoundButton = uibutton(app.GridLayout, 'push');
            app.NextRoundButton.ButtonPushedFcn = createCallbackFcn(app, @OnNextRoundPressed, true);
            app.NextRoundButton.Enable = 'off';
            app.NextRoundButton.Layout.Row = 5;
            app.NextRoundButton.Layout.Column = [5 7];
            app.NextRoundButton.Text = 'Next Round';

            % Create StatusText
            app.StatusText = uieditfield(app.GridLayout, 'text');
            app.StatusText.FontName = 'Comic Sans MS';
            app.StatusText.Layout.Row = 8;
            app.StatusText.Layout.Column = [2 7];

            % Create StatusEditFieldLabel
            app.StatusEditFieldLabel = uilabel(app.GridLayout);
            app.StatusEditFieldLabel.HorizontalAlignment = 'right';
            app.StatusEditFieldLabel.FontName = 'Comic Sans MS';
            app.StatusEditFieldLabel.Layout.Row = 8;
            app.StatusEditFieldLabel.Layout.Column = 1;
            app.StatusEditFieldLabel.Text = 'Status';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = SimonSays

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
