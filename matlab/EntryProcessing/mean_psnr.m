% compute_psnr_average.m
% Script này giả sử bạn đã có PSNR_Y_reg, PSNR_U_reg, PSNR_V_reg trong Workspace

% Tính trung bình
avgPSNR_Y = mean(PSNR_Y_reg);
avgPSNR_U = mean(PSNR_U_reg);
avgPSNR_V = mean(PSNR_V_reg);

% In kết quả
fprintf('--- Average PSNR (from existing workspace data) ---\n');
fprintf('Y channel: %.3f dB\n', avgPSNR_Y);
fprintf('U channel: %.3f dB\n', avgPSNR_U);
fprintf('V channel: %.3f dB\n', avgPSNR_V);