close all;
clc;
clear;
file_names = ["Thank_you_for_Arguing" "The_7_Habits_of_Highly_Effective_People" "What_Money_Cant_Buy" "Normal_People" "Wealth_Poverty_and_Politics" "Where_the_Crawdads_Sing"];
num_condition = 6;
upperbound = mpower(2,31);  
minimum = mpower(10,-5);
never_occur = [0,1,2,3,4,5,6,7,8,9,11,12,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,127];
for name = file_names
    file_name = strcat('../Test_patterns/',name,'.txt');
    fileID = fopen(file_name,'r');
    seq = fscanf(fileID,'%c');
    fclose(fileID);
    code = arithmetic_encoding(seq,num_condition,upperbound,never_occur,minimum);
    string = arithmetic_decoding(length(seq),code,num_condition,upperbound,never_occur,minimum);
    correct = strcmp(seq,string);
    assert(correct);
    code_len = length(code) + ceil(log2(length(seq)));
    rate = code_len / length(seq);
    assert(correct,'Decode incorrectly\nfile path %s\n', file_name);
    fprintf('File path: %s\n', file_name);
    fprintf('Decoding correctness %d\n', correct);
    fprintf('Length of the code %d\n', code_len);
    fprintf('Length of the seqence %d\n', length(seq));
    fprintf('Compression ratio %f\n\n', rate);
end
function code = arithmetic_encoding(seq, num_condition,upperbound,never_occur,minimum) % k-ary, X is encoded by C(k,b)    
    accum = ones(num_condition,128);
    for i = 1 : length(never_occur)
        accum(:,never_occur(1,i)+1) = repmat(minimum,num_condition,1);
    end
    total = sum(accum,2);
    prob = accum ./ total;
    lower = 0;
    upper = 1;
    code = '';
    prefix_sum=[zeros(num_condition,1),cumsum(prob')']; 
    for i = 1 : length(seq)
        index = seq(1,i) + 1;
        if i ~= 1
            if (seq(1,i-1) >= 65 && seq(1,i-1) <= 90) || (seq(1,i-1) >= 97 && seq(1,i-1) <= 122)
                if (seq(1,i-1) ~=  65 && seq(1,i-1) ~=  69 && seq(1,i-1) ~=  73 && seq(1,i-1) ~= 79  && seq(1,i-1) ~= 85  && seq(1,i-1) ~= 97  && seq(1,i-1) ~= 101  && seq(1,i-1) ~= 105  && seq(1,i-1) ~=  111 && seq(1,i-1) ~= 117) % consonant
                    condition = 1;
                else % vowel
                    condition = 2;
                end
            elseif seq(1,i-1) == 32 && i > 2
                prev_two_index = seq(1,i-2);
                if prev_two_index ~= 46 && ~strcmp(seq(1,i-2),'?') && ~strcmp(seq(1,i-2),'!') % last is blank and last last is not period
                    condition = 4;
                else % last is blank and last last is period
                   condition = 3;
                end
            elseif seq(1,i-1) >= 48 && seq(1,i-1) <= 57 % number
               condition = 5;
            else % otherwise
                condition = 6;
            end 
        else 
            condition = 3;
        end
        lower_new = lower + (upper - lower) * prefix_sum(condition,index);
        upper_new = lower + (upper - lower) * prefix_sum(condition,index+1);
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
        addend = 1;
        accum(condition,index) = accum(condition,index) + addend;
        total(condition,1) = total(condition,1) + addend;  
        if total(condition) > upperbound       
            accum(condition,:) = ceil(accum(condition,:)/10);    
            total(condition) = sum(accum(condition,:));
        end      
        prob(condition,:) = accum(condition,:) / total(condition,1); 
        prefix_sum = local_frequency_table(i, seq, num_condition, prob);
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
function seq = arithmetic_decoding(N, code, num_condition,upperbound,never_occur,minimum)
    seq = '';
    accum = ones(num_condition,128);
    for i = 1 : length(never_occur)
        accum(:,never_occur(1,i)+1) = repmat(minimum,num_condition,1);
    end
    total = sum(accum,2);
    prob = accum ./ total; 
    lower = 0;
    upper = 1;
    lower1 = 0;
    upper1 = 1;
    prefix_sum=[zeros(num_condition,1),cumsum(prob')'];
    bit_index = 1;
    i = 0;
    condition = 3;
    while(i < N)
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
            array = lower + (upper - lower) * prefix_sum(condition,:);
            index = find(array >= upper1, 1) - 1;
            if(array(1,index) <= lower1)
                in_range = true;
                seq(1,i+1) = char(index-1); 
                lower = array(1,index);
                upper = array(1,index+1);
                addend = 1;
                accum(condition,index) = accum(condition,index) + addend;
                total(condition,1) = total(condition,1) + addend;
                if total(condition,1) > upperbound         
                    accum(condition,:) = ceil(accum(condition,:)/10); 
                    total(condition,1) = sum(accum(condition,:));
                end             
                prob(condition,:) = accum(condition,:) / total(condition,1);
                i = i + 1;             
                prefix_sum = local_frequency_table(i, seq, num_condition, prob);
                prev_index = index - 1; % ascii
                if (prev_index >= 65 && prev_index <= 90) || (prev_index >= 97 && prev_index <= 122)
                    if (prev_index ~=  65 && prev_index ~=  69 && prev_index ~=  73 && prev_index ~= 79  && prev_index ~= 85  && prev_index ~= 97  && prev_index ~= 101  && prev_index ~= 105  && prev_index ~=  111 && prev_index ~= 117) % consonant
                        condition = 1;
                    else
                        condition = 2;
                    end
                elseif prev_index == 32 && i > 1
                    prev_two_index = seq(1,i-1);
                    if prev_two_index ~= 46 && ~strcmp(prev_two_index,'?') && ~strcmp(prev_two_index,'!')% last is blank and last last is not period
                        condition = 4;
                    else 
                        condition = 3;
                    end
                elseif prev_index >= 48 && prev_index <= 57 % number
                    condition = 5;
                else
                    condition = 6;
                end
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
            end 
            if i >= N
                break
            end
        end        
    end
end

function prefix_sum = local_frequency_table(i, seq, num_condition, local_prob)
    switch seq(1,i) % 31
        % below until ze is alphabet followed by space
        case 13
            local_prob(6,11) = local_prob(6,11) * 16777216;
        case 10
            local_prob(6,98:123) = local_prob(6,98:123) * 8;
            local_prob(6,66:91) = local_prob(6,66:91) * 8;
        case 39 % 's
            local_prob(6,116) = local_prob(6,116) * 32;
        case 'd'
            local_prob(1,33) = local_prob(1,33) * 4;
        case 'e'
            local_prob(2,33) = local_prob(2,33) * 2;
        case 'f'
            local_prob(1,33) = local_prob(1,33) * 2;
        case 'g'
            local_prob(1,33) = local_prob(1,33) * 2;
        case 's'
            local_prob(1,33) = local_prob(1,33) * 2;
        case 'y'
            local_prob(1,33) = local_prob(1,33) * 4;
        case 'z' %ze
            local_prob(1,102) = local_prob(1,102) * 4;
        case 'Q' % Qu
            local_prob(1,118) = local_prob(1,118) * 128;
        case 'q' % qu
            local_prob(1,118) = local_prob(1,118) * 4096;
        case 'T' % Th
            local_prob(1,105) = local_prob(1,105) * 32;
        case 'U' % Un
            local_prob(2,111) = local_prob(2,111) * 4;
        case 'V' % Ve
            local_prob(1,102) = local_prob(1,102) * 4;
        case 'v' % ve
            local_prob(1,102) = local_prob(1,102) * 16;
        case 'h' % he
            local_prob(1,102) = local_prob(1,102) * 4;
        case 'j' % ju
            local_prob(1,118) = local_prob(1,118) * 32;
        case ',' % ,
            local_prob(6,33) = local_prob(6,33) * 32;
            local_prob(6,14) = local_prob(6,14) * 8;
        case '.' % .
            local_prob(6,33) = local_prob(6,33) * 4;
            local_prob(6,14) = local_prob(6,14) * 8;
        case ':'
            local_prob(6,33) = local_prob(6,33) * 8;
            local_prob(6,14) = local_prob(6,14) * 8;
        case ';'
            local_prob(6,33) = local_prob(6,33) * 16;
            local_prob(6,14) = local_prob(6,14) * 8;
        case '?'
            local_prob(6,33) = local_prob(6,33) * 2;
            local_prob(6,14) = local_prob(6,14) * 8;
        case '-'
            local_prob(6,98:123) = local_prob(6,98:123) * 8;
        case '('
            local_prob(6,98:123) = local_prob(6,98:123) * 8;
    end
    % here is second order context
    if i > 1
        if (seq(1,i-1) >= 97 && seq(1,i-1) <= 122) && strcmp(seq(1,i),' ')
            local_prob(4,98:123) = local_prob(4,98:123) * 2;
        elseif strcmp(seq(1,i-1:i),'. ')
            local_prob(3,66:91) = local_prob(3,66:91) * 4;
            local_prob(3,98:123) = local_prob(3,98:123) / 2;
        elseif seq(1,i-1) == 10 && seq(1,i) == 84
            local_prob(1,105) = local_prob(1,105) * 2;
        elseif seq(1,i-1) == 10 && seq(1,i) == 87
            local_prob(1,105) = local_prob(1,105) * 16;
        elseif seq(1,i-1) == 10 && seq(1,i) == 89
            local_prob(1,112) = local_prob(1,112) * 16;
        elseif seq(1,i-1) == 10 && seq(1,i) == 105
            local_prob(2,111) = local_prob(2,111) * 8;
        elseif seq(1,i-1) == 10 && seq(1,i) == 113
            local_prob(1,118) = local_prob(1,118) * 16777216;
        elseif seq(1,i-1) == 10 && seq(1,i) == 116
            local_prob(1,105) = local_prob(1,105) * 32;
        elseif seq(1,i-1) == 10 && seq(1,i) == 121
            local_prob(1,112) = local_prob(1,112) * 64;
        elseif seq(1,i-1) == 32 && seq(1,i) == 81
            local_prob(1,118) = local_prob(1,118) * 2;
        elseif seq(1,i-1) == 32 && seq(1,i) == 84
            local_prob(1,105) = local_prob(1,105) * 2;
        elseif seq(1,i-1) == 32 && seq(1,i) == 89
            local_prob(1,112) = local_prob(1,112) * 32;
        elseif seq(1,i-1) == 32 && seq(1,i) == 106
            local_prob(1,118) = local_prob(1,118) * 2;
        elseif seq(1,i-1) == 32 && seq(1,i) == 113
            local_prob(1,118) = local_prob(1,118) * 8;
        elseif seq(1,i-1) == 32 && seq(1,i) == 116
            local_prob(1,105) = local_prob(1,105) * 32;
        elseif seq(1,i-1) == 32 && seq(1,i) == 121
            local_prob(1,112) = local_prob(1,112) * 64;
        elseif seq(1,i-1) == 33 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 2048;
        elseif seq(1,i-1) == 44 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 16384;
        elseif seq(1,i-1) == 45 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 4096;
        elseif seq(1,i-1) == 45 && seq(1,i) == 117
            local_prob(2,113) = local_prob(2,113) * 512;
        elseif seq(1,i-1) == 46 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 32768;
        elseif seq(1,i-1) == 46 && seq(1,i) == 44
            local_prob(6,33) = local_prob(6,33) * 2;
        elseif seq(1,i-1) == 46 && seq(1,i) == 67
            local_prob(1,47) = local_prob(1,47) * 64;
        elseif seq(1,i-1) == 55 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 4096;
        elseif seq(1,i-1) == 58 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 16384;
        elseif seq(1,i-1) == 59 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 4096;
        elseif seq(1,i-1) == 63 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 16384;
        elseif seq(1,i-1) == 65 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 4096;
        elseif seq(1,i-1) == 65 && seq(1,i) == 102
            local_prob(1,117) = local_prob(1,117) * 64;
        elseif seq(1,i-1) == 66 && seq(1,i) == 117
            local_prob(2,117) = local_prob(2,117) * 64;
        elseif seq(1,i-1) == 66 && seq(1,i) == 121
            local_prob(1,33) = local_prob(1,33) * 8;
        elseif seq(1,i-1) == 68 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 16384;
        elseif seq(1,i-1) == 69 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 8192;
        elseif seq(1,i-1) == 69 && seq(1,i) == 118
            local_prob(1,102) = local_prob(1,102) * 4;
        elseif seq(1,i-1) == 69 && seq(1,i) == 121
            local_prob(1,102) = local_prob(1,102) * 64;
        elseif seq(1,i-1) == 70 && seq(1,i) == 111
            local_prob(2,115) = local_prob(2,115) * 64;
        elseif seq(1,i-1) == 72 && seq(1,i) == 101
            local_prob(2,33) = local_prob(2,33) * 4;
        elseif seq(1,i-1) == 72 && seq(1,i) == 105
            local_prob(2,116) = local_prob(2,116) * 16;
        elseif seq(1,i-1) == 73 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 4096;
        elseif seq(1,i-1) == 73 && seq(1,i) == 79
            local_prob(2,79) = local_prob(2,79) * 2048;
        elseif seq(1,i-1) == 73 && seq(1,i) == 102
            local_prob(1,33) = local_prob(1,33) * 32;
        elseif seq(1,i-1) == 73 && seq(1,i) == 108
            local_prob(1,109) = local_prob(1,109) * 4096;
        elseif seq(1,i-1) == 73 && seq(1,i) == 110
            local_prob(1,33) = local_prob(1,33) * 8;
        elseif seq(1,i-1) == 73 && seq(1,i) == 116
            local_prob(1,33) = local_prob(1,33) * 8;
        elseif seq(1,i-1) == 73 && seq(1,i) == 118
            local_prob(1,102) = local_prob(1,102) * 8;
        elseif seq(1,i-1) == 77 && seq(1,i) == 121
            local_prob(1,33) = local_prob(1,33) * 8;
        elseif seq(1,i-1) == 78 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 4096;
        elseif seq(1,i-1) == 79 && seq(1,i) == 102
            local_prob(1,33) = local_prob(1,33) * 4;
        elseif seq(1,i-1) == 84 && seq(1,i) == 104
            local_prob(1,102) = local_prob(1,102) * 4;
        elseif seq(1,i-1) == 97 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 8192;
        elseif seq(1,i-1) == 97 && seq(1,i) == 46
            local_prob(6,33) = local_prob(6,33) * 2;
        elseif seq(1,i-1) == 97 && seq(1,i) == 107
            local_prob(1,102) = local_prob(1,102) * 8;
        elseif seq(1,i-1) == 97 && seq(1,i) == 115
            local_prob(1,33) = local_prob(1,33) * 2;
        elseif seq(1,i-1) == 98 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 4096;
        elseif seq(1,i-1) == 98 && seq(1,i) == 106
            local_prob(1,102) = local_prob(1,102) * 1024;
        elseif seq(1,i-1) == 98 && seq(1,i) == 117
            local_prob(2,117) = local_prob(2,117) * 16;
        elseif seq(1,i-1) == 98 && seq(1,i) == 118
            local_prob(1,106) = local_prob(1,106) * 2048;
        elseif seq(1,i-1) == 98 && seq(1,i) == 121
            local_prob(1,33) = local_prob(1,33) * 8;
        elseif seq(1,i-1) == 99 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 4096;
        elseif seq(1,i-1) == 99 && seq(1,i) == 44
            local_prob(6,33) = local_prob(6,33) * 2;
        elseif seq(1,i-1) == 99 && seq(1,i) == 46
            local_prob(6,33) = local_prob(6,33) * 2;
        elseif seq(1,i-1) == 100 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 8192;
        elseif seq(1,i-1) == 100 && seq(1,i) == 44
            local_prob(6,33) = local_prob(6,33) * 2;
        elseif seq(1,i-1) == 100 && seq(1,i) == 103
            local_prob(1,102) = local_prob(1,102) * 32;
        elseif seq(1,i-1) == 100 && seq(1,i) == 115
            local_prob(1,33) = local_prob(1,33) * 4;
        elseif seq(1,i-1) == 100 && seq(1,i) == 121
            local_prob(1,33) = local_prob(1,33) * 2;
        elseif seq(1,i-1) == 101 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 16384;
        elseif seq(1,i-1) == 101 && seq(1,i) == 44
            local_prob(6,33) = local_prob(6,33) * 2;
        elseif seq(1,i-1) == 101 && seq(1,i) == 58
            local_prob(6,33) = local_prob(6,33) * 2;
        elseif seq(1,i-1) == 101 && seq(1,i) == 100
            local_prob(1,33) = local_prob(1,33) * 2;
        elseif seq(1,i-1) == 101 && seq(1,i) == 113
            local_prob(1,118) = local_prob(1,118) * 16777216;
        elseif seq(1,i-1) == 101 && seq(1,i) == 121
            local_prob(1,33) = local_prob(1,33) * 2;
        elseif seq(1,i-1) == 102 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 8192;
        elseif seq(1,i-1) == 102 && seq(1,i) == 59
            local_prob(6,33) = local_prob(6,33) * 4;
        elseif seq(1,i-1) == 102 && seq(1,i) == 111
            local_prob(2,115) = local_prob(2,115) * 32;
        elseif seq(1,i-1) == 102 && seq(1,i) == 114
            local_prob(1,112) = local_prob(1,112) * 16;
        elseif seq(1,i-1) == 102 && seq(1,i) == 117
            local_prob(2,109) = local_prob(2,109) * 32;
        elseif seq(1,i-1) == 102 && seq(1,i) == 119
            local_prob(1,98) = local_prob(1,98) * 8;
        elseif seq(1,i-1) == 103 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 8192;
        elseif seq(1,i-1) == 103 && seq(1,i) == 44
            local_prob(6,33) = local_prob(6,33) * 2;
        elseif seq(1,i-1) == 103 && seq(1,i) == 104
            local_prob(1,117) = local_prob(1,117) * 64;
        elseif seq(1,i-1) == 103 && seq(1,i) == 115
            local_prob(1,33) = local_prob(1,33) * 4;
        elseif seq(1,i-1) == 104 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 4096;
        elseif seq(1,i-1) == 104 && seq(1,i) == 44
            local_prob(6,33) = local_prob(6,33) * 2;
        elseif seq(1,i-1) == 104 && seq(1,i) == 98
            local_prob(1,112) = local_prob(1,112) * 64;
        elseif seq(1,i-1) == 104 && seq(1,i) == 101
            local_prob(2,33) = local_prob(2,33) * 4;
        elseif seq(1,i-1) == 104 && seq(1,i) == 102
            local_prob(1,118) = local_prob(1,118) * 128;
        elseif seq(1,i-1) == 104 && seq(1,i) == 115
            local_prob(1,33) = local_prob(1,33) * 4;
        elseif seq(1,i-1) == 104 && seq(1,i) == 121
            local_prob(1,33) = local_prob(1,33) * 2;
        elseif seq(1,i-1) == 105 && seq(1,i) == 103
            local_prob(1,105) = local_prob(1,105) * 32;
        elseif seq(1,i-1) == 105 && seq(1,i) == 107
            local_prob(1,102) = local_prob(1,102) * 128;
        elseif seq(1,i-1) == 105 && seq(1,i) == 111
            local_prob(2,111) = local_prob(2,111) * 32;
        elseif seq(1,i-1) == 106 && seq(1,i) == 117
            local_prob(2,116) = local_prob(2,116) * 32;
        elseif seq(1,i-1) == 107 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 4096;
        elseif seq(1,i-1) == 107 && seq(1,i) == 44
            local_prob(6,33) = local_prob(6,33) * 2;
        elseif seq(1,i-1) == 107 && seq(1,i) == 46
            local_prob(6,33) = local_prob(6,33) * 2;
        elseif seq(1,i-1) == 107 && seq(1,i) == 103
            local_prob(1,115) = local_prob(1,115) * 1024;
        elseif seq(1,i-1) == 107 && seq(1,i) == 105
            local_prob(2,111) = local_prob(2,111) * 16;
        elseif seq(1,i-1) == 107 && seq(1,i) == 110
            local_prob(1,112) = local_prob(1,112) * 32;
        elseif seq(1,i-1) == 107 && seq(1,i) == 115
            local_prob(1,33) = local_prob(1,33) * 4;
        elseif seq(1,i-1) == 108 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 8192;
        elseif seq(1,i-1) == 108 && seq(1,i) == 100
            local_prob(1,33) = local_prob(1,33) * 2;
        elseif seq(1,i-1) == 108 && seq(1,i) == 114
            local_prob(1,102) = local_prob(1,102) * 32;
        elseif seq(1,i-1) == 108 && seq(1,i) == 118
            local_prob(1,102) = local_prob(1,102) * 4;
        elseif seq(1,i-1) == 108 && seq(1,i) == 119
            local_prob(1,98) = local_prob(1,98) * 512;
        elseif seq(1,i-1) == 108 && seq(1,i) == 121
            local_prob(1,33) = local_prob(1,33) * 2;
        elseif seq(1,i-1) == 109 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 8192;
        elseif seq(1,i-1) == 109 && seq(1,i) == 44
            local_prob(6,33) = local_prob(6,33) * 2;
        elseif seq(1,i-1) == 109 && seq(1,i) == 46
            local_prob(6,33) = local_prob(6,33) * 2;
        elseif seq(1,i-1) == 109 && seq(1,i) == 108
            local_prob(1,122) = local_prob(1,122) * 64;
        elseif seq(1,i-1) == 109 && seq(1,i) == 121
            local_prob(1,33) = local_prob(1,33) * 4;
        elseif seq(1,i-1) == 110 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 16384;
        elseif seq(1,i-1) == 110 && seq(1,i) == 44
            local_prob(6,33) = local_prob(6,33) * 2;
        elseif seq(1,i-1) == 110 && seq(1,i) == 100
            local_prob(1,33) = local_prob(1,33) * 2;
        elseif seq(1,i-1) == 110 && seq(1,i) == 103
            local_prob(1,33) = local_prob(1,33) * 4;
        elseif seq(1,i-1) == 110 && seq(1,i) == 108
            local_prob(1,122) = local_prob(1,122) * 256;
        elseif seq(1,i-1) == 110 && seq(1,i) == 120
            local_prob(1,106) = local_prob(1,106) * 64;
        elseif seq(1,i-1) == 111 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 8192;
        elseif seq(1,i-1) == 111 && seq(1,i) == 44
            local_prob(6,33) = local_prob(6,33) * 2;
        elseif seq(1,i-1) == 111 && seq(1,i) == 46
            local_prob(6,33) = local_prob(6,33) * 2;
        elseif seq(1,i-1) == 111 && seq(1,i) == 59
            local_prob(6,33) = local_prob(6,33) * 16777216;
        elseif seq(1,i-1) == 111 && seq(1,i) == 101
            local_prob(2,116) = local_prob(2,116) * 64;
        elseif seq(1,i-1) == 111 && seq(1,i) == 102
            local_prob(1,33) = local_prob(1,33) * 8;
        elseif seq(1,i-1) == 111 && seq(1,i) == 118
            local_prob(1,102) = local_prob(1,102) * 2;
        elseif seq(1,i-1) == 112 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 4096;
        elseif seq(1,i-1) == 112 && seq(1,i) == 44
            local_prob(6,33) = local_prob(6,33) * 2;
        elseif seq(1,i-1) == 114 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 16384;
        elseif seq(1,i-1) == 114 && seq(1,i) == 44
            local_prob(6,33) = local_prob(6,33) * 2;
        elseif seq(1,i-1) == 115 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 16384;
        elseif seq(1,i-1) == 115 && seq(1,i) == 44
            local_prob(6,33) = local_prob(6,33) * 2;
        elseif seq(1,i-1) == 115 && seq(1,i) == 58
            local_prob(6,33) = local_prob(6,33) * 2;
        elseif seq(1,i-1) == 115 && seq(1,i) == 113
            local_prob(1,118) = local_prob(1,118) * 16777216;
        elseif seq(1,i-1) == 116 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 16384;
        elseif seq(1,i-1) == 116 && seq(1,i) == 44
            local_prob(6,33) = local_prob(6,33) * 2;
        elseif seq(1,i-1) == 116 && seq(1,i) == 58
            local_prob(6,33) = local_prob(6,33) * 2;
        elseif seq(1,i-1) == 116 && seq(1,i) == 59
            local_prob(6,33) = local_prob(6,33) * 8;
        elseif seq(1,i-1) == 116 && seq(1,i) == 99
            local_prob(1,105) = local_prob(1,105) * 64;
        elseif seq(1,i-1) == 116 && seq(1,i) == 104
            local_prob(1,102) = local_prob(1,102) * 2;
        elseif seq(1,i-1) == 116 && seq(1,i) == 111
            local_prob(2,33) = local_prob(2,33) * 16;
        elseif seq(1,i-1) == 116 && seq(1,i) == 115
            local_prob(1,33) = local_prob(1,33) * 4;
        elseif seq(1,i-1) == 117 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 4096;
        elseif seq(1,i-1) == 117 && seq(1,i) == 102
            local_prob(1,103) = local_prob(1,103) * 1024;
        elseif seq(1,i-1) == 117 && seq(1,i) == 103
            local_prob(1,105) = local_prob(1,105) * 64;
        elseif seq(1,i-1) == 117 && seq(1,i) == 116
            local_prob(1,33) = local_prob(1,33) * 8;
        elseif seq(1,i-1) == 117 && seq(1,i) == 118
            local_prob(1,102) = local_prob(1,102) * 4;
        elseif seq(1,i-1) == 119 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 4096;
        elseif seq(1,i-1) == 119 && seq(1,i) == 44
            local_prob(6,33) = local_prob(6,33) * 2;
        elseif seq(1,i-1) == 119 && seq(1,i) == 59
            local_prob(6,33) = local_prob(6,33) * 16777216;
        elseif seq(1,i-1) == 119 && seq(1,i) == 110
            local_prob(1,33) = local_prob(1,33) * 8;
        elseif seq(1,i-1) == 119 && seq(1,i) == 115
            local_prob(1,33) = local_prob(1,33) * 4;
        elseif seq(1,i-1) == 120 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 1024;
        elseif seq(1,i-1) == 120 && seq(1,i) == 99
            local_prob(1,102) = local_prob(1,102) * 8;
        elseif seq(1,i-1) == 121 && seq(1,i) == 13
            local_prob(6,11) = local_prob(6,11) * 16384;
        elseif seq(1,i-1) == 121 && seq(1,i) == 44
            local_prob(6,33) = local_prob(6,33) * 2;
        elseif seq(1,i-1) == 121 && seq(1,i) == 59
            local_prob(6,33) = local_prob(6,33) * 4;
        elseif seq(1,i-1) == 121 && seq(1,i) == 105
            local_prob(2,111) = local_prob(2,111) * 128;
        elseif seq(1,i-1) == 121 && seq(1,i) == 111
            local_prob(2,118) = local_prob(2,118) * 512;
        elseif seq(1,i-1) == 121 && seq(1,i) == 116
            local_prob(1,105) = local_prob(1,105) * 128;
        elseif seq(1,i-1) == 121 && seq(1,i) == 118
            local_prob(1,102) = local_prob(1,102) * 16777216;
        elseif seq(1,i-1) == 122 && seq(1,i) == 108
            local_prob(1,102) = local_prob(1,102) * 8;
        end
    end

    local_prob = local_prob ./ sum(local_prob,2);
    prefix_sum = [zeros(num_condition,1),cumsum(local_prob')'];
end