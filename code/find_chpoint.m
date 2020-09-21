function [cp,SigLev] = find_chpoint(temp)

%   This function estimate change point (cp) and level of significance (SigLev)
%   for a given time series (temp) according to Taylor (2000) 
%   http://www.variation.com/cpa/tech/changepoint.html
%   parameter to be defined: nboot (bootstrap number of iterations)
%   Author: Fabiana Castino (15.04.2016)

    clear S S0 Sd Sbd 
    nyrs = length(temp);
    mtemp = nanmean(temp);
    S = zeros(nyrs+1,1);
    S0 = 0.;
    for is = 2 : nyrs + 1
        if ~isnan(temp(is-1,1))
            S(is,1) = S0 + temp(is-1,1) - mtemp;
            S0 = S(is,1);
        else
            S(is,1) = NaN;
        end
    end
    Sd = nanmax(S) - nanmin(S);
    % bootstrap
    nboot = 5000;
    Sbd = NaN(nboot,1);
    for iib = 1 : nboot
        clear iip tempb Sb Sb0
        iip = randperm(nyrs);
        tempb = temp(iip);
        Sb = zeros(nyrs+1,1);
        Sb0 = 0.;
        for is = 2 : nyrs + 1
            if ~isnan(tempb(is-1,1))
                Sb(is,1) = Sb0 + tempb(is-1,1) - mtemp;
                Sb0 = Sb(is,1);
            else
                Sb(is,1) = NaN;
            end
        end
        Sbd(iib,1) = nanmax(Sb) - nanmin(Sb);
    end
    SigLev = 100 - 100*length(find(Sd>Sbd))/nboot;
    cp = find(abs(S)==nanmax(abs(S))) - 1; %change point

    end
