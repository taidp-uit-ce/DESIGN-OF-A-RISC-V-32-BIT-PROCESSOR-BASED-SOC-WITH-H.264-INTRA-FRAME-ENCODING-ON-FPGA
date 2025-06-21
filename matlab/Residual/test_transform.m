
clear all;
clc;
addpath(genpath('.'));
load table;
global Table_coeff0 Table_coeff1 Table_coeff2 Table_coeff3
global Table_run Table_zeros


X = [58 64 51 58
     52 64 56 66
     62 63 61 64
     59 51 63 69];
 
 QP = 6;
 disp('Before transform X =');
 disp(X);
 W = integer_transform(X);
 disp('After transform W=');
 disp(W);
 Z = quantization(W,QP);
 disp('After quantization Z=');
 disp(Z);
 [bits] = enc_cavlc(Z, 0, 0);
 
 [Z1,i] = dec_cavlc(bits,0,0);
 
 %diff = Z - Z1
 
  Wi = inv_quantization(Z1,QP);
 
  Y = inv_integer_transform(Wi);
    
  %  post scaling - very important 
  Xi = round(Y/64);

  %disp(Xi);
  
  scan = [1,1;1,2;2,1;3,1;2,2;1,3;1,4;2,3;3,2;4,1;4,2;3,3;2,4;3,4;4,3;4,4];

    for i=1:16
       m=scan(i,1);
       n=scan(i,2);
       l(i)=Z(m,n); % l contains the reordered data
    end
    disp(l);