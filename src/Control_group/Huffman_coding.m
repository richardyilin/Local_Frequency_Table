close all;
clc;
clear;
symbols = zeros(1,128);
for i = 0 : 127
    symbols(1,i+1) = i;
end
file_names = ["argue" "gray" "habit" "money" "normal" "wealth" "where"];
for name = file_names
    file_name = strcat('../../Test_patterns/',name,'.txt');
    fileID = fopen(file_name,'r');
    buffer = fscanf(fileID,'%c');
    fclose(fileID);
    len = length(buffer);
    inputSig = zeros(1,len);
    accum = zeros(1,128);
    for i = 1 : len
        inputSig(1,i) = buffer(1,i) + 0;
        accum(1,buffer(1,i)+1) = accum(1,buffer(1,i)+1) + 1;    
    end
    p = accum / sum(accum,2);
    [dict, average_code_length] = huffmandict(symbols,p);
    code = huffmanenco(inputSig,dict);
    sig = huffmandeco(code,dict);
    code_len = length(code) + 64 * 128;
    seq_len = length(inputSig);
    rate = code_len/seq_len;
    correct = isequal(inputSig,sig);
    assert(correct);
    fprintf('decoding correctness: %d\n',correct);
    fprintf('length of the code %d\nlength of the seqence %d\nratio %f\n',code_len,seq_len,rate);
end