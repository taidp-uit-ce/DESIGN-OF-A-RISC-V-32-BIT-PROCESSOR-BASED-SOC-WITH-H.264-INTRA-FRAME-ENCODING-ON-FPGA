addpath(genpath('.'));
A = [1 2 3 4
     5 6 7 8
     9 10 11 12
     13 14 15 16];
     
% Hiển thị kết quả Hadamard thông thường
disp('Kết quả Hadamard thông thường:');
disp(hadamard_core(A));

% Hiển thị kết quả Hadamard với biểu diễn bù 2 (13 bit)
disp('Kết quả Hadamard với biểu diễn bù 2 (13 bit):');
disp(convert_2comp(hadamard_core(A), 13));

function [W] = hadamard_core(X)
    H = [1 1 1 1
         1 -1 1 -1
         1 1 -1 -1
         1 -1 -1 1];
    W = (H*double(X)*H');
end

