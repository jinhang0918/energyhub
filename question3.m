% 运行第二问的程序，并在此基础上进行输入输出分析，下面的路径需要根据question2.m文件路径进行修改
run('D:\matlab\多能源系统建模与分析\question2.m')
% 导入文件
filepath1 = 'D:\matlab\多能源系统建模与分析\load.xlsx';
load = table2array(readtable(filepath1));
filepath2 = 'D:\matlab\多能源系统建模与分析\price.xlsx';
price = table2array(readtable(filepath2));

% 形成Q矩阵
Q = vertcat(X, Z{1}, Z{2}, Z{3}, Z{4});

% 形成QB、QF、YB、YF
% 将 Q 转换为简化行阶梯形矩阵
[~, pivot_cols] = rref(Q);

% 选择线性无关的列作为 QB 和 YB
QB = Q(:, pivot_cols);
YB = Y(:, pivot_cols);

% 剩余的列作为 QF 和 YF
all_cols = 1:size(Q, 2);
dependent_cols = setdiff(all_cols, pivot_cols);
QF = Q(:, dependent_cols);
YF = Y(:, dependent_cols);

% 生成R矩阵
R = vertcat(-eye(size(X, 1)), zeros(size(Q, 1)-size(X, 1), size(X, 1)));

% 生成C1、C2矩阵
C1 = -YB * inv(QB) * R;
C2 = YF - YB * inv(QB) * QF;
C = [C1, C2];

% 求解优化问题
% 定义变量
v1 = sdpvar(1);
v2 = sdpvar(1);
v3 = sdpvar(1);
v4 = sdpvar(1);
v5 = sdpvar(1);
v6 = sdpvar(1);
v7 = sdpvar(1);
v8 = sdpvar(1);
v9 = sdpvar(1);
v10 = sdpvar(1);
v11 = sdpvar(1);
v12 = sdpvar(1);
electricity_input = zeros(1, 24);
gas_input = zeros(1, 24);
cost_total = 0;
% 构建输出向量
for i = 1 : 24
    output = zeros(3, 1);
    output(1, 1) = load(i, 2) - load(i, 5);
    output(2, 1) = load(i, 3);
    output(3, 1) = load(i, 4);
    % 目标函数
    cost = (v1 + v2) * price(i, 2) * 1000 + (v4 + v10) * price(i, 3) * 1000;
    % 输入输出等式约束
    cons = [output == C * [(v1 + v2); (v4 + v10); v5; v6; v9; v11; v12],...
            v4 <= 200,...
            v2 + v3 <= 50,...
            v10 <= 100,...
            v8 + v11 <= 100,...
            v3 + v6 <= 60,...
            v7 + v8 <= 80,...
            v5 <= 150,...
            v11 + v12 <= 95,...
            v9 <= 80
            v1 >= 0, v2 >= 0, v3 >= 0, v4 >= 0, v5 >= 0, v6 >= 0, v7 >= 0, v8 >= 0, v9 >= 0, v10 >= 0, v11 >= 0, v12 >= 0];
    result = optimize(cons, cost);
    if result.problem == 0
        electricity_input(1, i) = v1 + v2;
        gas_input(1, i) = v4 + v10;
        cost_total = cost_total + cost;
    else
        disp(result.info)
    end
end
% 画出 electricity_input 与 gas_input 折线图
figure;
plot(1:24, electricity_input, '-o', 'DisplayName', 'Electricity Input');
hold on;
plot(1:24, gas_input, '-x', 'DisplayName', 'Gas Input');
xlabel('Time (hours)');
ylabel('Input');
title('Electricity and Gas Input Over 24 Hours');
xticks(1:24); % 设置横轴为 1 到 24
legend;
hold on;