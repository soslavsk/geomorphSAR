function [ndjfma_stack,mjjaso_stack] = splitStack(stack)
%
%   Function to divide coherence stack into stacks containing only NDJFMA
%   (e.g., austral summer) and MJJASO (e.g., austral winter) for regions
%   with strong seasonal precipitation patterns.
%
%   INPUTS:
%       stack       coherence stack craeted by createStack.m
%
%   OUTPUTS:
%       ndjfma_stack    coherence stack containing only scenes from NDJFMA
%       mjjaso_stack    coherence stack containing only scenes from MJJASO
%
%   S. Olen, 6.11.2019

count_dry = 0;
count_wet = 0;

for i = 1:length(stack)
    
    [y,m,d] = ymd(stack{i}.date);
    
    if ismember(m,[11 12 1 2 3 4]) == 1
        count_wet = count_wet + 1;
        ndjfma_stack{count_wet} = stack{i};
    elseif ismember(m,[5 6 7 8 9 10]) == 1
        count_dry = count_dry +1 ;
        mjjaso_stack{count_dry} = stack{i};
    end
    
end

end