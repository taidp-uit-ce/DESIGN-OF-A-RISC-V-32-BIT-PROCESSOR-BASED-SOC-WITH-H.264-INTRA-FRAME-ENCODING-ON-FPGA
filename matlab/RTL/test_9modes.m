%% Prediction Engine module
cur_frame = [0  0  0  0  0
             0  0  0  0  0 
             0  40 41 42 43
             0  44 45 46 47
             0  48 49 50 51
             0  52 53 54 55];
cur_frame_ref = [0  0 0 0 0 0 0 0 0
                 50 51 52 53 54 55 56 57 58
                 59 0 0 0 0 0 0 0 0
                 60 0 0 0 0 0 0 0 0
                 61 0 0 0 0 0 0 0 0
                 62 0 0 0 0 0 0 0 0];
disp(size(cur_frame_ref));
[icp, pred, sae] = pred_hu_4(cur_frame, cur_frame_ref, 3, 2);
disp('icp=')
disp(convert_2comp(icp, 9));

disp('pred=');
disp(pred);

fprintf("sae=%f", sae);
%%
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
        fprintf("Không thể chọn chế độ VL do vượt quá biên ma trận!\n");
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
% function [icp,pred,sae] = pred_ddr_4(cur_frame,cur_frame_ref,i,j)
%     for y = 0:3 %taidao x => y
%         for x = 0:3 %taidao y => x
%             if (x>y)
%                 % pred(x+1,y+1) = bitshift(cur_frame_ref(i+x-y-2,j-1) + 2*cur_frame_ref(i+x-y-2,j-1) + cur_frame_ref(i+x-y,j-1) + 2,-2);
%                 pred(x+1,y+1) = bitshift(cur_frame_ref(i-1,j+x-y-2) + 2*cur_frame_ref(i-1,j+x-y-1) + cur_frame_ref(i-1,j+x-y) + 2,-2);
%             elseif (x<y)
%                 % pred(x+1,y+1) = bitshift(cur_frame_ref(i-1,j+y-x-2) + 2*cur_frame_ref(i-1,j+y-x-1) + cur_frame_ref(i-1,j+y-x) + 2,-2);
%                 pred(x+1,y+1) = bitshift(cur_frame_ref(i+y-x-2,j-1) + 2*cur_frame_ref(i+y-x-1,j-1) + cur_frame_ref(i+y-x,j-1) + 2,-2);
%             else
%                 % pred(x+1,y+1) = bitshift(cur_frame_ref(i,j-1) + 2*cur_frame_ref(i-1,j-1) + cur_frame_ref(i-1,j) + 2,-2);
%                 pred(x+1,y+1) = bitshift(cur_frame_ref(i-1,j) + 2*cur_frame_ref(i-1,j-1) + cur_frame_ref(i,j-1) + 2,-2);
%             end
%         end
%     end
%     pred = pred.';
%     icp = cur_frame(i:i+3,j:j+3) - pred;
%     sae = sum(sum(abs(icp)));
% end
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
% function [icp,pred,sae] = pred_vr_4(cur_frame,cur_frame_ref,i,j)
%     for x = 0:3
%         for y = 0:3
%             z = 2*x-y;
%             w = bitshift(y,-1);
%             if (z == 0 || z == 2 || z == 4 || z == 6)
%                 pred(x+1,y+1)= bitshift(cur_frame_ref(i+x-w-1,j-1) + cur_frame_ref(i+x-w,j-1) + 1,-1);
%             elseif rem(z,2)==1
%                 pred(x+1,y+1)= bitshift(cur_frame_ref(i+x-w-2,j-1) + 2*cur_frame_ref(i+x-w-1,j-1) + cur_frame_ref(i+x-w,j-1) + 2,-2);
%             elseif z==-1
%                 pred(x+1,y+1)= bitshift(cur_frame_ref(i-1,j)+ 2*cur_frame_ref(i-1,j-1) + cur_frame_ref(i,j-1) + 2,-2);
%             else
%                 pred(x+1,y+1) = bitshift(cur_frame_ref(i-1,j+y-1)+ 2*cur_frame_ref(i-1,j+y-2) + cur_frame_ref(i-1,j+y-3) + 2,-2);
%             end
%         end
%     end
% 
%     icp = cur_frame(i:i+3,j:j+3) - pred;
%     sae = sum(sum(abs(icp)));
% end
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
        fprintf("Không thể chọn chế độ VL do vượt quá biên ma trận!\n");
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