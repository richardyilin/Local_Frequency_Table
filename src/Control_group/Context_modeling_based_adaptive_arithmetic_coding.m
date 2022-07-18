close all;
clc;
clear;
num_condition = 6;
file_num = 7;
ratio = zeros(file_num,1);
names = strings(file_num,1);
original_code_length = zeros(file_num,1);
total_code_length = zeros(file_num,1);
correctness = false(file_num,1);
never_occur = [0,1,2,3,4,5,6,7,8,9,11,12,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,127];
minimum = mpower(10,-5);
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
    code = arithmetic_encoding(seq,num_condition,never_occur,minimum);
    string = arithmetic_decoding(length(seq),code,num_condition,never_occur,minimum);
    correct = strcmp(seq,string);
    assert(correct);
    code_len = length(code) + ceil(log2(length(seq)));
    rate = code_len / length(seq);
    ratio(k,1) = rate;
    correctness(k,1) = correct;
    total_code_length(k,1) = code_len;
    original_code_length(k,1) = length(code);
    assert(correct,'decode incorrectly\nfile name %s\n',file_name);
    fprintf('decoding correctness %d\n',correct);
    fprintf('length of the code %d\nlength of the seqence %d\nratio %f\n',code_len,length(seq),rate);
    file_name2 = strcat('./result/',name,'.txt');
    fileID = fopen(file_name2,'w');
    fprintf(fileID,'length of the code %d\nlength of the seqence %d\nratio %f\n',code_len,length(seq),rate);
    fprintf(fileID,'decoding correctness: %d\n',correct);  
end
excel_file_name = strcat('./result_excel/ContextModeling_data.xlsx');
T = table(names,ratio,total_code_length,original_code_length,correctness);
writetable(T,excel_file_name,'Sheet',1,'Range','B11');
function code = arithmetic_encoding(seq, num_condition,never_occur,minimum) % k-ary, X is encoded by C(k,b) 
    accum = ones(num_condition,128);
    for i = 1 : length(never_occur)
        accum(:,never_occur(1,i)+1) = repmat(minimum,num_condition,1);
    end
    total = sum(accum,2);
    prob = accum ./ total;
    lower = 0;
    upper = 1;
    code = '';
    S=[zeros(num_condition,1),cumsum(prob')'];   % modified
    for i = 1 : length(seq)
        index = seq(1,i) + 1;
        fprintf('encoding i: %d length(seq) %d\n',i,length(seq));
        if i ~= 1
            %fprintf('seq(i-1) %s seq(i-1) %d prev_index %d\n',seq(i-1),seq(i-1),prev_index);
            if (seq(1,i-1) >= 65 && seq(1,i-1) <= 90) || (seq(1,i-1) >= 97 && seq(1,i-1) <= 122)
                if (seq(1,i-1) ~=  65 && seq(1,i-1) ~=  69 && seq(1,i-1) ~=  73 && seq(1,i-1) ~= 79  && seq(1,i-1) ~= 85  && seq(1,i-1) ~= 97  && seq(1,i-1) ~= 101  && seq(1,i-1) ~= 105  && seq(1,i-1) ~=  111 && seq(1,i-1) ~= 117) % consonant
                    condition = 1;
                else % vowel
                    condition = 2;
                end
            elseif seq(1,i-1) == 32 && i > 2
                prev_two_index = seq(i-2);
                if prev_two_index ~= 46 && ~isequal(seq(1,i-2),'?') && ~isequal(seq(1,i-2),'!') % last is blank and last last is not period
                    condition = 4;
                %elseif (prev_two_index >=97 && prev_two_index <= 122)
                    %condition = 7;
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
        lower_new = lower + (upper - lower) * S(condition,index);
        upper_new = lower + (upper - lower) * S(condition,index+1);
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
        accum(condition,index) = accum(condition,index) + 1;
        total(condition,1) = total(condition,1) + 1;        
        % change here
        if total(condition) > 1000000   % modified              
            accum(condition,:) = ceil(accum(condition,:)/10);  % modified    
            total(condition) = sum(accum(condition,:));
        end      
        % until here        
        prob(condition,:) = accum(condition,:) / total(condition,1); 
        S=[zeros(num_condition,1),cumsum(prob')'];   % modified
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
function string = arithmetic_decoding(N, code, num_condition,never_occur,minimum) % k-ary, X is encoded by C(k,b) N is the length of data
    string = '';
    accum = ones(num_condition,128);
    for i = 1 : length(never_occur)
        accum(:,never_occur(1,i)+1) = repmat(minimum,num_condition,1);
    end
    total = sum(accum,2);
    prob = accum ./ total; 
    lower = 0; %encoded data
    upper = 1; %encoded data
    lower1 = 0; % bit
    upper1 = 1; % bit
    S=[zeros(num_condition,1),cumsum(prob')'];   % modified
    bit_index = 1;
    current_code_length = 0;
    condition = 3;
    while(current_code_length < N)
        fprintf('current_code_length %d code length %d\n',current_code_length,N);
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
            for index = 1 : 128
                lower2 = lower + (upper - lower) * S(condition,index);
                upper2 = lower + (upper - lower) * S(condition,index+1);
                if(lower2 <= lower1 && upper2 >= upper1)
                    in_range = true;
                    string(1,current_code_length+1) = char(index-1);                    
                    lower = lower2;
                    upper = upper2;
                    accum(condition,index) = accum(condition,index) + 1;
                    total(condition,1) = total(condition,1) + 1;                    
                     % change here
                    if total(condition,1) > 1000000          % modified     
                        accum(condition,:) = ceil(accum(condition,:)/10);   % modified 
                        total(condition,1) = sum(accum(condition,:));
                    end  
                    % until here                    
                    prob(condition,:) = accum(condition,:) / total(condition,1);
                    S=[zeros(num_condition,1),cumsum(prob')'];   % modified
                    current_code_length = current_code_length + 1;
                    prev_index = index - 1; % ascii
                    if (prev_index >= 65 && prev_index <= 90) || (prev_index >= 97 && prev_index <= 122)
                        if (prev_index ~=  65 && prev_index ~=  69 && prev_index ~=  73 && prev_index ~= 79  && prev_index ~= 85  && prev_index ~= 97  && prev_index ~= 101  && prev_index ~= 105  && prev_index ~=  111 && prev_index ~= 117) % consonant
                            condition = 1;
                        else
                            condition = 2;
                        end
                    elseif prev_index == 32 && current_code_length > 1
                        prev_two_index = string(1,current_code_length-1);
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
                    break;
                end   
            end
        end        
    end
end