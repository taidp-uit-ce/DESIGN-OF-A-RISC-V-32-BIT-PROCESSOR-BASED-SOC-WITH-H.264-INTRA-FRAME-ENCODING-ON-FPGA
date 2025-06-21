function display_video (yuvFrames, nFrames, fps)
    sampleMask = uint8([1 1; 1 1]);
    figure('Name', 'Video RGB', 'NumberTitle', 'off');
    for frame_idx = 1:nFrames
        frameY = yuvFrames(:,:, 1, frame_idx);
        frameU = yuvFrames(:,:, 2, frame_idx);
        frameV = yuvFrames(:,:, 3, frame_idx);

        frameRGB = yuv2rgb(frameY, frameU, frameV);
    
        figure(1);
        imshow(frameRGB);
        title(sprintf('Frame %d (RGB)', frame_idx));
        pause(1/fps);
    end
end