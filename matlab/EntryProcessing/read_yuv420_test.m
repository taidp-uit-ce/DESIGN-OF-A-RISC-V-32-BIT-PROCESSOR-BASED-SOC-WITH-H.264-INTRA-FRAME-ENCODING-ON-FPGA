% test_readYUV420_4D.m
% Script minh hoạ cách test hàm readYUV420_4D

clear; clc;

%% Thông số video giả lập
filename = 'BlowingBubbles_416x240_510f.yuv';
width    = 416;
height   = 240;
nFrames  = 5;   % số frame muốn tạo & đọc


%% 2) Gọi hàm readYUV420_4D để đọc lại
disp('--- Đọc file YUV 4:2:0 với hàm readYUV420_4D ---');
yuvData = read_yuv420(filename, width, height, nFrames);

%dec => hex
yuvData_hex = arrayfun(@(x) dec2hex(x, 2), yuvData, 'UniformOutput', false);

% Kiểm tra kích thước kết quả
% Kỳ vọng: [width, height, 3, nFrames]
sz = size(yuvData);
fprintf('Kích thước mảng yuvData: %dx%dx%dx%d\n', sz(1), sz(2), sz(3), sz(4));


%% 3) Test một frame bất kỳ
testFrameIdx = 1;  % ví dụ lấy frame thứ 3
frameY = yuvData(:,:,1,testFrameIdx);
frameU = yuvData(:,:,2,testFrameIdx);
frameV = yuvData(:,:,3,testFrameIdx);

% Hiển thị kênh Y, U, V (đã upsample)
figure('Name','Kênh Y, U, V');
subplot(1,3,1); imshow(frameY, []); title('Channel Y');
subplot(1,3,2); imshow(frameU, []); title('Channel U');
subplot(1,3,3); imshow(frameV, []); title('Channel V');


%% 4) (Tuỳ chọn) Chuyển từ YUV sang RGB để hiển thị 
% Hàm chuyển đổi YUV->RGB tùy bạn cài đặt. 
% Ví dụ đơn giản minh họa (BT.601) 
frameRGB = yuv2rgb(frameY, frameU, frameV);

figure('Name','Frame RGB');
imshow(frameRGB);
title(sprintf('Frame %d (RGB)', testFrameIdx));

disp('--- Kết thúc test ---');

