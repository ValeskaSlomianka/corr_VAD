function f=plotSpeech(audio,fs,act,t,turn,channel,titles)
arguments
    audio double
    fs double
    act logical
    t double
    turn logical = 0
    channel double = [1,4,7]
    titles string = ["Subject 81", "Subject 21", "Subject 11"]

end


n=length(channel);
if turn
    for i = 1:n

        act(i,:)=mergeAndRemoveBurst(act(i,:),t,0.5,1);
    end
    act=mergeUninterruptedPauses(act);
end

color= [1 0 0 .3; 0 1  0 .3;0 0 1  .3];
f=figure
for i = 1:n
    subplot(n,1,i)

    plotSegmentation(audio(:,channel(i)),fs,act(i,:),t,color(i,:));
    title(titles(i))
    %ylim([-0.3, 0.3])
    % ax=gca;
    % ax.FontSize=12;
    % box(ax,'off')
end
end