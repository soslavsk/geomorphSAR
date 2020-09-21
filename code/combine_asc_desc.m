function [sorted_stack,sorted_dates] = combine_asc_desc(asc_stack,desc_stack)
%
%
%   Function to combine ascending and desending track coherence image
%   stacks into one stack sorted by ascending dates. Ascending and
%   descending stacks should be created by the createStack.m function.
%
%   INPUTS:
%       asc_stack       ascending orbit stack of coherence images
%       desc_stack      descending orbit stack of coherence images
%
%   OUTPUTS:
%       sorted_stack    stack of ascending and descending coherence images
%                       sorted by ascending dates 
%       sorted_dates    vector of ascending dates as MATLAB date objects
%
%   S. Olen, 07.11.2019

%%



% Combine stacks into large cell structure, unsorted.
unsort_stack = [asc_stack desc_stack];

% Extract dates from unsorted, combined stack
for i = 1:length(unsort_stack)
	dates(i) = unsort_stack{i}.date;
end

% Sort dates to ascending order
[sorted_dates,idx] = sort(dates);


for i = 1:length(unsort_stack)
	sorted_stack{i} = unsort_stack{idx(i)};
end
