close all;
clc;
clear;
file_num = 7;
ratio = zeros(file_num,1);
names = strings(file_num,1);
correctness = false(file_num,1);
symbol = '';
for i = 1 : 128
    symbol(1,i) = char(i-1);
end
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
    code = arithmetic_encoding(symbol,seq);
    string = arithmetic_decoding(symbol,length(seq),code);
    correct = strcmp(seq,string);
    assert(correct);
    code_len = length(code) + ceil(log2(length(seq)));
    rate = code_len / length(seq);
    ratio(k,1) = rate;
    total_code_length(k,1) = code_len;
    original_code_length(k,1) = length(code);
    correctness(k,1) = correct;
    assert(correct,'decode incorrectly\nfile name %s\n',file_name);
    fprintf('decoding correctness %d\n',correct);
    fprintf('length of the code %d\nlength of the seqence %d\nratio %f\n',code_len,length(seq),rate);
    file_name2 = strcat('./result/',name,'.txt');
    fileID = fopen(file_name2,'w');
    fprintf(fileID,'length of the code %d\nlength of the seqence %d\nratio %f\n',code_len,length(seq),rate);
    fprintf(fileID,'decoding correctness: %d\n',correct);  
end
excel_file_name = strcat('./result_excel/AdaptiveArithmetic_data.xlsx');
T = table(names,ratio,total_code_length,original_code_length,correctness);
writetable(T,excel_file_name,'Sheet',1,'Range','B11');

function code = arithmetic_encoding(symbol, seq) % k-ary, X is encoded by C(k,b) 
    accum = ones(1,length(symbol));
    total = length(symbol);
    prob = accum / total; 
    lower = 0;
    upper = 1;
    code = '';
    for i = 1 : length(seq)
        fprintf('encoding i %d\n',i);
        S=zeros(1,length(symbol)+1);
        for j=2:length(symbol)+1
            S(1,j)=S(1,j-1)+prob(1,j-1);
        end
        index = find(seq(i) == symbol);
        lower_new = lower + (upper - lower) * S(index);
        upper_new = lower + (upper - lower) * S(index+1);
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
        accum(1,index) = accum(1,index) + 1;
        total = total + 1;          
        if total >= mpower(2,31)   % modified              
            accum = ceil(accum/2);  % modified    
            total = sum(accum);
        end    
        prob = accum / total;
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
function string = arithmetic_decoding(symbol, N, code) % k-ary, X is encoded by C(k,b) N is the length of data
    string = '';
    accum = ones(1,length(symbol));
    total = length(symbol);
    prob = accum / total; 
    lower = 0; %encoded data
    upper = 1; %encoded data
    lower1 = 0; % bit
    upper1 = 1; % bit
    S=zeros(1,length(symbol)+1);
    for j=2:length(symbol)+1
        S(1,j)=S(1,j-1)+prob(1,j-1);
    end
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
        fprintf('decoding current_code_length %d\n',current_code_length);
        %fprintf('lower %f upper %f lower1 %f upper1 %f\n',lower,upper,lower1, upper1);
        in_range = true;
        while(in_range)
            in_range = false;
            for index = 1 : length(symbol)
                lower2 = lower + (upper - lower) * S(1,index);
                upper2 = lower + (upper - lower) * S(1,index+1); 
                if(lower2 <= lower1 && upper2 >= upper1)
                    in_range = true;
                    string = [string,symbol(1,index)];
                    lower = lower2;
                    upper = upper2;
                    accum(1,index) = accum(1,index) + 1;
                    total = total + 1;        
                    if total >= mpower(2,31)   % modified              
                        accum = ceil(accum/2);  % modified    
                        total = sum(accum);
                    end    
                    prob = accum / total;
                    for j=2:length(symbol)+1
                        S(1,j)=S(1,j-1)+prob(1,j-1);
                    end
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
                    %fprintf('string %s\n',string);
                    %fprintf('lower %f upper %f lower1 %f upper1 %f\n',lower,upper,lower1, upper1);
                    %{
                    while(upper <= 0.5)
                        lower = lower * 2;
                        upper = upper * 2;
                        lower1 = lower1 * 2;
                        upper1 = upper1 * 2;
                    end
                    while(lower >= 0.5)
                        lower = lower * 2 - 1;
                        upper = upper * 2 - 1;
                        lower1 = lower1 * 2 - 1;
                        upper1 = upper1 * 2 - 1;
                    end
                    %}
                    %fprintf('string %s\n',string);
                    %fprintf('lower %f upper %f lower1 %f upper1 %f\n',lower,upper,lower1, upper1);
                    break;
                end   
            end
        end        
    end
end