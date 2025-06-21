function yuvFrames = read_yuv420(filename, width, height, nFrames)
% READ_YUV420 Đọc file YUV 4:2:0 và trả về 1 mảng 4 chiều:
%   yuvFrames có kích thước: [height x width x 3 x nFrames]
% Trong đó:
%   - yuvFrames(:,:,1,f) là kênh Y (full resolution)
%   - yuvFrames(:,:,2,f) là kênh U, được upsample lên [height x width] bằng kron
%   - yuvFrames(:,:,3,f) là kênh V, được upsample tương tự
%
% Tham số:
%   filename: Đường dẫn file YUV
%   width, height: độ phân giải của kênh Y (full resolution)
%   nFrames: số lượng frame cần đọc
%
% Lưu ý: 1 frame YUV 4:2:0 gồm:
%  - Y: width*height byte
%  - U: (width/2)*(height/2) byte
%  - V: (width/2)*(height/2) byte
% => Tổng số byte/frame = 1.5 * width * height

    % Mở file ở chế độ đọc nhị phân
    fileId = fopen(filename, 'r');
    if fileId < 0
        error('Không thể mở file: %s', filename);
    end

    % Tính số byte của 1 frame
    frameSize = 1.5 * width * height;
    
    % Khởi tạo mảng kết quả yuvFrames [height x width x 3 x nFrames]
    yuvFrames = zeros(height, width, 3, nFrames, 'uint8');
    
    % Mask dùng cho upsample các kênh U và V (phép nhân replication 2x2)
    sampleMask = [1 1; 1 1];
    
    for f = 1 : nFrames
        % Tính offset của frame f (frame đầu tiên có offset 0)
        offset = (f - 1) * frameSize;
        status = fseek(fileId, offset, 'bof');
        if status ~= 0
            warning('File đã hết dữ liệu hoặc fseek bị lỗi ở frame %d', f);
            break;
        end

        %% Đọc kênh Y (full resolution)
        Ysize = width * height;
        bufY = fread(fileId, Ysize, 'uint8');
        if numel(bufY) < Ysize
            warning('Thiếu dữ liệu cho kênh Y ở frame %d', f);
            break;
        end
        % Chuyển vector thành ma trận [height x width]
        Y = reshape(bufY, [width, height]).';
        
        %% Đọc kênh U (gốc: [width/2 x height/2])
        UVsize = (width/2) * (height/2);
        bufU = fread(fileId, UVsize, 'uint8');
        if numel(bufU) < UVsize
            warning('Thiếu dữ liệu cho kênh U ở frame %d', f);
            break;
        end
        U_small = reshape(bufU, [width/2, height/2]).';
        
        %% Đọc kênh V (gốc: [width/2 x height/2])
        bufV = fread(fileId, UVsize, 'uint8');
        if numel(bufV) < UVsize
            warning('Thiếu dữ liệu cho kênh V ở frame %d', f);
            break;
        end
        V_small = reshape(bufV, [width/2, height/2]).';
        
        % Up-sample U và V lên kích thước của Y dùng hàm kron
        U = kron(U_small, sampleMask);
        V = kron(V_small, sampleMask);
        
        % Lưu 3 kênh vào mảng kết quả
        yuvFrames(:,:,1,f) = Y;
        yuvFrames(:,:,2,f) = U;
        yuvFrames(:,:,3,f) = V;
    end

    fclose(fileId);

    % Nếu số frame đọc được nhỏ hơn nFrames, cắt bỏ phần thừa
    if f < nFrames
        yuvFrames = yuvFrames(:,:,:,1:f);
    end
end
