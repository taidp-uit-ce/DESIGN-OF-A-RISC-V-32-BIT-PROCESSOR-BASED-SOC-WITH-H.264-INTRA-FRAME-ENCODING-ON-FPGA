for i = -9:1:9
    temp = enc_golomb(i, 1);
    fprintf('i=%d => bits = %s |length = %d\n', i, temp, length(temp));
    [temp2, pos] = dec_golomb(1, temp, 1);
    fprintf('bits = %s => i = %d | pos = %d\n', temp, temp2(1), pos);
    x = i - temp2;
    if x ~= 0
        disp('diff');
    else
        disp('matched');
    end
end