close all;
clc;
clear;

file_names = ["Thank_you_for_Arguing" "The_7_Habits_of_Highly_Effective_People" "What_Money_Cant_Buy" "Normal_People" "Wealth_Poverty_and_Politics" "Where_the_Crawdads_Sing"];
for name = file_names
    file_name = strcat('../../Test_patterns/',name,'.txt');
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
    assert(correct,'Decode incorrectly\nfile path %s\n', file_name);
    fprintf('File path: %s\n', file_name);
    fprintf('Decoding correctness %d\n', correct);
    fprintf('Length of the code %d\n', code_len);
    fprintf('Length of the seqence %d\n', length(seq));
    fprintf('Compression ratio %f\n\n', rate);
end
function code = arithmetic_encoding(seq, prob)
    lower = 0;
    upper = 1;
    code = '';
    prefix_sum=[0,cumsum(prob')'];
    for i = 1 : length(seq)
        index = seq(1,i) + 1;        
        lower_new = lower + (upper - lower) * prefix_sum(1,index);
        upper_new = lower + (upper - lower) * prefix_sum(1,index+1);
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
function string = arithmetic_decoding(N, code, prob)
    string = '';    
    lower = 0;
    upper = 1;
    lower1 = 0;
    upper1 = 1;
    prefix_sum=[0,cumsum(prob')'];
    bit_index = 1;
    current_code_length = 0;
    while(current_code_length < N)
        bit = code(1,bit_index);
        bit_index = bit_index + 1;
        if bit == '1'
            lower1 = lower1 + (upper1 - lower1)/2;
        elseif bit == '0'
            upper1 = lower1 + (upper1 - lower1)/2;
        end
        in_range = true;
        while(in_range)
            in_range = false;
            for index = 1 : length(prob)
                lower2 = lower + (upper - lower) * prefix_sum(1,index);
                upper2 = lower + (upper - lower) * prefix_sum(1,index+1);
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