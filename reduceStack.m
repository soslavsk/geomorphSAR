function [output] = reduceStack(stack,metric)

%   Function to create a temporal reduction of cohernece stack.
%
%   INPUTS:
%
%       stack       Coherence stack as craeted by createStack
%       metric      string specifying which statistic to reduce the stack
%                   by. Optoins include 'mean', 'median', 'minimum', 'prc5'
%                   (5th percentile), 'prc10', 'prc90', and 'std'.
%
%   OUTPUT:
%
%       reducedStack        Single geotiff of temporally reduced coherence
%                           stack
%
%   S. Olen, 06.11.2019


if iscell(stack) == 1
    zstack = stack{2}.coh;
    zstack.Z = []; zstack.size = stack{2}.coh.size(1:2);
    for i = 1:length(stack)
        zstack.Z(:,:,i) = stack{i}.coh.Z;
    end
end

output = stack{1}.coh;
output.Z = []; output.size = stack{1}.coh.size(1:2);

switch metric
    case 'mean'
        output.Z = nanmean(zstack.Z,3);
    case 'median'
        output.Z = nanmedian(zstack.Z,3);
    case 'minimum'
        output.Z = nanmin(zstack.Z,3);
    case 'prc5'
        output.Z = prctile(zstack.Z,5,3);
    case 'prc10'
        output.Z = prctile(zstack.Z,10,3);
    case 'prc90'
        output.Z = prctile(zstack.Z,90,3);
    case 'std'
        output.Z = nanstd(zstack.Z,1,3);
end

end
