function rgbImg = yuv2rgb(Y, U, V)
% Chuyển YUV (3 kênh cùng kích thước) -> RGB (BT.601)
% Input Y, U, V: ma trận uint8
% Output: ma trận RGB loại uint8

    Y = double(Y);
    U = double(U);
    V = double(V);

    R = Y + 1.4075 .* (V - 128);
    G = Y - 0.3455 .* (U - 128) - 0.7169 .* (V - 128);
    B = Y + 1.7790 .* (U - 128);

    % Giới hạn giá trị về [0..255]
    R = uint8(max(min(R, 255), 0));
    G = uint8(max(min(G, 255), 0));
    B = uint8(max(min(B, 255), 0));

    % Ghép kênh
    rgbImg = cat(3, R, G, B);
end