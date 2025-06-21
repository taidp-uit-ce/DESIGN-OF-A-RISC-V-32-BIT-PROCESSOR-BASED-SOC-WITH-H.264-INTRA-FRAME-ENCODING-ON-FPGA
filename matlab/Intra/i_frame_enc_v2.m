function [cur_frame_ref, bits_frame] = i_frame_enc_v2(cur_frame, Quant)
    global QP h w
    global Table_coeff0 Table_coeff1 Table_coeff2 Table_coeff3
    global Table_run Table_zeros
    bits_frame = '';
    load table.mat
    [h, w, u] = size(cur_frame);
    QP = Quant;

    %% Y
    [bits_luma, cur_frame_y_ref] = luma_prediction(cur_frame(:,:,1));
    bits_frame = [bits_frame bits_luma];
    %% U
    [bits_u, cur_frame_u_ref, n_a] = intra_16(cur_frame(:,:,2));
    bits_frame = [bits_frame bits_u];
    %% V
    [bits_v, cur_frame_v_ref, n_a] = intra_16(cur_frame(:,:,3));
    bits_frame = [bits_frame bits_v];

    cur_frame_ref(:,:,1) = cur_frame_y_ref;
    cur_frame_ref(:,:,2) = cur_frame_u_ref;
    cur_frame_ref(:,:,3) = cur_frame_v_ref;
end
%--------------------------------------------------------------
function [bits_frame, cur_frame_ref] = luma_prediction (cur_frame)
    [bits_4x4, cur_frame_ref4x4, sae1] = intra_4(cur_frame);
    [bits_16x16, cur_frame_ref16x16, sae2] = intra_16(cur_frame); %taidao
    bits_frame = ''; %taidao
    if (sae1 < sae2)
        bits_frame = bits_4x4;
        cur_frame_ref = cur_frame_ref4x4;
    else
        bits_frame = bits_16x16;
        cur_frame_ref = cur_frame_ref16x16;  
    end
end

function [bits_frame,cur_frame_ref,total_sae] = intra_4(cur_frame)
    global h w
    bits_frame = '';
    total_sae = 0;
    mode_prev = 0;
    mode = 0;
    mb_type = 1;            % 0 denotes 16x16, 1 denotes 4x4
    
    for m = 1:16:h
        for n = 1:16:w
            fprintf("Intra4: Processing MB(%d, %d)\n", m, n);
            bits_frame = [bits_frame dec2bin(mb_type)];    % mb header
            for i = m:4:m+15
                for j = n:4:n+15
                    if (i==1)&(j==1)    % No prediciton
                        mode = 9;       % Special mode to describe no prediction in 4x4 
                        bits = enc_golomb(mode - mode_prev, 1);
                        mode_prev = mode;
                        bits_frame = [bits_frame bits];
                        [cur_frame_ref(i:i+3,j:j+3),bits] = code_block(cur_frame(i:i+3,j:j+3));
                        bits_frame = [bits_frame bits];
                    elseif (i==1)       % Horz prediction
                        mode = 1;       
                        bits = enc_golomb(mode - mode_prev, 1);
                        mode_prev = mode;
                        bits_frame = [bits_frame bits];
                        [icp,pred,sae] = pred_horz_4(cur_frame,cur_frame_ref,i,j);
                        [icp_r,bits] = code_block(icp);
                        bits_frame = [bits_frame bits];
                        cur_frame_ref(i:i+3,j:j+3)= icp_r + pred;
                        total_sae = total_sae + sae;
                    elseif (j==1)       % Vert prediction
                        mode = 0;       
                        bits = enc_golomb(mode - mode_prev, 1);
                        mode_prev = mode;
                        bits_frame = [bits_frame bits];
                        [icp,pred,sae] = pred_vert_4(cur_frame,cur_frame_ref,i,j);
                        [icp_r,bits] = code_block(icp);
                        bits_frame = [bits_frame bits];
                        cur_frame_ref(i:i+3,j:j+3)= icp_r + pred;
                        total_sae = total_sae + sae;
                    else                % Try all different prediction
                        [icp,pred,sae,mode] = mode_select_4(cur_frame,cur_frame_ref,i,j); 
                        bits = enc_golomb(mode - mode_prev, 1);
                        mode_prev = mode;
                        bits_frame = [bits_frame bits];
                        [icp_r,bits] = code_block(icp);
                        bits_frame = [bits_frame bits];
                        cur_frame_ref(i:i+3,j:j+3)= icp_r + pred;
                        total_sae = total_sae + sae;
                    end 
                    fprintf("Mode of block (%d, %d)=%d\n", i, j, mode);
                end
            end
        end
    end
end
%% 4x4 Horizontal prediciton
function [icp,pred,sae] = pred_horz_4(cur_frame,cur_frame_ref,i,j)
    pred = cur_frame_ref(i:i+3,j-1)*ones(1,4);
    icp = cur_frame(i:i+3,j:j+3) - pred;
    sae = sum(sum(abs(icp)));
end
%-------------------------------------------------------
%% 4x4 Vertical Prediciton
function [icp,pred,sae] = pred_vert_4(cur_frame,cur_frame_ref,i,j)
    pred = ones(4,1)*cur_frame_ref(i-1,j:j+3);
    icp = cur_frame(i:i+3,j:j+3) - pred;
    sae = sum(sum(abs(icp)));
end
%-------------------------------------------------------
%% 4x4 DC prediction
function [icp,pred,sae] = pred_dc_4(cur_frame,cur_frame_ref,i,j)
    pred = bitshift(sum(cur_frame_ref(i-1,j:j+3))+ sum(cur_frame_ref(i:i+3,j-1))+4,-3);
    icp = cur_frame(i:i+3,j:j+3) - pred;
    sae = sum(sum(abs(icp)));
end
%--------------------------------------------------------

%% 4x4 diagonal down-left prediction
function [icp,pred,sae] = pred_ddl_4(cur_frame,cur_frame_ref,i,j)
    % cur_frame_ref(i+4:i+7,j-1)=cur_frame_ref(i+3,j-1); %%auto extend?

    % Kiểm tra xem có đủ 8 pixel tham chiếu phía trên không
    if (i-1 < 1) || (j+7 > size(cur_frame_ref, 2))
        %fprintf("Không thể /chọn chế độ VL do vượt quá biên ma trận!\n");
        icp = [];
        pred = [];
        sae = inf;
        return;
    end
    
    for x = 0:3
        for y = 0:3
            if (x==3)&(y==3)
                % pred(x+1,y+1) = bitshift(cur_frame_ref(i+6,j-1) + 3*cur_frame_ref(i+7,j-1) + 2,-2); old version (column <=> row) ==> wrong
                pred(x+1,y+1) = bitshift(cur_frame_ref(i-1, j+6) + 3*cur_frame_ref(i-1, j+7) + 2,-2);
            else
                % pred(x+1,y+1) = bitshift(cur_frame_ref(i+x+y,j-1) + 2*cur_frame_ref(i+x+y+1,j-1) + cur_frame_ref(i+x+y+2,j-1) + 2,-2);
                pred(x+1,y+1) = bitshift(cur_frame_ref(i-1, j+x+y) + 2*cur_frame_ref(i-1, j+x+y+1) + cur_frame_ref(i-1, j+x+y+2) + 2,-2);
            end
        end
    end
    
    icp = cur_frame(i:i+3,j:j+3) - pred;
    sae = sum(sum(abs(icp)));
end
%--------------------------------------------------------
function [icp,pred,sae] = pred_ddr_4(cur_frame,cur_frame_ref,i,j)
    for x = 0:3
        for y = 0:3
            if (x>y)
                pred(x+1,y+1) = bitshift(cur_frame_ref(i+x-y-2,j-1) + 2*cur_frame_ref(i+x-y-1,j-1) + cur_frame_ref(i+x-y,j-1) + 2,-2);
            elseif (x<y)
                pred(x+1,y+1) = bitshift(cur_frame_ref(i-1,j+y-x-2) + 2*cur_frame_ref(i-1,j+y-x-1) + cur_frame_ref(i-1,j+y-x) + 2,-2);
            else
                pred(x+1,y+1) = bitshift(cur_frame_ref(i,j-1) + 2*cur_frame_ref(i-1,j-1) + cur_frame_ref(i-1,j) + 2,-2);
            end
        end
    end
    
    icp = cur_frame(i:i+3,j:j+3) - pred;
    sae = sum(sum(abs(icp)));
end
%--------------------------------------------------------
function [icp,pred,sae] = pred_vr_4(cur_frame,cur_frame_ref,i,j)
    for y = 0:3
        for x = 0:3
            z = 2*x-y; % z = [-3, 6]
            w = bitshift(y,-1);
            if (z == 0 || z == 2 || z == 4 || z == 6) %taidao | corner z = 2x-y (x=0, y = 2) = -2 => must 'else' case
                pred(x+1,y+1)= bitshift(cur_frame_ref(i-1,j+x-w-1) + cur_frame_ref(i-1,j+x-w) + 1,-1);
            elseif rem(z,2)==1 % z = 1 | 3 | 5
                pred(x+1,y+1)= bitshift(cur_frame_ref(i-1,j+x-w-2) + 2*cur_frame_ref(i-1,j+x-w-1) + cur_frame_ref(i-1,j+x-w) + 2,-2);
            elseif z==-1
                pred(x+1,y+1)= bitshift(cur_frame_ref(i,j-1)+ 2*cur_frame_ref(i-1,j-1) + cur_frame_ref(i-1,j) + 2,-2);
            else % z = -2 | -3
                pred(x+1,y+1) = bitshift(cur_frame_ref(i+y-1,j-1)+ 2*cur_frame_ref(i+y-2,j-1) + cur_frame_ref(i+y-3,j-1) + 2,-2);
            end
        end
    end
    pred = pred.';
    icp = cur_frame(i:i+3,j:j+3) - pred;
    sae = sum(sum(abs(icp)));
end
%--------------------------------------------------------
function [icp,pred,sae] = pred_hd_4(cur_frame,cur_frame_ref,i,j)
    for y = 0:3
        for x = 0:3
            z = 2*y-x;
            w = bitshift(x,-1);
            if (z == 0 || z == 2 || z == 4 || z == 6)
                pred(x+1,y+1)= bitshift(cur_frame_ref(i+y-w-1,j-1) + cur_frame_ref(i+y-w,j-1) + 1,-1);
            elseif rem(z,2)==1
                pred(x+1,y+1)= bitshift(cur_frame_ref(i+y-w-2,j-1) + 2*cur_frame_ref(i+y-w-1,j-1) + cur_frame_ref(i+y-w,j-1) + 2,-2);
            elseif z==-1
                pred(x+1,y+1)= bitshift(cur_frame_ref(i,j-1)+ 2*cur_frame_ref(i-1,j-1) + cur_frame_ref(i-1,j) + 2,-2);
            else
                pred(x+1,y+1) = bitshift(cur_frame_ref(i-1,j+x-1)+ 2*cur_frame_ref(i-1,j+x-2) + cur_frame_ref(i-1,j+x-3) + 2,-2);
            end
        end
    end
    pred = pred.';
    icp = cur_frame(i:i+3,j:j+3) - pred;
    sae = sum(sum(abs(icp)));
end
%--------------------------------------------------------
function [icp,pred,sae] = pred_vl_4(cur_frame,cur_frame_ref,i,j)
    % cur_frame_ref(i+4:i+7,j-1)=cur_frame_ref(i+3,j-1);

    % Kiểm tra xem có đủ 8 pixel tham chiếu phía trên không
    if (i-1 < 1) || (j+7 > size(cur_frame_ref, 2))
        %fprintf("Không thể chọn chế độ VL do vượt quá biên ma trận!\n");
        icp = [];
        pred = [];
        sae = inf;
        return;
    end

    for y = 0:3
        for x = 0:3
            w = bitshift(y,-1);
            if rem(y,2)==0 % y = 0 || 2
                pred(x+1,y+1) = bitshift(cur_frame_ref(i-1,j+x+w) + cur_frame_ref(i-1,j+x+w+1) + 1,-1);
            else % y = 1 || 3
                pred(x+1,y+1) = bitshift(cur_frame_ref(i-1,j+x+w) + 2*cur_frame_ref(i-1,j+x+w+1) + cur_frame_ref(i-1,j+x+w+2) + 2,-2);
            end
        end
    end
    pred = pred.';
    icp = cur_frame(i:i+3,j:j+3) - pred;
    sae = sum(sum(abs(icp)));
end
%--------------------------------------------------------
function [icp,pred,sae] = pred_hu_4(cur_frame,cur_frame_ref,i,j)
    for y = 0:3
        for x = 0:3
            z = x + 2*y;
            w = bitshift(x,-1);
            if (z==0)|(z==2)|(z==4)
                pred(x+1,y+1)= bitshift(cur_frame_ref(i+y+w,j-1) + cur_frame_ref(i+y+w+1,j-1) + 1,-1);
            elseif (z==1)|(z==3)
                pred(x+1,y+1)= bitshift(cur_frame_ref(i+y+w,j-1) + 2*cur_frame_ref(i+y+w+1,j-1) + cur_frame_ref(i+y+w+2,j-1) + 2,-2);
            elseif z==5
                pred(x+1,y+1)= bitshift(cur_frame_ref(i+2,j-1)+ 3*cur_frame_ref(i+3,j-1) + 2,-2);
            else % z > 5
                pred(x+1,y+1) = cur_frame_ref(i+3,j-1);
            end
        end
    end
    pred = pred.';
    icp = cur_frame(i:i+3,j:j+3) - pred;
    sae = sum(sum(abs(icp)));
end
%---------------------------------------------------------
%% Mode selection for 4x4 prediciton

function [icp,pred,sae,mode] = mode_select_4(cur_frame,cur_frame_ref,i,j)
    [icp1,pred1,sae1] = pred_vert_4(cur_frame,cur_frame_ref,i,j);
    [icp2,pred2,sae2] = pred_horz_4(cur_frame,cur_frame_ref,i,j);
    [icp3,pred3,sae3] = pred_dc_4(cur_frame,cur_frame_ref,i,j);
    [icp4,pred4,sae4] = pred_ddl_4(cur_frame,cur_frame_ref,i,j);
    [icp5,pred5,sae5] = pred_ddr_4(cur_frame,cur_frame_ref,i,j);
    [icp6,pred6,sae6] = pred_vr_4(cur_frame,cur_frame_ref,i,j);
    [icp7,pred7,sae7] = pred_hd_4(cur_frame,cur_frame_ref,i,j);
    [icp8,pred8,sae8] = pred_vl_4(cur_frame,cur_frame_ref,i,j);
    [icp9,pred9,sae9] = pred_hu_4(cur_frame,cur_frame_ref,i,j);
    
    [val, idx]=min([sae1 sae2 sae3 sae4 sae5 sae6 sae7 sae8 sae9]);
    
    switch idx
        case 1
            sae = sae1;
            icp = icp1;
            pred = pred1; 
            mode = 0;
        case 2
            sae = sae2;
            icp = icp2;
            pred = pred2;
            mode = 1;
        case 3
            sae = sae3;
            icp = icp3;
            pred = pred3;
            mode = 2;
        case 4
            sae = sae4;
            icp = icp4;
            pred = pred4; 
            mode = 3;
        case 5
            sae = sae5;
            icp = icp5;
            pred = pred5; 
            mode = 4;
        case 6
            sae = sae6;
            icp = icp6;
            pred = pred6; 
            mode = 5;
        case 7
            sae = sae7;
            icp = icp7;
            pred = pred7; 
            mode = 6;
        case 8
            sae = sae8;
            icp = icp8;
            pred = pred8; 
            mode = 7;
        case 9
            sae = sae9;
            icp = icp9;
            pred = pred9; 
            mode = 8;
    end
end

%--------------------------------------------------------------
function [bits_frame,cur_frame_ref,total_sae] = intra_16(cur_frame)
    global h w
    bits_frame = '';
    total_sae = 0;
    mode_prev = 0;
    mode = 0;
    mb_type = 0;            % 0 denotes 16x16, 1 denotes 4x4
    for i = 1:16:h
        for j = 1:16:w
            fprintf("Intra16: Processing MB(%d, %d)\n", i, j);
            bits_frame = [bits_frame dec2bin(mb_type)];    % taidao
            if (i==1)&(j==1)    % No prediciton
                mode = 4;       % Special mode to describe no prediction
                % [bits,mode_prev]= mb_header(mb_type,mode,mode_prev);
                bits_golomb = enc_golomb(mode - mode_prev, 1); % taidao
                mode_prev = mode; % taidao
                bits_frame = [bits_frame bits_golomb];
                
                [cur_frame_ref(i:i+15,j:j+15),bits] = code_block(cur_frame(i:i+15,j:j+15));
                bits_frame = [bits_frame bits];
            elseif (i==1)       % Horz prediction
                mode = 1;       
                % [bits,mode_prev]= mb_header(mb_type,mode,mode_prev);
                bits_golomb = enc_golomb(mode - mode_prev, 1);
                mode_prev = mode;
                bits_frame = [bits_frame bits_golomb];
                
                [icp,pred,sae] = pred_horz_16(cur_frame,cur_frame_ref,16,i,j);
                [icp_r,bits] = code_block(icp);
                bits_frame = [bits_frame bits];
                cur_frame_ref(i:i+15,j:j+15)= icp_r + pred;
                total_sae = total_sae + sae;
            elseif (j==1)       % Vert prediction
                mode = 0;       
                % [bits,mode_prev]= mb_header(mb_type,mode,mode_prev);
                bits_golomb = enc_golomb(mode - mode_prev, 1);
                mode_prev = mode;
                bits_frame = [bits_frame bits_golomb];
                
                [icp,pred,sae] = pred_vert_16(cur_frame,cur_frame_ref,16,i,j);
                [icp_r,bits] = code_block(icp);
                bits_frame = [bits_frame bits];
                cur_frame_ref(i:i+15,j:j+15)= icp_r + pred;
                total_sae = total_sae + sae;
            else                % Try all different prediction
                [icp,pred,sae,mode] = mode_select_16(cur_frame,cur_frame_ref,16,i,j);
                % [bits,mode_prev]= mb_header(mb_type,mode,mode_prev);
                bits_golomb = enc_golomb(mode - mode_prev, 1);
                mode_prev = mode;
                bits_frame = [bits_frame bits_golomb];
                
                [icp_r,bits] = code_block(icp);
                bits_frame = [bits_frame bits];
                cur_frame_ref(i:i+15,j:j+15)= icp_r + pred;
                total_sae = total_sae + sae;
            end
        end
    end
end

%--------------------------------------------------------
%% Transform, Quantization, Entropy coding
% transform = Integer transform
% Quantization = h.264 
% VLC = CAVLC (H.264)

function [err_r,bits_mb] = code_block(err)
    global QP
    
    [n,m] = size(err);
    
    bits_mb = '';
    
    for i = 1:4:n
        for j = 1:4:m
            c(i:i+3,j:j+3) = integer_transform(err(i:i+3,j:j+3));
            cq(i:i+3,j:j+3) = quantization(c(i:i+3,j:j+3),QP);
            [bits_b] = enc_cavlc(cq(i:i+3,j:j+3), 0, 0);       
            bits_mb = [bits_mb bits_b];       
            Wi = inv_quantization(cq(i:i+3,j:j+3),QP);
            Y = inv_integer_transform(Wi);        
            err_r(i:i+3,j:j+3) = round(Y/64);        
        end
    end
end
%-------------------------------------------------------
%% 16x16 Horizontal prediciton

function [icp,pred,sae] = pred_horz_16(cur_frame,cur_frame_ref,bs,i,j)
    pred = cur_frame_ref(i:i+15,j-1)*ones(1,bs);
    icp = cur_frame(i:i+15,j:j+15) - pred;
    sae = sum(sum(abs(icp)));
end
%-------------------------------------------------------
%% 16x16 Vertical Prediciton

function [icp,pred,sae] = pred_vert_16(cur_frame,cur_frame_ref,bs,i,j)
    pred = ones(bs,1)*cur_frame_ref(i-1,j:j+15);
    icp = cur_frame(i:i+15,j:j+15) - pred;
    sae = sum(sum(abs(icp)));
end
%-------------------------------------------------------
%% 16x16 DC prediction

function [icp,pred,sae] = pred_dc_16(cur_frame,cur_frame_ref,bs,i,j)
    pred = bitshift(sum(cur_frame_ref(i-1,j:j+15))+ sum(cur_frame_ref(i:i+15,j-1))+16,-5);
    icp = cur_frame(i:i+15,j:j+15) - pred;
    sae = sum(sum(abs(icp)));
end
%------------------------------------------------------
%% 16x16 Plane prediction

function [icp,pred,sae] = pred_plane_16(cur_frame,cur_frame_ref,bs,i,j)
    x = 0:7;
    H = sum((x+1)*(cur_frame_ref(i+x+8,j-1)-cur_frame_ref(i+6-x,j-1)));
    y = 0:7;
    V = sum((y+1)*(cur_frame_ref(i-1,j+8+y)'-cur_frame_ref(i-1,j+6-y)'));
    
    a = 16*(cur_frame_ref(i-1,j+15) + cur_frame_ref(i+15,j-1));
    b = bitshift(5*H + 32,-6,'int64');
    c = bitshift(5*V + 32,-6,'int64');
    
    % pred = clipy() << refer to the standard
    for m = 1:16
        for n = 1:16
            d = bitshift(a + b*(m-8)+ c*(n-8) + 16, -5,'int64');
            if d <0
                pred(m,n) = 0;
            elseif d>255
                pred(m,n) = 255;
            else
                pred(m,n) = d;
            end
        end
    end
    
    icp = cur_frame(i:i+15,j:j+15) - pred;
    sae = sum(sum(abs(icp)));
end
%---------------------------------------------------------
%% Mode selection for 16x16 prediciton

function [icp,pred,sae,mode] = mode_select_16(cur_frame,cur_frame_ref,bs,i,j)
    [icp1,pred1,sae1] = pred_vert_16(cur_frame,cur_frame_ref,bs,i,j);
    [icp2,pred2,sae2] = pred_horz_16(cur_frame,cur_frame_ref,bs,i,j);
    [icp3,pred3,sae3] = pred_dc_16(cur_frame,cur_frame_ref,bs,i,j);
    [icp4,pred4,sae4] = pred_plane_16(cur_frame,cur_frame_ref,bs,i,j);
    
    [val,idx]=min([sae1 sae2 sae3 sae4]);
    
    switch idx
        case 1
            sae = sae1;
            icp = icp1;
            pred = pred1; 
            mode = 0;
        case 2
            sae = sae2;
            icp = icp2;
            pred = pred2;
            mode = 1;
        case 3
            sae = sae3;
            icp = icp3;
            pred = pred3;
            mode = 2;
        case 4
            sae = sae4;
            icp = icp4;
            pred = pred4; 
            mode = 3;
    end
end

