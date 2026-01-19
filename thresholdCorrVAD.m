function [speech] = thresholdCorrVAD(power,pT, rsS,corrT,rsO,crossO,lagS,lagsO,lagO,smooth, crosstalk)
arguments
    power double
    pT double
    rsS double = ones(size(power))
    corrT double = 0
    rsO double = zeros(size(power))
    crossO double = 1
    lagS double = zeros(size(power))
    lagsO double = zeros(size(power))
    lagO double = 1
    smooth logical = 0
    crosstalk logical = 0
end

if smooth
    power=movmedian(power,5);
    rsS=movmedian(rsS,5);
    rsO=movmedian(rsO,5);
    lagS=movmedian(lagS,5);
    lagsO=movmedian(lagsO,5);
end

if crosstalk

    speech=power>pT&max(rsS,[],2)>corrT&mean(lagS,2)<=0&mean(lagS,2)>-40&(lagsO(:,1)<lagO|lagsO(:,1)>300|rsO(:,1)<crossO)&(lagsO(:,2)<lagO|lagsO(:,2)>300|rsO(:,2)<crossO);
else
    speech=power>pT&max(rsS,[],2)>corrT&mean(lagS,2)<=0&mean(lagS,2)>-40;
end
end