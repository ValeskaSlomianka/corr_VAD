function a= getThreshold(power,method)
arguments
    power double
    method string = "intercept"
end

plotOn=1;
%fit gauss
%[N,bin]=histcounts(power);
power(power<-100)=[];
%g=fit(bin(1:end-1)',N','gauss2');
g=fitgmdist(power(:),2,'Start',(power(:)>max(power(:))-40)+1);
if strcmpi(method,"intercept")
    try
        a=fzero(@(x) g.ComponentProportion(1)*pdf('Normal',x,g.mu(1),sqrt(g.Sigma(:,:,1))) - g.ComponentProportion(2)*pdf('Normal',x,g.mu(2),sqrt(g.Sigma(:,:,2))),[g.mu(1),g.mu(2)]);
    catch
        a=-40;
        disp('could not calc threshold, use -40dB instead')

    end
elseif strcmpi(method,"2sd")
    a=g.mu(1)+ 2*sqrt(g.Sigma(:,:,1));
elseif strcmpi(method,"2sdM")
    a=g.mu(2)- 2*sqrt(g.Sigma(:,:,2));
elseif strcmpi(method,"max")
    a=max(power(:))-40;
end

if plotOn
    figure
    h=histogram(power,'Normalization','pdf', 'BinWidth',1);
    hold on
    plot(h.BinEdges(1:end-1)',g.ComponentProportion(1)*pdf('Normal',h.BinEdges(1:end-1),g.mu(1),sqrt(g.Sigma(:,:,1))));

    plot(h.BinEdges(1:end-1)',g.ComponentProportion(2)*pdf('Normal',h.BinEdges(1:end-1),g.mu(2),sqrt(g.Sigma(:,:,2))));
    xline(a)
end
end

