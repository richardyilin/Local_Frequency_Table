close all;
clc;
clear;
file_num = 7;
names = strings(file_num,1);
ratio = zeros(file_num,1);
correctness = false(file_num,1);
original_code_length = zeros(file_num,1);
total_code_length = zeros(file_num,1);
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
    seq = fscanf(fileID,'%c');
    fclose(fileID);
    len = length(seq);
    frequency_table = zeros(1,128);
    for i = 1:128
        frequency_table(1,i) = sum(seq == (i-1));
    end
    frequency_table(frequency_table == 0) = 1;
    frequency_table = frequency_table/sum(frequency_table);
    code = arithmetic_encoding(seq,frequency_table);
    decoded_seq = arithmetic_decoding(length(seq),code,frequency_table);
    correct = strcmp(seq,decoded_seq);
    assert(correct);
    code_len = length(code) + 64 * 128;
    seq_len = length(decoded_seq);
    rate = code_len / seq_len;
    fprintf('length of the code %d\nlength of the seqence %d\nratio %f\n',code_len,seq_len,rate);
    file_name2 = strcat('./result/',name,'.txt');
    fileID = fopen(file_name2,'w');
    fprintf(fileID,'length of the code %d\nlength of the seqence %d\nratio %f\n',code_len,seq_len,rate);
    fprintf(fileID,'decoding correctness: %d\n',correct);
    fclose(fileID);
    names(k,1) = name;
    ratio(k,1) = rate;
    total_code_length(k,1) = code_len;
    original_code_length(k,1) = length(code);
    correctness(k,1) = correct; 
end
excel_file_name = strcat('./result_excel/StaticArithmetic_data.xlsx');
T = table(names,ratio,total_code_length,original_code_length,correctness);
writetable(T,excel_file_name,'Sheet',1,'Range','B2');
function code = arithmetic_encoding(seq, prob) % k-ary, X is encoded by C(k,b) 
    lower = 0;
    upper = 1;
    code = '';
    S=[0,cumsum(prob')'];   % modified
    for i = 1 : length(seq)
        fprintf('encoding i %d\n',i);
        index = seq(1,i) + 1;        
        lower_new = lower + (upper - lower) * S(1,index);
        upper_new = lower + (upper - lower) * S(1,index+1);
        lower = lower_new;
        upper = upper_new;
        while((upper <= 0.5 && lower <= 0.5) || (lower >= 0.5 && upper >= 0.5))
            if (upper <= 0.5 && lower <= 0.5)
                code = strcat(code,'0');
                lower = lower * 2;
                upper = upper * 2;                    
            elseif (lower >= 0.5 && upper >= 0.5)
                code = strcat(code,'1');
                lower = lower * 2 - 1;
                upper = upper * 2 - 1;                    
            end
        end  
    end
    b = 2;
    while(1)
        c = ceil(lower * mpower(2,b));
        if ((c+1) * mpower(2,-b) <= upper)
            break
        end
        b = b + 1;
    end
    code = strcat(code, dec2bin(c,b));
end
function string = arithmetic_decoding(N, code, prob) % k-ary, X is encoded by C(k,b) N is the length of data
    string = '';    
    lower = 0; %encoded data
    upper = 1; %encoded data
    lower1 = 0; % bit
    upper1 = 1; % bit
    S=[0,cumsum(prob')'];   % modified
    bit_index = 1;
    current_code_length = 0;
    while(current_code_length < N)
        fprintf('decoding current_code_length %d\n',current_code_length);
        bit = code(1,bit_index);
        bit_index = bit_index + 1;
        if bit == '1'
            lower1 = lower1 + (upper1 - lower1)/2;
        elseif bit == '0'
            upper1 = lower1 + (upper1 - lower1)/2;
        end
        %fprintf('lower %f upper %f lower1 %f upper1 %f\n',lower,upper,lower1, upper1);
        in_range = true;
        while(in_range)
            in_range = false;
            for index = 1 : length(prob)
                lower2 = lower + (upper - lower) * S(1,index);
                upper2 = lower + (upper - lower) * S(1,index+1);
                if(lower2 <= lower1 && upper2 >= upper1)
                    in_range = true;
                    string(1,current_code_length+1) = char(index-1);                    
                    lower = lower2;
                    upper = upper2;                   
                    current_code_length = current_code_length + 1;                    
                    while((upper <= 0.5 && lower <= 0.5) || (lower >= 0.5 && upper >= 0.5))
                        if (upper <= 0.5 && lower <= 0.5)
                            lower = lower * 2;
                            upper = upper * 2;
                            lower1 = lower1 * 2;
                            upper1 = upper1 * 2;
                        elseif (lower >= 0.5 && upper >= 0.5)
                            lower = lower * 2 - 1;
                            upper = upper * 2 - 1;
                            lower1 = lower1 * 2 - 1;
                            upper1 = upper1 * 2 - 1;
                        end
                    end
                    break;
                end   
            end
        end        
    end
end