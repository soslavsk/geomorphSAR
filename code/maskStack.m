function [maskedStack] = maskStack(stack,mask)
%
%
%   Function to apply dynamic mask to coherence stack.
%
%   INPUTS:
%       stack       x by y by n stack of coherence images
%       mask        x by y by n stack of mask images (logical)
%
%   OUTPUT:
%       maskedstack     masked coherence stack.


maskedStack = stack;

for i = 1:length(stack)
    maskedStack{i}.coh.Z(mask{i}.mask.Z == 1) = NaN;
end