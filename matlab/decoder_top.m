%% H.264/AVC INTRA DECODER
% Initialization
clear all;
clc;
close all;
tic
system_dependent('DirChangeHandleWarn', 'Never');
addpath(genpath('.'));

%% Input - load the encoded file

load ./bitstream_enc.mat; % correct packets
global h w QP block_size
Frame_start = 1;
Frame_end = 3; 
nFrames = Frame_end - Frame_start + 1;
width = 416;
height = 240;
filename = 'D:\Workspaces\RTL\KLTN_sourcecode\videos\BlowingBubbles_416x240_510f.yuv';

% Read yuv file to matrix
yuvData = read_yuv420(filename, width, height, nFrames);

%-------------------------
idx = 1;
block_size = 16;

%---------------------------------------------------------
% Decode header
[h, w, QP, Frame_start, Frame_end, m] = dec_header(bitstream);
idx = idx + m - 1;

N = 1 + (Frame_end - Frame_start);

if (strcmp(bitstream(idx:idx+3),'1111'))
    fprintf("START DECODING\n");
    idx = idx + 4;
    for dec_frame_idx = 1:N
        fprintf('Decoding I Frame Y: %d\n', dec_frame_idx);
        [cur_dec_frame(:,:,1,dec_frame_idx), idx]=i_frame_dec(idx,bitstream); % decode Y
        fprintf('Decoding I Frame U: %d - idx=%d\n', dec_frame_idx, idx);
        disp(bitstream(idx:idx+10));
        [cur_dec_frame(:,:,2,dec_frame_idx), idx]=i_frame_dec(idx,bitstream); % decode U
        fprintf('Decoding I Frame V: %d - idx=%d\n', dec_frame_idx, idx);
        [cur_dec_frame(:,:,3,dec_frame_idx), idx]=i_frame_dec(idx,bitstream); % decode V
        
        cur_frame(:,:,1) = double(yuvData(:,:,1,dec_frame_idx));
        cur_frame(:,:,2) = double(yuvData(:,:,2,dec_frame_idx));
        cur_frame(:,:,3) = double(yuvData(:,:,3,dec_frame_idx));
        disp(class(cur_frame));
        disp(class(cur_dec_frame));
        display_frame (cur_dec_frame, dec_frame_idx, 2);

        % [temp] = result_display(cur_frame, cur_dec_frame, k, Frame_start, h, w);
        PSNR_Y_dec_reg(dec_frame_idx) = find_psnr(cur_frame(:,:,1), cur_dec_frame(:,:,1, dec_frame_idx));
        PSNR_U_dec_reg(dec_frame_idx) = find_psnr(cur_frame(:,:,2), cur_dec_frame(:,:,2, dec_frame_idx));
        PSNR_V_dec_reg(dec_frame_idx) = find_psnr(cur_frame(:,:,3), cur_dec_frame(:,:,3, dec_frame_idx));

    end
    %% display decoded video
    % display_video (cur_dec_frame, N, 30);
end

% display_psnr(PSNR_Y_dec_reg, Frame_start, Frame_end);
% disp([ 'average PSNR with frame-copy error concealment is: ', num2str(mean(PSNR_Y_dec_reg))])
toc

function [psnr_value] = result_display(cur_frame, cur_frame_ref, k, Frame_start, h, w)
        % display original picture on the left side
        subplot(1, 2, 1); 
        image(cur_frame(:, :, 1));
        title(['Original - Frame No. ' num2str(Frame_start + k - 1)]);
        colormap(gray(256));
        axis image; % ensure property ratio

        % display decoded picture on the right side
        subplot(1, 2, 2); 
        %taidao
        image(cur_frame_ref(:,:,1))
        title(['Decoded picture - Frame No. ' num2str(Frame_start+k-1)]);
        colormap(gray(256));
        axis image; 

        % display PSNR
        psnr_value = find_psnr(cur_frame(:,:,1),cur_frame_ref(:,:,1));

        delete(findall(gcf, 'Tag', 'PSNR_Annotation'));
        annotation('textbox', [0.4, 0.01, 0.2, 0.08], ...
        'String', ['PSNR: ' num2str(psnr_value, '%.5f') ' dB'], ...
        'EdgeColor', 'none', ...
        'HorizontalAlignment', 'center', ...
        'FontSize', 12, ...
        'FontWeight', 'bold', ...
        'Tag', 'PSNR_Annotation');


        truesize([2*h 2*w])
        drawnow
        % pause(1)
end
%-----------------------------------------------------------

function display_psnr(PSNR_Y_dec_reg, Frame_start, Frame_end);
    frames = Frame_start:Frame_end; 
    size(frames)
size(PSNR_Y_dec_reg)
    figure; 
    plot(frames, PSNR_Y_dec_reg, '-o', 'LineWidth', 1.5, 'MarkerSize', 6); 
    grid on; 
    xlabel('Frame Number', 'FontSize', 12); 
    ylabel('PSNR (dB)', 'FontSize', 12); 
    title('PSNR Values per Frame', 'FontSize', 14); 
    xlim([Frame_start Frame_end]); 
    ylim([floor(min(PSNR_Y_dec_reg)) ceil(max(PSNR_Y_dec_reg))]); 

   for k = Frame_start:Frame_end
        text(frames(k), PSNR_Y_dec_reg(k), sprintf('%.2f', PSNR_Y_dec_reg(k)), ...
         'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', ...
         'FontSize', 10, 'Color', 'blue');
    end
end

function display_frame (cur_frame, idx, type)
    frameRGB = yuv2rgb(cur_frame(:,:,1), cur_frame(:,:,2), cur_frame(:,:,3));
    figure(1)
    imshow(frameRGB);
    if(type == 0)
        title(sprintf('Encoding Frame %d (RGB)', idx));
    elseif(type == 1)
        title(sprintf('Encoded Frame %d (RGB)', idx));
    else
        title(sprintf('Decoded Frame %d (RGB)', idx));
    end
    % pause(1);
end