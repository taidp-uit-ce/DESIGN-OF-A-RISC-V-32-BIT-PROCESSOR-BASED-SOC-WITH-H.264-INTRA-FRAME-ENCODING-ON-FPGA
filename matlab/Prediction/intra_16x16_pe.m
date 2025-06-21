%% Prediction Engine Module

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