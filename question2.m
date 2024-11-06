% 输入部分
% 节点矩阵
bus = [-1 0 0 0 0
        0 0 0 0 0
        1 0.3 0 0 0.4
        2 0 0 3 0
        3 0 0 0.8 0
        4 0 0 0 0.95];
% 支路矩阵
branch = [1 1 -1 0
          2 1 -1 2
          3 1 1 2
          4 2 -1 1
          5 3 2 0 
          6 1 1 0
          7 4 1 0
          8 4 1 3
          9 3 3 0
          10 2 -1 4
          11 4 4 3
          12 4 4 0];
% 计算部分
% 计算节点、支路个数
number_of_nodes = size(bus, 1) - 2;
number_of_branch = size(branch, 1);

% 生成A矩阵
% 形成初始A矩阵
A_initial = zeros(number_of_nodes*4, number_of_branch);
for i = 1 : number_of_branch
    if branch(i,3) ~= -1
        A_initial((branch(i,3)-1)*4+branch(i,2),i) = -1;
    end
    if branch(i,4) ~= 0
        A_initial((branch(i,4)-1)*4+branch(i,2),i) = 1;
    end
end
% 初始化一个 3D 数组来存储子矩阵
block_size = 4;
sub_matrices = zeros(block_size, size(A_initial, 2), number_of_nodes);

% 使用循环来分块矩阵
for k = 1:number_of_nodes
    start_row = (k-1)*block_size + 1;
    end_row = k*block_size;
    sub_matrices(:, :, k) = A_initial(start_row:end_row, :);
end
% 初始化一个单元格数组来存储结果矩阵
num_blocks = size(sub_matrices, 3);
A = cell(1, num_blocks);

% 使用循环处理每个子矩阵
for k = 1:num_blocks
    % 获取第 k 个子矩阵
    sub_matrix = sub_matrices(:, :, k);
    % 删除全零行
    sub_matrix(all(sub_matrix == 0, 2), :) = [];
    % 存储结果
    A{k} = sub_matrix;
end

% 生成H矩阵
% 计算各节点能源类型，确定H矩阵维度
% energy_class = zeros(2, number_of_nodes);
% for i = 1 : 4
%     % 在branch的第3、4行分别将同一节点的支路分类
%     indices_out = find(branch(:, 3) == i);
%     indices_in = find(branch(:, 4) == i);
%     % 提取第2列对应的数字
%     corresponding_values_out = branch(indices_out, 2);
%     corresponding_values_in = branch(indices_in, 2);
%     % 统计第2列对应的数字不重复的中有多少种，即可表示该节点的输出、输入能量类型数
%     num_unique_values_out = length(unique(corresponding_values_out));
%     num_unique_values_in = length(unique(corresponding_values_in));
%     energy_class(1, i) = num_unique_values_out;
%     energy_class(2, i) = num_unique_values_in;
% end
H_initial = zeros(4, 4, number_of_nodes);
for i = 1 : number_of_nodes
    H_initial(:, :, i) = eye(4);
end
for i = 1 : 4
    for j = 1 : number_of_branch
        if branch(j, 4) == i
            energy_class_input = branch(j, 2);
            for k = 1 : number_of_branch
                if branch(k, 3) == i
                    H_initial(branch(k, 2), energy_class_input, i) = bus(i+2, branch(k, 2)+1);
                end
            end
        end
    end
end
H = cell(1, number_of_nodes);
for k = 1 : number_of_nodes
    % 获取第 k 个子矩阵
    sub_H_initial = H_initial(:, :, k);
    % 删除只有一个非零元素的行
    sub_H_initial(sum(sub_H_initial ~= 0, 2) <= 1, :) = [];
    % 删除全零的列
    sub_H_initial(:, all(sub_H_initial == 0, 1)) = [];
    H{k} = sub_H_initial;
end
% 生成Z矩阵
Z = cell(1, number_of_nodes);
for i = 1 : number_of_nodes
    Z{i} = H{i} * A{i};
end

% 生成X、Y矩阵
X = zeros(4, number_of_branch);
Y = zeros(4, number_of_branch);
for i = 1 : number_of_branch
    if branch(i, 3) == -1
        X(branch(i, 2), branch(i, 1)) = 1;
    end
    if branch(i, 4) == 0
        Y(branch(i, 2), branch(i, 1)) = 1;
    end
end
X(all(X == 0, 2), :) = [];
Y(all(Y == 0, 2), :) = [];