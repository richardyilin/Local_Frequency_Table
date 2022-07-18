close all;
clc;
clear;
symbols = zeros(1,128);
for i = 0 : 127
    symbols(1,i+1) = i;
end
file_num = 7;
names = strings(file_num,1);
ratio = zeros(file_num,1);
correctness = false(file_num,1);
code_length = zeros(file_num,1);
for k = 1 : file_num
    switch k
        case 1
            name = 'argue';
        case 2
            name = 'gray';
        case 3
            name = 'habit';
        case 4
            name = 'money';
        case 5
            name = 'normal';
        case 6
            name = 'wealth';
        case 7
            name = 'where';
    end
    names(k,1) = name;
    file_name = strcat('./testing/',name,'.txt');
    fileID = fopen(file_name,'r');
    buffer = fscanf(fileID,'%c');
    fclose(fileID);
    %len = 1000;
    len = length(buffer);
    inputSig = zeros(1,len);
    % change line is 13 then 10
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
    file_name2 = strcat('./result/',name,'.txt');
    fileID = fopen(file_name2,'w');
    fprintf(fileID,'length of the code %d\nlength of the seqence %d\nratio %f\n',code_len,seq_len,rate);
    fprintf(fileID,'decoding correctness: %d\n',correct);
    fclose(fileID);
    names(k,1) = name;
    ratio(k,1) = rate;
    code_length(k,1) = length(code);
    correctness(k,1) = correct; 
end
excel_file_name = strcat('./result_excel/StaticHuffman_data.xlsx');
T = table(names,ratio,code_length,correctness);
writetable(T,excel_file_name,'Sheet',1,'Range','B2');