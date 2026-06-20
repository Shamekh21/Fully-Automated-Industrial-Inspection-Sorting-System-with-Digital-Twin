function Robot_GUI()
    P = paths();
 
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%     FULLY AUTOMATED INDUSTRIAL INSPECTION & SORTING SYSTEM              %
%                     WITH DIGITAL TWIN TECHNOLOGY                        %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Course:
% MAE401 - Artificial Intelligence
%
% Faculty:
% Faculty of Engineering, Benha University
%
% Project Type:
% AI-Driven Cyber-Physical System (CPS)
% Industrial Inspection, Sorting, and Digital Twin Integration
%
% Project Description:
% This project presents a fully automated industrial inspection and
% sorting system integrating:
%
%   - Computer Vision
%   - Deep Learning (CNN)
%   - Robotics & Kinematics
%   - Optimization Algorithms
%   - Digital Twin Technology
%   - TCP/IP Industrial Communication
%   - Hardware-in-the-Loop (HIL)
%
% The system performs real-time defect detection on industrial casting
% components and automatically controls a UR5 robotic manipulator for
% intelligent pick-and-place operations.
%
% Team Members:
%   Mahmoud Shamekh
%   Omar Metwally
%   Omar Shokran
%   Mohamed Abdeltawab
%
% Academic Supervisor:
%   Dr. Amro Shafik
%
% Teaching Assistant:
%   Eng. Mohamed Nasser
%
% Technologies:
%   MATLAB
%   Python
%   PyTorch
%   CoppeliaSim
%   Arduino
%
% Year:
% Spring 2026
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    robot = loadrobot('universalUR5', 'DataFormat', 'column');
    endEffector = 'tool0';
    
    qHome_deg = [0, -90, 0, 0, 0, 0]; 
    qCurrent = deg2rad(qHome_deg(:));
    visionServer = [];
    
    % 🌟 CoppeliaSim Connection Setup 🌟
    vrep = remApi('remoteApi');
    vrep.simxFinish(-1);
    clientID = vrep.simxStart('127.0.0.1', 19000, true, true, 5000, 5);
    vrepConnected = (clientID > -1);
    jointHandles = zeros(1, 6);
    sensorHandle = -1;
    
    if vrepConnected
        disp('✅ SUCCESS: Connected to CoppeliaSim Real-Time Engine!');
        jointNames = {'joint1', 'joint2', 'joint3', 'joint4', 'joint5', 'joint6'};
        for i = 1:6
            [~, jointHandles(i)] = vrep.simxGetObjectHandle(clientID, jointNames{i}, vrep.simx_opmode_blocking);
        end
        vrep.simxSetIntegerSignal(clientID, 'gripper_status', 0, vrep.simx_opmode_oneshot);
        
        [res, sensorHandle] = vrep.simxGetObjectHandle(clientID, '/create_boxes/_sensor', vrep.simx_opmode_blocking);
        if res == vrep.simx_return_ok
            disp('✅ SUCCESS: Proximity Sensor Handle Acquired!');
        end
    else
        disp('⚠️ WARNING: CoppeliaSim not found. Running in MATLAB-Only Simulation Mode.');
    end
    
    isSequenceRunning = false;
    pathMemX = {}; pathMemY = {}; pathMemZ = {}; pathMemColor = {};
    moveCounter = 0; currentLineColor = 'b-';
    
    partVisible = false; partX = 0; partY = 0; partZ = 0;
    partColor = [0 0 0]; isCarryingPart = false;
    
    function clearPath()
        pathMemX = {}; pathMemY = {}; pathMemZ = {}; pathMemColor = {};
        moveCounter = 0; partVisible = false; 
    end

    fig = figure('Name', '🤖 6-DOF Robot AI Optimization Twin & CoppeliaSim', 'Position', [50, 50, 1300, 780], 'NumberTitle', 'off', 'MenuBar', 'none', 'Color', [0.94 0.95 0.97]);
    
   % 🌟 Sensor Monitoring Timer 🌟
    sensorTimer = timer('ExecutionMode', 'fixedRate', 'Period', 0.5, 'TimerFcn', @checkProximitySensor);

% 🌟 shutdown function for everything (works with the letter Q or the Exit button) 🌟
    set(fig, 'CloseRequestFcn', @closeApp);
    function closeApp(~, ~)
        disp('🛑 Initiating System Shutdown...');
        % 1. stop the timer
       
        try stop(sensorTimer); delete(sensorTimer); catch, end
        
        % 2.Python and TCP locking
        if ~isempty(visionServer) && isvalid(visionServer)
            try writeline(visionServer, "QUIT"); catch, end 
            delete(visionServer); 
        end
        
        % 3. Separate coppelia safely
        if vrepConnected
            vrep.simxFinish(clientID);
            vrep.delete();
        end
        
        % 4. Clear the interface
        delete(fig);
        disp('🛑 System fully terminated.');
    end

    panelPlot = uipanel('Parent', fig, 'Title', ' 3D Robot Live Simulation View ', 'FontSize', 12, 'FontWeight', 'bold', 'ForegroundColor', [0.1 0.2 0.3], 'Position', [0.48 0.02 0.50 0.96], 'BackgroundColor', [1 1 1]);
    ax = axes('Parent', panelPlot, 'Position', [0.05 0.05 0.90 0.90]);
    axis(ax, [-1 1 -1 1 -0.5 1.5]); grid(ax, 'on'); view(ax, 45, 30);
    show(robot, qCurrent, 'Parent', ax, 'PreservePlot', false);
    
    hold(ax, 'on'); drawEnvironment(ax); hold(ax, 'off');
    
    panelFK = uipanel('Parent', fig, 'Title', ' Forward Kinematics (Joint Space - Deg) ', 'FontSize', 11, 'FontWeight', 'bold', 'Position', [0.02 0.48 0.21 0.50]);
    y_pos = 0.85; dy = 0.13;
    for i = 1:6
        uicontrol('Parent', panelFK, 'Style', 'text', 'String', sprintf('Joint %d:', i), 'Units', 'normalized', 'Position', [0.08, y_pos, 0.32, 0.07], 'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'left');
        fk_inputs(i) = uicontrol('Parent', panelFK, 'Style', 'edit', 'String', num2str(qHome_deg(i)), 'Units', 'normalized', 'Position', [0.45, y_pos, 0.45, 0.08], 'FontSize', 11, 'FontWeight', 'bold');
        y_pos = y_pos - dy;
    end
    uicontrol('Parent', panelFK, 'Style', 'pushbutton', 'String', 'Move (FK)', 'Units', 'normalized', 'Position', [0.05, 0.02, 0.9, 0.08], 'FontSize', 12, 'BackgroundColor', [0.8 0.9 0.8], 'Callback', @runFK);

    panelIK = uipanel('Parent', fig, 'Title', ' Inverse Kinematics & AI Planners ', 'FontSize', 11, 'FontWeight', 'bold', 'Position', [0.24 0.48 0.22 0.50]);
    initialFrame = getTransform(robot, qCurrent, endEffector); eul_rad_init = rotm2eul(initialFrame(1:3, 1:3), 'ZYX'); eul_deg_init = rad2deg(eul_rad_init);
    labels_ik = {'X Target (mm):', 'Y Target (mm):', 'Z Target (mm):', 'Roll Angle (Deg):', 'Pitch Angle (Deg):', 'Yaw Angle (Deg):'};
    defaults_ik = {num2str(initialFrame(1,4)*1000, '%.1f'), num2str(initialFrame(2,4)*1000, '%.1f'), num2str(initialFrame(3,4)*1000, '%.1f'), num2str(eul_deg_init(3), '%.2f'), num2str(eul_deg_init(2), '%.2f'), num2str(eul_deg_init(1), '%.2f')};    
    y_pos_ik = 0.86; dy_ik = 0.09; 
    for i = 1:6
        uicontrol('Parent', panelIK, 'Style', 'text', 'String', labels_ik{i}, 'Units', 'normalized', 'Position', [0.05, y_pos_ik, 0.42, 0.06], 'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'left');
        ik_inputs(i) = uicontrol('Parent', panelIK, 'Style', 'edit', 'String', defaults_ik{i}, 'Units', 'normalized', 'Position', [0.50, y_pos_ik, 0.45, 0.07], 'FontSize', 11, 'FontWeight', 'bold');
        y_pos_ik = y_pos_ik - dy_ik;
    end
    
    uicontrol('Parent', panelIK, 'Style', 'pushbutton', 'String', 'Traditional Analytical (Math IK)', 'Units', 'normalized', 'Position', [0.05, 0.28, 0.9, 0.055], 'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', [0.82 0.84 0.88], 'Callback', @runIK);
    uicontrol('Parent', panelIK, 'Style', 'pushbutton', 'String', 'Genetic Algorithm (GA)', 'Units', 'normalized', 'Position', [0.05, 0.22, 0.9, 0.055], 'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', [1 0.88 0.75], 'Callback', @runAI_GA);
    uicontrol('Parent', panelIK, 'Style', 'pushbutton', 'String', 'Simulated Annealing (SA)', 'Units', 'normalized', 'Position', [0.05, 0.16, 0.9, 0.055], 'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', [0.75 0.88 1], 'Callback', @runSA);
    uicontrol('Parent', panelIK, 'Style', 'pushbutton', 'String', 'Hill Climbing (Pattern Search)', 'Units', 'normalized', 'Position', [0.05, 0.10, 0.9, 0.055], 'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', [0.82 0.95 0.82], 'Callback', @runPatternSearch);
    uicontrol('Parent', panelIK, 'Style', 'pushbutton', 'String', 'Particle Swarm Intelligence (PSO)', 'Units', 'normalized', 'Position', [0.05, 0.04, 0.9, 0.055], 'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', [0.92 0.82 0.98], 'Callback', @runPSO);

    panelNet = uipanel('Parent', fig, 'Title', ' System Integration & Networking ', 'FontSize', 11, 'FontWeight', 'bold', 'Position', [0.02 0.36 0.44 0.10]);
    uicontrol('Parent', panelNet, 'Style', 'pushbutton', 'String', '📡 Connect to Python Vision Network Server', 'Units', 'normalized', 'Position', [0.04, 0.20, 0.92, 0.60], 'FontSize', 11, 'FontWeight', 'bold', 'ForegroundColor', [1 1 1], 'BackgroundColor', [0.12 0.53 0.28], 'Callback', @startPythonServer);

    panelConsole = uipanel('Parent', fig, 'Title', ' System Diagnostics Log & Benchmarks ', 'FontSize', 11, 'FontWeight', 'bold', 'Position', [0.02 0.02 0.44 0.32]);
    logConsole = uicontrol('Parent', panelConsole, 'Style', 'listbox', 'Units', 'normalized', 'Position', [0.03 0.28 0.94 0.66], 'FontSize', 11, 'FontName', 'Consolas', 'ForegroundColor', [0.05 0.10 0.30], 'String', {'[SYSTEM] Ready to accept local or network commands...'});
    uicontrol('Parent', panelConsole, 'Style', 'pushbutton', 'String', '🏆 Run ALL & Benchmark Best', 'Units', 'normalized', 'Position', [0.03, 0.04, 0.46, 0.18], 'FontSize', 11, 'FontWeight', 'bold', 'ForegroundColor', [1 1 1], 'BackgroundColor', [0.78 0.15 0.15], 'Callback', @runAllAndPickBest);
    uicontrol('Parent', panelConsole, 'Style', 'pushbutton', 'String', '🏠 Reset Home', 'Units', 'normalized', 'Position', [0.52, 0.04, 0.21, 0.18], 'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', [0.88 0.92 0.96], 'Callback', @goHome);
    
    % 🌟 Modified the Exit button to use the global shutdown function 🌟
    uicontrol('Parent', panelConsole, 'Style', 'pushbutton', 'String', '🛑 Exit', 'Units', 'normalized', 'Position', [0.75, 0.04, 0.22, 0.18], 'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', [0.94 0.82 0.82], 'Callback', @closeApp);

    function logMsg(msg)
        currentLog = get(logConsole, 'String'); currentLog{end+1} = msg;
        set(logConsole, 'String', currentLog); set(logConsole, 'Value', length(currentLog)); drawnow limitrate; 
    end

    function startPythonServer(~, ~)
        try
            if ~isempty(visionServer) && isvalid(visionServer), delete(visionServer); end
            clear visionServer;
            visionServer = tcpserver("127.0.0.1", 65432); 
            configureTerminator(visionServer, "CR/LF"); 
            configureCallback(visionServer, "terminator", @receivePythonData);
            logMsg('🟢 [NET] TCP Server listening... Run Python Code now!');
            
            start(sensorTimer);
        catch ME
            logMsg(['❌ [NET] Server initialization failed: ' ME.message]);
        end
    end

    function checkProximitySensor(~, ~)
        if vrepConnected && ~isSequenceRunning && ~isempty(visionServer) && isvalid(visionServer)
            [res, detectionState, ~, ~, ~] = vrep.simxReadProximitySensor(clientID, sensorHandle, vrep.simx_opmode_blocking);
            if res == vrep.simx_return_ok && detectionState > 0
                try
                    isSequenceRunning = true; 
                    writeline(visionServer, "TRIGGER");
                    logMsg('🎯 Sensor Triggered! Requesting Python AI analysis...');
                catch
                    isSequenceRunning = false; 
                end
            end
        end
    end

    function receivePythonData(src, ~)
        try
            if src.NumBytesAvailable > 0
                dataStr = readline(src);
                if isempty(dataStr) || dataStr == "", return; end
               
                % 🌟 Receiving the STOP_SYSTEM command from Python and closing the program 🌟
                if contains(dataStr, 'STOP_SYSTEM')
                    logMsg('🛑 [NET] Python requested Full Shutdown. Closing system...');
                    closeApp();
                    return;
                end
                
                logMsg(['📥 [NET] Python Packet: ' char(dataStr)]);
                
                coords = str2double(split(dataStr, ','));
                if length(coords) >= 3
                    if length(coords) >= 4, class_id = coords(4); else
                        if coords(2) < 0, class_id = 0; else, class_id = 1; end
                    end
                    executePickAndPlace(coords, class_id);
                end
            end
        catch ME
            logMsg(['❌ [NET] Packet decoding error: ' ME.message]);
            isSequenceRunning = false; 
        end
    end

    function executePickAndPlace(placeCoords, class_id)
        clearPath();
        pickX = 250.0; pickY = 0.0; pickZ = 150.0;
        
        if class_id == 0 
            partColor = [0.8 0 0]; placeLineColor = 'r-'; statusMsg = 'DEFECTIVE (Red Bin)'; placeCoords(2) = -500.0; 
        else 
            partColor = [0 0.8 0]; placeLineColor = 'g-'; statusMsg = 'OK (Green Bin)'; placeCoords(2) = 500.0; 
        end
        
        logMsg('==================================================');
        logMsg(sprintf('📦 [SEQUENCE] Verified Route: %s', statusMsg));
        
        partX = pickX/1000; partY = pickY/1000; partZ = pickZ/1000;
        partVisible = true; isCarryingPart = false;
        
        hold(ax, 'on'); drawEnvironment(ax);
        scatter3(ax, partX, partY, partZ, 1200, 's', 'filled', 'MarkerFaceColor', partColor, 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
        hold(ax, 'off'); drawnow;
        
        logMsg(sprintf('🤖 [STEP 1] Moving to Pick Position (X:%.1f, Y:%.1f, Z:%.1f)...', pickX, pickY, pickZ));
        currentLineColor = 'b-'; 
        set(ik_inputs(1), 'String', num2str(pickX)); set(ik_inputs(2), 'String', num2str(pickY)); set(ik_inputs(3), 'String', num2str(pickZ));
        drawnow; runIK([], []); 
        
        logMsg('🧲 [GRASP] Picking up the component...');
        isCarryingPart = true; 
        if vrepConnected, vrep.simxSetIntegerSignal(clientID, 'gripper_status', 1, vrep.simx_opmode_oneshot); end
        pause(1.5);
        
        logMsg(sprintf('🤖 [STEP 2] Optimizing path to Place Position (X:%.1f, Y:%.1f, Z:%.1f)...', placeCoords(1), placeCoords(2), placeCoords(3)));
        currentLineColor = placeLineColor; 
        set(ik_inputs(1), 'String', num2str(placeCoords(1))); set(ik_inputs(2), 'String', num2str(placeCoords(2))); set(ik_inputs(3), 'String', num2str(placeCoords(3)));
        drawnow; runAllAndPickBest([], []); 
        
        logMsg('👐 [RELEASE] Dropping the component in designated bin...');
        isCarryingPart = false; 
        if vrepConnected, vrep.simxSetIntegerSignal(clientID, 'gripper_status', 0, vrep.simx_opmode_oneshot); end
        pause(1.5);
        
        logMsg('🤖 [STEP 3] Returning to Home position...');
        currentLineColor = 'k-'; goHome([], []);
        logMsg('✅ [SEQUENCE] Cycle Complete! Waiting for next part...');
        logMsg('--------------------------------------------------');
        
        isSequenceRunning = false;
    end

    function animateRobot(qTarget_rad)
        numSteps = 40; [qMatrix, ~, ~] = trapveltraj([qCurrent, qTarget_rad], numSteps);
        moveCounter = moveCounter + 1; currColor = currentLineColor; 
        currX = zeros(1, numSteps); currY = zeros(1, numSteps); currZ = zeros(1, numSteps);
        
        vrep_offset_rad = [0; pi/2; 0; 0; 0; 0];
        
        for k = 1:numSteps
            T = getTransform(robot, qMatrix(:, k), endEffector);
            currX(k) = T(1,4); currY(k) = T(2,4); currZ(k) = T(3,4);
            
            if vrepConnected
                for j = 1:6
                    target_joint_val = qMatrix(j, k) + vrep_offset_rad(j);
                    vrep.simxSetJointTargetPosition(clientID, jointHandles(j), target_joint_val, vrep.simx_opmode_oneshot);
                end
            end
            
            show(robot, qMatrix(:, k), 'Parent', ax, 'PreservePlot', false); hold(ax, 'on');
            drawEnvironment(ax);
            for p = 1:(moveCounter-1), plot3(ax, pathMemX{p}, pathMemY{p}, pathMemZ{p}, pathMemColor{p}, 'LineWidth', 2.5); end
            plot3(ax, currX(1:k), currY(1:k), currZ(1:k), currColor, 'LineWidth', 2.5);
            
            if partVisible
                if isCarryingPart
                    partX = currX(k); partY = currY(k); partZ = currZ(k) - 0.05; 
                end
                scatter3(ax, partX, partY, partZ, 1200, 's', 'filled', 'MarkerFaceColor', partColor, 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
            end
            hold(ax, 'off'); drawnow;
        end
        
        pathMemX{moveCounter} = currX; pathMemY{moveCounter} = currY; pathMemZ{moveCounter} = currZ; pathMemColor{moveCounter} = currColor;
        qCurrent = qTarget_rad; 
    end

    function drawEnvironment(axesHandle)
        drawBin(axesHandle, 250, 500, 0, 100, [0 0.7 0], 'OK Line');         
        drawBin(axesHandle, 250, -500, 0, 100, [0.8 0 0], 'Scrap Bin');      
        drawBin(axesHandle, 250, 0, 0, 100, [0.4 0.4 0.5], 'Conveyor Pick'); 
    end

    function drawBin(ax, x, y, z, h_mm, c, labelText)
        w = 0.2; l = 0.3; h = h_mm/1000; 
        x0 = x/1000 - w/2; x1 = x/1000 + w/2; y0 = y/1000 - l/2; y1 = y/1000 + l/2; z0 = z/1000; z1 = z/1000 + h;
        v = [x0 y0 z0; x1 y0 z0; x1 y1 z0; x0 y1 z0; x0 y0 z1; x1 y0 z1; x1 y1 z1; x0 y1 z1];
        f = [1 2 3 4; 1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8];
        patch('Parent', ax, 'Vertices', v, 'Faces', f, 'FaceColor', c, 'FaceAlpha', 0.15, 'EdgeColor', c, 'LineWidth', 1.5);
        text(ax, x/1000, y/1000, z1+0.05, labelText, 'Color', c, 'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    end

    function runFK(~, ~)
        if ~isSequenceRunning, clearPath(); currentLineColor = 'm-'; end
        logMsg('--------------------------------------------------'); logMsg('[FK] Command Received. Processing Forward Kinematics...');
        qTarget_deg = zeros(6,1); for j = 1:6, qTarget_deg(j) = str2double(get(fk_inputs(j), 'String')); end
        qTarget_rad = deg2rad(qTarget_deg); finalFrame = getTransform(robot, qTarget_rad, endEffector); eul_rad_out = rotm2eul(finalFrame(1:3, 1:3), 'ZYX'); eul_deg_out = rad2deg(eul_rad_out);
        X_mm = finalFrame(1,4)*1000; Y_mm = finalFrame(2,4)*1000; Z_mm = finalFrame(3,4)*1000;
        set(ik_inputs(1), 'String', num2str(X_mm, '%.1f')); set(ik_inputs(2), 'String', num2str(Y_mm, '%.1f')); set(ik_inputs(3), 'String', num2str(Z_mm, '%.1f'));
        set(ik_inputs(4), 'String', num2str(eul_deg_out(3), '%.2f')); set(ik_inputs(5), 'String', num2str(eul_deg_out(2), '%.2f')); set(ik_inputs(6), 'String', num2str(eul_deg_out(1), '%.2f')); 
        animateRobot(qTarget_rad);
        logMsg('✅ [FK] Transformation matrix computed.');
    end

    function runIK(~, ~)
        if ~isSequenceRunning, clearPath(); currentLineColor = 'm-'; end
        logMsg('--------------------------------------------------'); logMsg('[IK] Executing Traditional Analytical Solver...'); drawnow;
        targetPos = [str2double(get(ik_inputs(1),'String')) / 1000; str2double(get(ik_inputs(2),'String')) / 1000; str2double(get(ik_inputs(3),'String')) / 1000];
        roll_rad  = deg2rad(str2double(get(ik_inputs(4),'String'))); pitch_rad = deg2rad(str2double(get(ik_inputs(5),'String'))); yaw_rad   = deg2rad(str2double(get(ik_inputs(6),'String')));
        targetFrame = eul2tform([yaw_rad, pitch_rad, roll_rad]); targetFrame(1:3, 4) = targetPos;
        ik = inverseKinematics('RigidBodyTree', robot); ik.SolverParameters.MaxIterations = 1500;
        tic; [qCalc, solInfo] = ik(endEffector, targetFrame, [1 1 1 1 1 1], qCurrent); execTime = toc;
        if solInfo.PoseErrorNorm > 1e-3, logMsg('❌ [IK] Operational space target unreachable.'); return; end
        best_q_deg = rad2deg(qCalc); for j = 1:6, set(fk_inputs(j), 'String', num2str(best_q_deg(j), '%.2f')); end
        animateRobot(qCalc); logMsg(sprintf('✅ [IK] Done. (Time: %.3f s)', execTime));
    end

    function goHome(~, ~)
        if ~isSequenceRunning, clearPath(); currentLineColor = 'k-'; end
        qHome_rad = deg2rad(qHome_deg(:)); for j = 1:6, set(fk_inputs(j), 'String', num2str(qHome_deg(j), '%.2f')); end
        homeFrame = getTransform(robot, qHome_rad, endEffector); eul_rad_home = rotm2eul(homeFrame(1:3, 1:3), 'ZYX'); eul_deg_home = rad2deg(eul_rad_home);
        set(ik_inputs(1), 'String', num2str(homeFrame(1,4)*1000, '%.1f')); set(ik_inputs(2), 'String', num2str(homeFrame(2,4)*1000, '%.1f')); set(ik_inputs(3), 'String', num2str(homeFrame(3,4)*1000, '%.1f'));
        set(ik_inputs(4), 'String', num2str(eul_deg_home(3), '%.2f')); set(ik_inputs(5), 'String', num2str(eul_deg_home(2), '%.2f')); set(ik_inputs(6), 'String', num2str(eul_deg_home(1), '%.2f'));
        animateRobot(qHome_rad);
    end

    function runAI_GA(~, ~), logMsg('--------------------------------------------------'); logMsg('🧠 [GA] Initializing Genetic Algorithm Search...'); drawnow; runOptimization('ga'); end
    function runSA(~, ~), logMsg('--------------------------------------------------'); logMsg('🔥 [SA] Initializing Simulated Annealing Search...'); drawnow; runOptimization('sa'); end
    function runPatternSearch(~, ~), logMsg('--------------------------------------------------'); logMsg('⛰️ [PS] Initializing Hill Climbing Core...'); drawnow; runOptimization('ps'); end
    function runPSO(~, ~), logMsg('--------------------------------------------------'); logMsg('✨ [PSO] Initializing Particle Swarm Optimization...'); drawnow; runOptimization('pso'); end

    function runOptimization(algorithmType)
        if ~isSequenceRunning, clearPath(); currentLineColor = 'm-'; end
        targetPos = [str2double(get(ik_inputs(1),'String')) / 1000; str2double(get(ik_inputs(2),'String')) / 1000; str2double(get(ik_inputs(3),'String')) / 1000];
        qCurrent_deg = rad2deg(qCurrent); lb = [-180, -180, -180, -180, -180, -180]; ub = [ 180,  180,  180,  180,  180,  180];
        objFcn = @(q_deg) advancedFitnessFunctionDeg(q_deg, targetPos, qCurrent_deg);
        try
            tic;
            switch algorithmType
                case 'ga', opt = optimoptions('ga', 'Display', 'off', 'PopulationSize', 60, 'MaxGenerations', 40); [best_q_deg, finalCost] = ga(objFcn, 6, [], [], [], [], lb, ub, [], opt);
                case 'sa', opt = optimoptions('simulannealbnd', 'Display', 'off', 'MaxIterations', 1500); [best_q_deg, finalCost] = simulannealbnd(objFcn, qCurrent_deg', lb, ub, opt);
                case 'ps', opt = optimoptions('patternsearch', 'Display', 'off'); [best_q_deg, finalCost] = patternsearch(objFcn, qCurrent_deg', [], [], [], [], lb, ub, [], opt);
                case 'pso', opt = optimoptions('particleswarm', 'Display', 'off', 'SwarmSize', 100, 'MaxIterations', 100); [best_q_deg, finalCost] = particleswarm(objFcn, 6, lb, ub, opt);
            end
            execTime = toc; best_q_rad = deg2rad(best_q_deg(:));
            for j = 1:6, set(fk_inputs(j), 'String', num2str(best_q_deg(j), '%.2f')); end
            animateRobot(best_q_rad);
            logMsg(sprintf('✅ [OPTIMIZE] Trajectory converged. Cost: %.2f | Time: %.3f s', finalCost, execTime));
        catch ME
            logMsg(['❌ [OPTIMIZE] Resolution failed: ' ME.message]);
        end
    end

    function runAllAndPickBest(~, ~)
        if ~isSequenceRunning, clearPath(); currentLineColor = 'm-'; end
        logMsg('--------------------------------------------------'); logMsg('⏳ [BENCHMARK] Computing state spaces across all heuristics...'); drawnow;
        targetPos = [str2double(get(ik_inputs(1),'String')) / 1000; str2double(get(ik_inputs(2),'String')) / 1000; str2double(get(ik_inputs(3),'String')) / 1000];
        qCurrent_deg = rad2deg(qCurrent); lb = [-180, -180, -180, -180, -180, -180]; ub = [ 180,  180,  180,  180,  180,  180];
        objFcn = @(q_deg) advancedFitnessFunctionDeg(q_deg, targetPos, qCurrent_deg);
        costs = zeros(1,5); times = zeros(1,5); solutions_deg = zeros(6,5); methods = {'Traditional Math', 'GA', 'SA', 'Hill Climbing', 'PSO'};
        
        tFrame = eul2tform([deg2rad(str2double(get(ik_inputs(6),'String'))), deg2rad(str2double(get(ik_inputs(5),'String'))), deg2rad(str2double(get(ik_inputs(4),'String')))]); tFrame(1:3, 4) = targetPos;
        ik = inverseKinematics('RigidBodyTree', robot); tic; [qCalc_trad, ~] = ik(endEffector, tFrame, [1 1 1 1 1 1], qCurrent); times(1) = toc; solutions_deg(:,1) = rad2deg(qCalc_trad); costs(1) = objFcn(solutions_deg(:,1));
        opt_ga = optimoptions('ga', 'Display', 'off', 'PopulationSize', 50, 'MaxGenerations', 30); tic; [q_ga, cost_ga] = ga(objFcn, 6, [], [], [], [], lb, ub, [], opt_ga); times(2) = toc; solutions_deg(:,2) = q_ga(:); costs(2) = cost_ga;
        opt_sa = optimoptions('simulannealbnd', 'Display', 'off', 'MaxIterations', 1000); tic; [q_sa, cost_sa] = simulannealbnd(objFcn, qCurrent_deg', lb, ub, opt_sa); times(3) = toc; solutions_deg(:,3) = q_sa(:); costs(3) = cost_sa;
        opt_ps = optimoptions('patternsearch', 'Display', 'off'); tic; [q_ps, cost_ps] = patternsearch(objFcn, qCurrent_deg', [], [], [], [], lb, ub, [], opt_ps); times(4) = toc; solutions_deg(:,4) = q_ps(:); costs(4) = cost_ps;
        opt_pso = optimoptions('particleswarm', 'Display', 'off', 'SwarmSize', 80, 'MaxIterations', 80); tic; [q_pso, cost_pso] = particleswarm(objFcn, 6, lb, ub, opt_pso); times(5) = toc; solutions_deg(:,5) = q_pso(:); costs(5) = cost_pso;
        
        [~, bestIdx] = min(costs); bestMethodName = methods{bestIdx}; best_q_deg = solutions_deg(:, bestIdx);
        for k = 1:5, logMsg(sprintf('   -> %s: Cost Metrics: %.2f | Exec Time: %.3f s', methods{k}, costs(k), times(k))); end
        logMsg('--------------------------------------------------');
        logMsg(sprintf('🏆 WINNER SELECTION: [%s] optimized trajectory limits!', bestMethodName));
        for j = 1:6, set(fk_inputs(j), 'String', num2str(best_q_deg(j), '%.2f')); end
        animateRobot(deg2rad(best_q_deg));
    end

    function cost = advancedFitnessFunctionDeg(q_deg, targetPos, qCurrent_deg)
        q_col_rad = deg2rad(q_deg(:)); tform = getTransform(robot, q_col_rad, endEffector); posError = norm(tform(1:3, 4) - targetPos); 
        jointMovement = sum(abs(q_deg(:) - qCurrent_deg(:))); torquePenalty = sum([5; 4; 3; 1; 1; 1] .* abs(q_deg(:) - qCurrent_deg(:)));
        W_pos = 1000; W_move = 0.05; W_torque = 0.02; cost = (W_pos * posError) + (W_move * jointMovement) + (W_torque * torquePenalty);
    end
end
