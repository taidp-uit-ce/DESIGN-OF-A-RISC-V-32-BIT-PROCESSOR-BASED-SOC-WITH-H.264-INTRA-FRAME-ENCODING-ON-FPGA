clear all;
tic
system_dependent('DirChangeHandleWarn', 'Never');
addpath(genpath('.'));

global h w

% .........................................................................
% Input parameters are:
Frame_start = 1;
Frame_end = 2;
nFrames = Frame_end - Frame_start + 1;
QP = 28;
width = 416;
height = 240;
filename = 'D:\Workspaces\RTL\KLTN_sourcecode\videos\BlowingBubbles_416x240_510f.yuv';

% Read yuv file to matrix
yuvFrames = read_yuv420(filename, width, height, nFrames);

% Display video
% display_video (yuvFrames, 501, 144);

% Output bitstream
bitstream = '';         

% Initialize PSNR and bitrate values for regular ME
PSNR_reg = zeros(nFrames,length(QP));
R_reg =  zeros(nFrames,length(QP));

% Create header
[bits] = enc_header(height, width, QP, Frame_start, Frame_end);
bitstream = bits;

% Add '1111' to mark I frame
bitstream = [bitstream '1111'];

for frame_idx = 1:nFrames
    fprintf("Encoding Frame Number = %d\n", frame_idx);
    cur_frame = double(yuvFrames(:,:,:,frame_idx));
    display_frame (cur_frame, frame_idx, 0);
    [cur_frame_ref, bits]= i_frame_enc(cur_frame, QP);
    display_frame (cur_frame_ref, frame_idx, 1);
    bitstream = [bitstream bits];
    PSNR_Y_reg(1, frame_idx) = find_psnr(cur_frame(:,:,1), cur_frame_ref(:,:,1));
    PSNR_U_reg(1, frame_idx) = find_psnr(cur_frame(:,:,2), cur_frame_ref(:,:,2));
    PSNR_V_reg(1, frame_idx) = find_psnr(cur_frame(:,:,3), cur_frame_ref(:,:,3));
    R_reg(frame_idx, 1) = length(bitstream);
        
end    
    % save ('./results/final_enc_values','bitstream','PSNR_reg', 'QP','h','w')
    save(['bitstream','_enc'],'bitstream')

    % Tính trung bình
    avgPSNR_Y = mean(PSNR_Y_reg);
    avgPSNR_U = mean(PSNR_U_reg);
    avgPSNR_V = mean(PSNR_V_reg);
    
    % In kết quả
    fprintf('--- Average PSNR (from existing workspace data) ---\n');
    fprintf('Y channel: %.3f dB\n', avgPSNR_Y);
    fprintf('U channel: %.3f dB\n', avgPSNR_U);
    fprintf('V channel: %.3f dB\n', avgPSNR_V);
toc

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
    pause(1);
end
