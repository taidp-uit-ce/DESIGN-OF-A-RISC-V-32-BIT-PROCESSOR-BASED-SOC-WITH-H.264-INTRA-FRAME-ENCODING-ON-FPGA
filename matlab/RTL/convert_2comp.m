function [result] = convert_2comp(matrix, bit_width)
    % Chuyển đổi ma trận sang biểu diễn bù 2 với độ rộng bit_width
    result = matrix;
    
    % Tìm và chuyển đổi các phần tử âm
    for i = 1:size(matrix, 1)
        for j = 1:size(matrix, 2)
            if matrix(i, j) < 0
                % Chuyển đổi số âm sang biểu diễn bù 2
                abs_value = abs(matrix(i, j));
                binary_rep = dec2bin(abs_value, bit_width);
                
                % Đảo ngược bit
                inverted = char(ones(1, bit_width) * '0');
                for k = 1:bit_width
                    if binary_rep(k) == '0'
                        inverted(k) = '1';
                    else
                        inverted(k) = '0';
                    end
                end
                
                % Cộng 1
                twos_comp = bin2dec(inverted) + 1;
                
                % Điều chỉnh giá trị nếu vượt quá bit_width
                max_value = 2^bit_width;
                if twos_comp >= max_value
                    twos_comp = twos_comp - max_value;
                end
                
                % Cập nhật ma trận kết quả
                result(i, j) = twos_comp;
            end
        end
    end
end