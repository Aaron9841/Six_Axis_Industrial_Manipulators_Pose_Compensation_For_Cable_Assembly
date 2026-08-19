% ======================================================
% ABB IRB 1090：R/L/U/D 四方向 TCP 歪斜補償批次 IK
%
% RTR_i 對應 R_i：實際 TCP 繞 Z 軸 +10 deg，MATLAB 用 Rz(-10)
% RTL_i 對應 L_i：實際 TCP 繞 Z 軸 -10 deg，MATLAB 用 Rz(+10)
% RTU_i 對應 U_i：實際 TCP 繞 Y 軸 -10 deg，MATLAB 用 Ry(+10)
% RTD_i 對應 D_i：實際 TCP 繞 Y 軸 +10 deg，MATLAB 用 Ry(-10)
%
% 每個 RT 點都視為第 1 點，也就是上排最左上角
% 每組產生 10 點：
% 上排 5 點：Y 每點減少 3 mm
% 下排 5 點：Z 減少 3 mm，Y 同樣每點減少 3 mm
%
% 不畫圖，只在 Command Window 顯示 6 軸角度與 FK 回算誤差
% ======================================================

clear; clc; close all;

deg = pi/180;
mm  = 0.001;

%% 1. 模型建立 (Modified DH)
L(1)=Link([0, 0.327, 0, 0*deg], 'modified');
L(2)=Link([0, 0, 0, -90*deg], 'modified');
L(3)=Link([0, 0, 0.280, 0*deg], 'modified');
L(4)=Link([0, 0.300, 0.010, -90*deg], 'modified');
L(5)=Link([0, 0, 0, 90*deg], 'modified');
L(6)=Link([0, 0.064, 0, -90*deg], 'modified');

L(2).offset = -90*deg;
L(6).offset = 180*deg;

irb1090 = SerialLink(L, 'name', 'IRB 1090');

%% 2. 目標點資料 RT 系列
% 格式：
% [X, Y, Z, q1, q2, q3, q4]
%
% 注意：
% RTL_1 使用你這次程式碼中的最新值：
% [512.88, 46.6, 216.08, 0.00046, 0.00004, -1, 0.00002]

RT.RTR_1 = [509.47, 45.86, 213.05, 0.0400946, 0.14137,  -0.989101, 0.00929991];
RT.RTR_2 = [529.56, 50.92, 190.69, 0.0302357, 0.141456, -0.989451, 0.00789965];
RT.RTR_3 = [511.25, 46.34, 215.66, 0.00335138,0.141616, -0.989908, 0.00406361];

RT.RTL_1 = [512.88, 46.60, 216.08, 0.00046,    0.00004,  -1.000000, 0.00002];
RT.RTL_2 = [514.55, 46.99, 216.47, 0.0170767, -0.0000484304, 0.999854, 0.0000537404];
RT.RTL_3 = [512.71, 46.26, 216.69, 0.0206254,  0.0000476966,-0.999787, 0.00000746204];

RT.RTU_1 = [508.32, 46.61, 214.91, 0.0292126,  0.0000418648,-0.999573, -0.0000166081];
RT.RTU_2 = [508.68, 45.26, 215.07, 0.0542293,  0.0000419547,-0.998528, -0.000093051];
RT.RTU_3 = [501.14, 46.23, 222.93, 0.0291111,  0.0000459027,-0.999576,  0.00012303];

RT.RTD_1 = [509.44, 45.64, 216.02, 0.0607206, -0.0289147, 0.997715, -0.0065038];
RT.RTD_2 = [510.64, 45.18, 216.33, 0.0683737, -0.0290229, 0.997224, -0.00516438];
RT.RTD_3 = [515.19, 44.38, 212.29, 0.0166574, -0.0287193, 0.999426, -0.00670302];

%% 3. TCP 校正資料 R/L/U/D 系列
% 格式：
% [X, Y, Z, Rx, Ry, Rz]
%
% X/Y/Z 單位 mm
% Rx/Ry/Rz 單位 degree

TCP.R_1 = [ 4.772, -8.508, 79.327, -179.997, 83.914, -180.000];
TCP.R_2 = [27.628, -9.126, 99.480, -179.996, 85.056,  180.000];
TCP.R_3 = [ 2.207, -8.565, 81.227, -179.995, 88.168, -180.000];

TCP.L_1 = [1.136, 5.951, 81.994, -179.995, 89.053, -180.000];
TCP.L_2 = [1.774, 5.841, 83.649,   -0.004, 88.937,    0.000];
TCP.L_3 = [1.520, 5.119, 81.819, -179.998, 86.742,  180.000];

TCP.U_1 = [-1.982, -0.496, 77.527,  0.006, 84.358, 0.000];
TCP.U_2 = [-2.195, -1.844, 77.855, -0.002, 87.227, 0.000];
TCP.U_3 = [-8.777, -0.870, 69.182,  0.022, 84.346, 0.000];

TCP.D_1 = [ 8.959, -1.391, 75.646, -179.869, 80.467,  180.000];
TCP.D_2 = [ 9.007, -1.925, 76.855, -179.998, 81.349, -180.000];
TCP.D_3 = [14.165, -2.930, 80.023, -179.993, 75.415,  180.000];

%% 4. 實驗組合設定
% 欄位：
% Direction, ExpID, TargetName, ToolName, Axis, MatlabCompAngleDeg
%
% 注意：
% MatlabCompAngleDeg 已經是「反向後」要放進 MATLAB 的角度。

caseData = {
    'R', 1, 'RTR_1', 'R_1', 'z', -10;
    'R', 2, 'RTR_2', 'R_2', 'z', -10;
    'R', 3, 'RTR_3', 'R_3', 'z', -10;

    'L', 1, 'RTL_1', 'L_1', 'z',  10;
    'L', 2, 'RTL_2', 'L_2', 'z',  10;
    'L', 3, 'RTL_3', 'L_3', 'z',  10;

    'U', 1, 'RTU_1', 'U_1', 'y', -10;
    'U', 2, 'RTU_2', 'U_2', 'y', -10;
    'U', 3, 'RTU_3', 'U_3', 'y', -10;

    'D', 1, 'RTD_1', 'D_1', 'y', 10;
    'D', 2, 'RTD_2', 'D_2', 'y', 10;
    'D', 3, 'RTD_3', 'D_3', 'y', 10;
};

%% 5. 10 點排列設定
num_layer = 2;
num_col   = 5;

y_step_mm     = -3;          % 每點 Y 減少 3 mm
layer_step_mm = [0, 0, -3];  % 下排相對上排 Z 減少 3 mm

%% 6. 安全偏移設定
safe_offset_mm = [-15, 0, 0];
T_safe_offset = SE3(safe_offset_mm * mm);

%% 7. IK 設定
q_seed = [0 0 0 0 0 0];

ik_tol = 1e-10;

% 如果之後你要手動引導 J4，可以改這裡
j4_bias_deg = 0;

%% 8. 開始批次計算
total_expected = size(caseData, 1) * num_layer * num_col;
valid_count = 0;
fail_count  = 0;

results_cell = {};

fprintf('\n');
fprintf('====================================================================================================================\n');
fprintf(' ABB IRB 1090 - R/L/U/D TCP Compensation IK Result\n');
fprintf(' Total expected result count = %d cases x %d points = %d\n', size(caseData,1), num_layer*num_col, total_expected);
fprintf(' Unit: joint angles in degree, position in mm\n');
fprintf('====================================================================================================================\n\n');

fprintf('%-4s %-4s %-8s %-6s %-5s %-5s %-10s %-10s %-10s %10s %10s %10s %10s %10s %10s %12s %12s\n', ...
    'Dir', 'Exp', 'Target', 'Tool', 'Pt', 'Lay', ...
    'X', 'Y', 'Z', ...
    'J1', 'J2', 'J3', 'J4', 'J5', 'J6', ...
    'PosErr(mm)', 'RotErr(deg)');

fprintf('%s\n', repmat('-', 1, 180));

for k = 1:size(caseData, 1)

    dirName   = caseData{k, 1};
    expID     = caseData{k, 2};
    targetName = caseData{k, 3};
    toolName   = caseData{k, 4};
    axisName   = caseData{k, 5};
    compAngleDeg = caseData{k, 6};

    targetBase = RT.(targetName);
    tcpData    = TCP.(toolName);

    % 建立原始 TCP
    T_tcp_raw = make_tcp_SE3(tcpData, mm);

    % 建立反向補償後 TCP
    T_comp = make_compensation_SE3(axisName, compAngleDeg);
    T_tcp_compensated = T_tcp_raw * T_comp;

    % 每一組實驗重新給 seed，避免跨實驗亂跳
    q_prev = q_seed;

    for layerID = 1:num_layer
        for colID = 1:num_col

            pointID = (layerID - 1) * num_col + colID;

            % --------------------------------------------------
            % 產生 10 點位置
            % --------------------------------------------------
            delta_y_mm = (colID - 1) * y_step_mm;
            delta_layer_mm = (layerID - 1) * layer_step_mm;

            pos_mm = targetBase(1:3) + [0, delta_y_mm, 0] + delta_layer_mm;

            targetNow = targetBase;
            targetNow(1:3) = pos_mm;

            % 目標點 SE3
            T_target_origin = make_robtarget_SE3(targetNow, mm);

            % 加安全偏移
            T_target = T_safe_offset * T_target_origin;

            % --------------------------------------------------
            % 第一步：使用原始 TCP 求基準 IK
            % --------------------------------------------------
            irb1090.tool = T_tcp_raw;

            q_base = irb1090.ikine(T_target, ...
                'q0', q_prev, ...
                'pinv');

            if isempty(q_base) || any(~isfinite(q_base))
                fail_count = fail_count + 1;

                fprintf('%-4s %-4d %-8s %-6s %-5d %-5d %-10.3f %-10.3f %-10.3f %s\n', ...
                    dirName, expID, targetName, toolName, pointID, layerID, ...
                    pos_mm(1), pos_mm(2), pos_mm(3), ...
                    'Base IK failed');

                results_cell(end+1,:) = {dirName, expID, targetName, toolName, pointID, layerID, colID, ...
                    pos_mm(1), pos_mm(2), pos_mm(3), ...
                    NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN};

                continue;
            end

            q_base = q_base(:)';

            % --------------------------------------------------
            % 第二步：熱啟動猜測值
            % --------------------------------------------------
            q_guess = q_base;
            q_guess(4) = q_guess(4) + j4_bias_deg * deg;

            % --------------------------------------------------
            % 第三步：使用反向補償 TCP 重解 IK
            % --------------------------------------------------
            irb1090.tool = T_tcp_compensated;

            q_sol = irb1090.ikine(T_target, ...
                'q0', q_guess, ...
                'pinv', ...
                'tol', ik_tol);

            if isempty(q_sol) || any(~isfinite(q_sol))
                fail_count = fail_count + 1;

                fprintf('%-4s %-4d %-8s %-6s %-5d %-5d %-10.3f %-10.3f %-10.3f %s\n', ...
                    dirName, expID, targetName, toolName, pointID, layerID, ...
                    pos_mm(1), pos_mm(2), pos_mm(3), ...
                    'Compensated IK failed');

                results_cell(end+1,:) = {dirName, expID, targetName, toolName, pointID, layerID, colID, ...
                    pos_mm(1), pos_mm(2), pos_mm(3), ...
                    NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN};

                continue;
            end

            q_sol = q_sol(:)';
            q_sol_deg = q_sol / deg;

            % --------------------------------------------------
            % FK 回算檢查
            % --------------------------------------------------
            T_check = irb1090.fkine(q_sol);

            [pos_err_mm, rot_err_deg] = pose_error(T_check, T_target, deg);

            valid_count = valid_count + 1;

            fprintf('%-4s %-4d %-8s %-6s %-5d %-5d %-10.3f %-10.3f %-10.3f %10.3f %10.3f %10.3f %10.3f %10.3f %10.3f %12.6f %12.6f\n', ...
                dirName, expID, targetName, toolName, pointID, layerID, ...
                pos_mm(1), pos_mm(2), pos_mm(3), ...
                q_sol_deg(1), q_sol_deg(2), q_sol_deg(3), ...
                q_sol_deg(4), q_sol_deg(5), q_sol_deg(6), ...
                pos_err_mm, rot_err_deg);

            results_cell(end+1,:) = {dirName, expID, targetName, toolName, pointID, layerID, colID, ...
                pos_mm(1), pos_mm(2), pos_mm(3), ...
                q_sol_deg(1), q_sol_deg(2), q_sol_deg(3), ...
                q_sol_deg(4), q_sol_deg(5), q_sol_deg(6), ...
                pos_err_mm, rot_err_deg};

            % 下一點使用前一點結果，讓解比較連續
            q_prev = q_sol;

        end
    end
end

fprintf('%s\n', repmat('-', 1, 180));
fprintf('Valid IK result: %d / %d\n', valid_count, total_expected);
fprintf('Failed IK result: %d / %d\n', fail_count, total_expected);
fprintf('====================================================================================================================\n\n');

%% 9. 轉成 table，方便後續複製或輸出
% 注意：
% 不要使用 Row 當變數名稱，MATLAB table 會跟 dimension name 衝突。
% 之前它已經表演過一次了，讓我們不要再給它機會。

results_table = cell2table(results_cell, ...
    'VariableNames', {'DirectionName', 'ExpID', 'TargetName', 'ToolName', ...
                      'PointID', 'LayerID', 'ColID', ...
                      'X_mm', 'Y_mm', 'Z_mm', ...
                      'J1_deg', 'J2_deg', 'J3_deg', ...
                      'J4_deg', 'J5_deg', 'J6_deg', ...
                      'PosErr_mm', 'RotErr_deg'});

disp(results_table);

%% 10. 可選：輸出成 Excel
% 如果不需要輸出 Excel，可以把這行註解掉
writetable(results_table, 'IRB1090_RLUD_120points_IK_Result.xlsx');


%% ======================================================
% Local functions
% ======================================================

function T = make_robtarget_SE3(data, mm)
    % data = [X, Y, Z, q1, q2, q3, q4]
    % ABB robtarget quaternion 使用 q1 作為 scalar part
    pos = data(1:3) * mm;
    q1 = data(4);
    qv = data(5:7);

    T = SE3(pos) * UnitQuaternion(q1, qv).SE3;
end


function T = make_tcp_SE3(tcpData, mm)
    % tcpData = [X, Y, Z, Rx, Ry, Rz]
    tcp_pos = tcpData(1:3) * mm;
    tcp_rot = tcpData(4:6);

    T = SE3(transl(tcp_pos)) * ...
        SE3.Rx(tcp_rot(1), 'deg') * ...
        SE3.Ry(tcp_rot(2), 'deg') * ...
        SE3.Rz(tcp_rot(3), 'deg');
end


function T_comp = make_compensation_SE3(axisName, compAngleDeg)
    % compAngleDeg 是已經反向後的 MATLAB 補償角度
    %
    % 實際 R：Z +10 deg -> MATLAB Rz(-10)
    % 實際 L：Z -10 deg -> MATLAB Rz(+10)
    % 實際 U：Y -10 deg -> MATLAB Ry(+10)
    % 實際 D：Y +10 deg -> MATLAB Ry(-10)

    if strcmpi(axisName, 'z')
        T_comp = SE3.Rz(compAngleDeg, 'deg');
    elseif strcmpi(axisName, 'y')
        T_comp = SE3.Ry(compAngleDeg, 'deg');
    else
        error('Unknown compensation axis: %s', axisName);
    end
end


function [pos_err_mm, rot_err_deg] = pose_error(T_check, T_target, deg)
    % FK 回算誤差：
    % T_check 是 IK 解出後 fkine 的結果
    % T_target 是原本指定目標
    %
    % pos_err_mm：位置誤差，mm
    % rot_err_deg：旋轉誤差，degree

    T_err = inv(T_check) * T_target;

    pos_err_mm = norm(T_err.t) * 1000;

    cos_theta = (trace(T_err.R) - 1) / 2;
    cos_theta = max(-1, min(1, cos_theta));

    rot_err_deg = acos(cos_theta) / deg;
end