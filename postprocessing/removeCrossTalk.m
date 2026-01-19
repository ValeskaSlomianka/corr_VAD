function [actArr] = removeCrossTalk(actArr,rs,power,  pT,lT)
arguments
    actArr logical
    rs double
    power double
    pT double = 6
    lT double = -100 %removes more the higher
end
rT=0.4;
%% function to remove crosstalk. Crosstalk is detected by comparing the power in both channels. If the power difference is higher than pT,  there is a certain lag, then it is considered as crosstalk. Otherwise it is likely speech overlap
inter=1:size(actArr,1);
crosstalk=zeros(size(actArr));
for s=1:size(actArr,1)
    tmpinter=inter;
    tmpinter(s)=[];
    pi=1+(s-1)*size(power,2)/size(actArr,1);
    for tmp=tmpinter
        %check for activity in both channels
        pii=1+(tmp-1)*size(power,2)/size(actArr,1);
        potentialCrosstalk=actArr(s,:)&actArr(tmp,:);
        powerDiff = power(:,pi)-power(:,pii)<pT;

        %lagDiff = lags(:,(pi-1)*size(lags,2)/size(actArr,1)+pii)>lT;
        rsDiff = rs(:,(pi-1)*size(rs,2)/size(actArr,1)+pii)>rT;

        %tmpC=potentialCrosstalk&powerDiff'&(lagDiff');
        tmpC=potentialCrosstalk&powerDiff'&(rsDiff');

        crosstalk(s,:)=crosstalk(s,:)|tmpC;

    end

end

actArr=actArr-crosstalk;

end

