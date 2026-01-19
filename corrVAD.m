function [rs,lags,power,t, actArr,idx,pT] = corrVAD(sig, fs,tLength,corrT,crossO,lagO,pT, burstThresh,silThresh,plotOn,hp,smooth,poverlap,mouthIdx, micsPerTalker)
% VOICEACTIVITYDETECTION
%    Detects voice activity in a matrix of sginals "sig" by computing the
%    squared RMS level (power) and cross correlation between signals in overlapping windows of tLength duration with
%    50% overlap, and determining speech dominant windows based on a power
%    threshold pT and a correlation threshold corrT.
%
%    Inputs:
%    - sig:      waveforms of talker in 9 channels                         [*x9 double]
%    - fs:       sampling rate                                [1x1 double]
%    - corrT:    threshold for cross corr with own in ear mics
%    - corrO:    threshold for cross corr with other mouth mics
%    - lagO:     threshold for cross corr lags with other mouth mics
%    - hp:       highpass filter frequency to remove breathing noise
%    - smooth:   apply smoothing to corr and power

%    - pT:       power threshold, if 0 use bimodal dirstribution of speech
%                 to calculate threshold
%    - tLength:  window length
%    - burstThresh: Threshold for small bursts that are unlikely to be speech
%    - silThresh:    Threshold for defining silent gaps
%

%    Outputs:
%    - idx:      struct with indices for speach activity
%    - actArr:   binary array indicating speech dominant (1)
%                or silence domaninant (0) windows.           [2x* logical]
%    - t:        time array with mid-points of each of the
%                windows                                      [1x* double]
%    - lags:     lags of the maximum correlation for each window and
%               channel pair
%    - rs:      maximum correlation
%    - power:    power in each window
arguments
    sig double
    fs double = 48000
    tLength double = 20e-3
    corrT double = 0
    crossO double =1
    lagO double = 0
    pT double = 0
    burstThresh double = 0.09
    silThresh double = 0.18
    plotOn logical = false
    hp double = 100
    smooth logical = false
    poverlap double = 0.5
    mouthIdx double = []   % optional: indices of mouth mics (one per talker)
    micsPerTalker double = [] % optional: if known, set 1 or 3 to force grouping

end

%% Bandpass filter signal to filter out breathing noise
if hp>0
    for i=1:size(sig,2)
        a=highpass(sig(:,i),hp,fs);
        sig(:,i)=a;
        clear a
    end
end
%% COMPUTE RMS and XCORR VALUES OF THE SIGNALS
% Define analysis window
window  = round(fs * tLength);                                              % Window size in samples
overlap = round(fs * poverlap*tLength);                                          % Overlap  in samples

timeVec = 0 : 1/fs : length(sig)/fs-1/fs;                                   % Time vector

b= buffer(1:length(sig),window,overlap,'nodelay'); %Buffer with indices for windows

%init output variables
t=zeros(1,size(b,2));
power=zeros(size(b,2),size(sig,2));
lags=zeros(size(b,2),size(sig,2)^2);
rs=zeros(size(lags));

for i=1:size(b,2)
    %calc xcorr and rms
    [r,lag]=xcorr(sig(b(b(:,i)>0,i),:),400,'normalized'); %calc xcorr for +-50 samples (could be changed, but higher values increase processing time)
    [rmax,midx]=max(abs(r),[],1); %get max xcorr
    power(i,:)=rms(sig(b(b(:,i)>0,i),:),1).^2;
    lags(i,:)=lag(midx);
    rs(i,:)=rmax;
    t(i)=mean(timeVec(b(b(:,i)>0,i))); %time of window

end


%% Threshold XCORR and energy and apply temporal constraints
if nargout > 4
    idx=struct();


    logPower = 10*log10(power);

    %threhold
    if pT == 0
        % --- Determine which channels to use for threshold estimation ---
        nCh = size(sig,2);

        % If caller provided mouthIdx, trust it (one index per talker)
        if ~isempty(mouthIdx)
            mouthCh = mouthIdx(:)';  % row vector
            % Basic sanity check
            if any(mouthCh < 1 | mouthCh > nCh)
                error('mouthIdx contains invalid channel indices.');
            end

        else
            % Try to infer grouping
            if ~isempty(micsPerTalker)
                mpt = micsPerTalker;
            else
                % Heuristic: if divisible by 3, assume triplets; else 1 mic per talker
                if mod(nCh,3) == 0 & nCh>3
                    mpt = 3;
                else
                    mpt = 1;
                end
            end

            if mpt == 3
                % Assume contiguous triplets: (1:3), (4:6), ...
                % and that the "mouth" mic is the first in each triplet.
                mouthCh = 1:3:nCh;  % [1,4,7,...]
            elseif mpt == 1
                % One mic per talker: use all channels as "mouth" channels
                mouthCh = 1:nCh;
            else
                error('Unsupported micsPerTalker=%d. Use 1 or 3, or supply mouthIdx.', mpt);
            end
        end

        % --- Choose a stable time region to estimate the threshold ---
        % Prefer excluding first/last 30 s; fall back gracefully for short recordings.
        if t(end) > 60
            tStart = 30;
            tStop  = t(end) - 30;
            iStart = find(t > tStart, 1, 'first');
            iStop  = find(t < tStop,  1, 'last');
            if isempty(iStart) || isempty(iStop) || iStart > iStop
                % Fallback: use middle 50% of frames
                iStart = round(0.25*length(t));
                iStop  = round(0.75*length(t));
            end
        else
            % Short session: use middle 80% of frames
            iStart = round(0.1*length(t));
            iStop  = round(0.9*length(t));
        end

        % --- Aggregate the RMS (in dB) from the selected "mouth" channels and time window ---
        powForThr = logPower(iStart:iStop, mouthCh);

        % --- Estimate threshold from a bimodal-like distribution using your helper ---
        % Note: getThreshold expects a matrix [time x channels]; '2sd' matches your current choice.
        pT = getThreshold(powForThr, '2sd');
    end

    actArr=zeros(numel(mouthCh),size(b,2));

    for s=1:numel(mouthCh)

        m = mouthCh(s);                              % this talker's mouth channel
        ownAux = [];% this talker's aux channels

        if mpt == 3
            ownAux= [m+1,m+2];
        end
        otherMouth = mouthCh; otherMouth(s) = [];    % other talkers' mouth channels

        % Columns in rs/lags for correlations between this talker's mouth and:
        %   (a) own aux mics
        colOwn   = pairCols(m, ownAux, nCh);         % may be empty for 1-mic layouts
        %   (b) other talkers' mouth mics
        colOther = pairCols(m, otherMouth, nCh);     % empty if single talker

        % Extract per-talker signals for thresholdCorrVAD
        pow_mouth   = logPower(:, m);
        rs_own      = rs(:, colOwn);
        rs_other    = rs(:, colOther);
        lags_own    = lags(:, colOwn);
        lags_other  = lags(:, colOther);

        % Call your decision function (must handle empty rs_own/lag_own gracefully)
        actArr(s,:) = thresholdCorrVAD( ...
            pow_mouth, pT, ...
            rs_own,   corrT, ...
            rs_other, crossO, ...
            lags_own, lags_other, ...
            lagO, smooth);

        % Post-process per talker:  Bridge pauses, remove bursts of speech
        [actArr(s,:), idx(s).onsets] = mergeAndRemoveBurst(actArr(s,:), t, burstThresh, silThresh);


    end
end



%% ACTIVITY ARRAYS AND RMS WAVEFORMS STACKED
if plotOn
    plotSpeech(sig,fs,actArr,t);

end
end



function cols = pairCols(i, js, nCh)
% Map (i, j) → column indices in MATLAB's xcorr matrix output: (i-1)*nCh + j
if isempty(js)
    cols = [];
else
    js = js(:).';
    cols = (i-1)*nCh + js;
end
end


