function noisepatterns = MakeNoisePattern(varargin)
%%
% Specify any parameters using variablename, and variablevalue:
% e.g. MakeNoisePattern('ImageSize',[300 300]);
%
% Available parameters and default values
% imagesize: default [300 300]
% Size of the noise pattern.
%
% checksize: default 4
% Size of the checks that make up the noise pattern. NOTE: There will be
% floor(imagesize/checksize) number of checks in the pattern.
%
% nFrames = 1;
% randfun = 'rand';
% video = 'off';
% noisesave = 'off';
% normal_mean = 0.5;
% normal_std = 1;
% default_norm = 1;
% clipping = [0 1]; % restrict the range of the random numbers. Clipping
% them to min and max values.
% fpower = 0; %power of 1/f^fpower. 0 = gaussian, -1 = pink noise, etc

%% default parameters
imagesize = [300 300];
checksize = 4;
nFrames = 1;
randfun = 'rand';
video = 'off';
noisesave = 'off';
normal_mean = 0.5;
normal_std = 1;
default_norm = 1;
clipping = [0 1];
fpower = 0;

%% check input parameters
if nargin > 0
    for index = 1:2:length(varargin)
        field = varargin{index};
        val = varargin{index+1};
        switch lower(field)
            case 'imagesize'
                if numel(val)~=2
                    error('MakeNoisePattern:InvalidParam','MakeNoisePattern: ImageSize should be a vecter of length 2');
                else
                    imagesize =  val;
                end
            case 'checksize'
                if numel(val)~=1 || ~isnumeric(val) || val < 1
                    error('MakeNoisePattern:InvalidParam','MakeNoisePattern: CheckSize should be a number larger than 0');
                else
                    checksize =  val;
                end
            case 'nframes'
                if numel(val)~=1 || ~isnumeric(val) || val < 1
                    error('MakeNoisePattern:InvalidParam','MakeNoisePattern: nFrames should be a number larger than 0');
                else
                    nFrames =  val;
                end
            case 'type'
                switch lower(val)
                    case 'randn'
                        randfun = 'randn';
                    case 'rand'
                        randfun = 'rand';
                    case 'coloured'
                        randfun = 'coloured';
                    otherwise
                        warning('MakeNoisePattern:InvalidParam',['MakeNoisePattern: ''type'' not recognised, will use ' randfun]);
                end
            case 'video'
                switch lower(val)
                    case 'on'
                        video = 'on';
                    case 'off'
                        video = 'off';
                    otherwise
                        warning('MakeNoisePattern:InvalidParam',['MakeNoisePattern: video setting not recognised. Will not record video']);
                        video = 'off';
                end
            case 'imsave'
                switch lower(val)
                    case 'on'
                        noisesave = 'on';
                    case 'off'
                        noisesave = 'off';
                    otherwise
                        warning('MakeNoisePattern:InvalidParam',['MakeNoisePattern: image save setting not recognised. Will not save images']);
                        noisesave = 'off';
                end
            case 'normmean'
                if  ~isnumeric(val)
                    error('MakeNoisePattern:InvalidParam','MakeNoisePattern: NormMean should be a numeric value');
                else
                    normal_mean =  val;
                    default_norm = 0;
                end
                
            case 'normstd'
                if  ~isnumeric(val) || val<0
                    error('MakeNoisePattern:InvalidParam','MakeNoisePattern: NormStd should be a positive numeric value');
                else
                    normal_std =  val;
                    default_norm = 0;
                end
            case 'clipping'
                if strcmp(val,'off')
                    clipping = [-inf inf];
                else
                    if  ~isnumeric(val) || any(val<0) || ~numel(val)==2
                        error('MakeNoisePattern:InvalidParam','MakeNoisePattern: Clipping values should be positive numeric values');
                    else
                        if val(1) > val(2)
                            clipping = fliplr(val);
                        else
                            clipping =  val;
                        end
                    end
                end
            case 'fpower'
                fpower = val;
            otherwise
                warning('MakeNoisePattern:InvalidParam',['MakeNoisePattern: invalid parameter: ',field]);
        end
    end
end

if strcmp(randfun,'coloured')
    randcoloured = randnd(fpower,[floor(imagesize(1)/checksize) floor(imagesize(2)/checksize) nFrames]);
end
for k = 1:nFrames
        disp(['calculating frame ' num2str(k)]);
        switch randfun
            case 'rand'
                randnums = rand(floor(imagesize(1)/checksize),floor(imagesize(2)/checksize));
            case 'randn'
                if default_norm
                    randnums = randn(floor(imagesize(1)/checksize),floor(imagesize(2)/checksize))/(1.96*2)+0.5;
                else
                    randnums = randn(floor(imagesize(1)/checksize),floor(imagesize(2)/checksize))*normal_std+normal_mean;
                end
            case 'coloured'
                if default_norm
                    randnums = randcoloured(:,:,k)/(1.96*2)+0.5;
                else
                    randnums = randcoloured(:,:,k)*normal_std+normal_mean;
                end
                
        end
    
    %randnums = rand(imagesize(1),imagesize(2));
    randnummul = [];
    randnummul2 = [];
    for i = 1:size(randnums,1)
        randnummul = [randnummul ; repmat(randnums(i,:),checksize,1)];
    end
    
    randnummul2 = [];
    for i = 1:size(randnums,2)
        randnummul2 = [randnummul2 , repmat(randnummul(:,i),1,checksize)];
    end
    
    noisepatterns(:,:,k) = min(max(randnummul2,clipping(1)),clipping(2));%randnummul2;
    if  (any(randnums(:)>clipping(2)) || any(randnums(:)<clipping(1)))
        outofbounds = ((randnums>clipping(2))|(randnums<clipping(1)));
        warning('MakeNoisePattern:Clipping',['MakeNoisePattern: In nFrame = ' num2str(k) ', ' num2str(sum(outofbounds(:))) ' (' num2str(mean(outofbounds(:))*100,3) '%%) noise values have been clipped to range between ' num2str(clipping(1)) ' and ' num2str(clipping(2)) '.']);
    end
end

if sum(size(randnummul2)-imagesize)
    warning(['Size of background is not equal to requested size. Size is ' num2str(size(randnummul2,1)) 'x' num2str(size(randnummul2,2)) ' instead of ' num2str(imagesize(1)) 'x' num2str(imagesize(2)) '.']);
end

%% save as video and/or images
if strcmpi(video,'on')
    v = VideoWriter('newfile.mp4','MPEG-4');
    open(v);
end
for i = 1:size(noisepatterns,3)
    A = noisepatterns(:,:,i)/clipping(2); % for images and videos the max value is 1, so needs to be normalised
    if strcmpi(video,'on')
        writeVideo(v,A);
    end
    if  strcmpi(noisesave,'on')
        imwrite(A, ['./frames/bgnoise' num2str(i) '.png']);
    end
end
if strcmpi(video,'on')
    close(v);
end

end