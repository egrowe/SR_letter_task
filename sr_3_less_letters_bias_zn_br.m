addpath('..\Noise_Bias_LessLetters');
addpath('..\Noise_Bias_LessLetters\auxfiles');

%opengl('save', 'software'); %save settings for OpenGL instead of graphics hardware

%Open GL
AssertOpenGL;                   % Is the script running in OpenGL Psychtoolbox? Abort, if not.
InitializeMatlabOpenGL;         % Setup Psychtoolbox for OpenGL 3D rendering support and initialize the mogl OpenGL for Matlab wrapper:
window.OpenGL = 1;

try
    clear all;
    parameters_LessLetters;
    try
        load myGammaTableApprox
        p.gammaloaded = 1;

    catch TABLOAD
        warning(TABLOAD.message);
        s = 'x';
        while ~all(ismember(s,'yn'))
            s = input('Do you want to continue? (y/n)','s');
        end
        if ~strcmp('y',s)
            error('Experiment stopped. Lookup table could not be located');
        end
        p.gammaloaded = 0;
    end

    Screen('Preference', 'SkipSyncTests', 1);

    %% START EXPERIMENT
    ExperimentName = mfilename; %'sr_letter_001';
    parentPlusExpFolder = fullfile('StochasticResonance', ExperimentName);

    subject = ExpDialogBox;

    %Load the QUEST params
    load(['QUESTparams_all10Letters_' subject.name '.mat']);
    p.letterlum = 10^savedTh; %load QUEST defined letter luminance

    %Load which letters to be the majority (80%)
    loadThis = [(subject.name) '_' num2str(subject.age) '_Criterion_Block2.mat']
    load(loadThis,'outputCriterion');

    
    clear p.letters

    if outputCriterion < 0 %if negative (favouring vowels) then make vowels 80%
        p.letters =  {'O','U','E','O','U','E','O',...
            'U','E','O','U','E','C','B','H'};
    elseif outputCriterion > 0 %if positive (favouring consonants) then make consonants 80%
        p.letters =  {'C','H','B','C','H','B','C',...
            'H','B','C','H','B','O','E','U'};
    end

    ListenChar(2);
    %    HideCursor;
    if ~isempty(subject)
        dirname     = ['Data_' ExperimentName '/' subject.name];      % output data folder
        datadir     = ['./' dirname '/'];       % output data folder
        if ~exist(datadir,'dir'); mkdir('.',dirname); end
        filenamestart = [struct2str(subject,'_',[5:7]) '_'];

        expstart      = datestr(now,'ddmmmyyyy-HH.MM');
        s             = RandStream.create('mrg32k3a','Seed',subject.randseed); % set random seed generator
        RandStream.setGlobalStream(s);
        filenamebase = [filenamestart, ExperimentName];sca


        datatab = table;

        win= max(Screen('Screens')); % selects the maximum number of screen to project to in multiple screen condition
        %  winInfo=SetScreen('BGColor',127,'FontSize',14,'OpenGL',1);
        [winPtr, rect] = Screen('OpenWindow',win,127);%,[0 0 1000 700]);  %find window point and screen size
        %The above is from Kate's scripts

        % SetBlending(winPtr,'Transparent')
        Screen('BlendFunction', winPtr, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

        if p.gammaloaded
            oldGammaTable = Screen('ReadNormalizedGammaTable', winPtr);
            Screen('LoadNormalizedGammaTable', winPtr, myGammaTableApprox);
        end

        Screen('Flip', winPtr);% Flip to clear
        ifi         = Screen('GetFlipInterval', winPtr);% Query the frame duration
        topPriority = MaxPriority(winPtr);  % Query the maximum priority level
        %    oldPriority = Priority(topPriority);

        %Stimulus lasts for 1 second(?) that is, 60 frames (at 60 Hz)
        refreshRateHz = FrameRate(winPtr);
        trialDurFrames = p.stimdur*(round(refreshRateHz));
        vbl = Screen('Flip', winPtr);

        %Find the centre of the screen for display purposes
        Centre(1) = rect(3)/2; %check all these
        Centre(2)= rect(4)/2; %centre of screen

        if outputCriterion < 0
            DrawFormattedText(winPtr,'Welcome to BLOCK 3 \n \n Report which letter you see on the screen \n \n VOWELS are present 80% of the time, CONSONANTS 20% \n \n Press any key to begin...',...
                'center',Centre(2),[255 255 255]);
        elseif outputCriterion >= 0
            DrawFormattedText(winPtr,'Welcome to BLOCK 3 \n \n Report which letter you see on the screen \n \n CONSONANTS are present 80% of the time, VOWELS 20% \n \n Press any key to begin...',...
                'center',Centre(2),[255 255 255]);
        end

        vbl = Screen('Flip', winPtr, vbl +  0.5 * ifi);
        KbWait

        %% make trailstructure
        in.noiselevels = 0; %zero noise added in this block
        in.letternumbers = 1:length(p.letters);
        in.letterresize   = 1; %p.letterresize;
        in.checkresize      = 1; %p.checkresize;
        trialpars = MakeInputFromStruct(in,'Randomize',1,'Replications',4); % 4reps

        %Removing the structure files that aren't allowed
        all_letter_nums = in.letternumbers;
        all_letters = p.letters;
        all_letter_lum = p.letterlum;
        noise_fields_size = p.size_noisefields;
        noise_fields_num = p.n_noisefields;

        datam = zeros(size(trialpars,2), 25);

        Screen('TextFont', winPtr,'Sloan');
        vbl = Screen('Flip', winPtr);

        for trial = 1:length(trialpars)

            %Create the noise patterns for each trials
            %             randomnoisefields = MakeNoisePattern('imagesize',p.size_noisefields,'checksize',...
            %                 trialpars{trial}.checkresize,'nFrames', p.n_noisefields,'normmean',127,'normstd',...
            %                 trialpars{trial}.noiselevels,'type','randn','clipping',[0 255]);

            %Create noise pattern like Kate
            randomnoisefields = 127+trialpars{trial}.noiselevels*randn([fliplr(p.size_noisefields) p.n_noisefields]);


            for nTi = 1:size(randomnoisefields,3)
                noiseTexture(nTi) = Screen('MakeTexture',winPtr,randomnoisefields(:,:,nTi));
            end

            ntorder = randperm(size(randomnoisefields,3));

            for fr = 1:trialDurFrames

                Screen('BlendFunction', winPtr, 'GL_ONE', 'GL_ZERO');

                %Setup the screen with rectangle and frame
                Screen('FillRect',winPtr,[0 0 0],CenterRectOnPoint([0 0 noise_fields_size*trialpars{trial}.letterresize],Centre(1), Centre(2)));
                Screen('FrameRect',winPtr,[255 255 255],CenterRectOnPoint([0 0 noise_fields_size*trialpars{trial}.letterresize],Centre(1), Centre(2)));

                %Setup the text and font parameters
                Screen('TextFont', winPtr,'Sloan');
                fz = p.fontsizeTarget*trialpars{trial}.letterresize;
                Screen(winPtr,'TextSize',fz);
                DrawFormattedText(winPtr,all_letters{trialpars{trial}.letternumbers},'center','center',[all_letter_lum all_letter_lum all_letter_lum])
                Screen('BlendFunction', winPtr, 'GL_ONE', 'GL_ONE');

                %Only draw the noise fields if noise level = 0
                destinationrect = CenterRectOnPoint([0 0 noise_fields_size*trialpars{trial}.letterresize],Centre(1), Centre(2));
                Screen('DrawTexture',winPtr,noiseTexture(ntorder(fr)),[],destinationrect);
                vbl = Screen('Flip', winPtr, vbl +  0.5 * ifi);
            end

            Screen('BlendFunction', winPtr, 'GL_ONE', 'GL_ZERO');
            Screen('TextFont', winPtr,'Arial');
            Screen(winPtr,'TextSize',p.fontsizeTarget/2);
            DrawFormattedText(winPtr,['Trial ' num2str(trial) '/' num2str(length(trialpars)) '.\n Please type letter'],'center','center',[250 250 250])
            vbl = Screen('Flip', winPtr, vbl +  0.5 * ifi);

            ff = 0;
            while ff<100
                [keyIsDown,secs,keyCode] = KbCheck;
                ff = ff+1;
                [timepressed,keypressed] = KbPressWait
                DrawFormattedText(winPtr,['You selected ' KbName(keypressed) '.\n Space to confirm, other key to change.' ],'center','center',[250 250 250])
                vbl = Screen('Flip', winPtr, vbl +  0.5 * ifi);

                [a, keystroke] = KbStrokeWait;
                pr = find(keystroke);
                if strcmp(KbName(pr(1)),'space')
                    if strcmp(KbName(keypressed),'ESCAPE')
                        error('Participant Ended Program.');
                    end
                    break;
                end
            end

            %Blank screen after answering
            Screen('FillRect',winPtr,[127 127 127]);
            vbl = Screen('Flip', winPtr, vbl +  0.5 * ifi);

            answerCorrect = strcmpi(all_letters(trialpars{trial}.letternumbers),KbName(keypressed));

            data = [trialpars{trial}.noiselevels, trialpars{trial}.letternumbers, trialpars{trial}.letterresize,trialpars{trial}.checkresize,KbName(all_letters(trialpars{trial}.letternumbers)),keypressed, answerCorrect];
            datacell  = {trialpars{trial}.noiselevels, trialpars{trial}.letternumbers, trialpars{trial}.letterresize,trialpars{trial}.checkresize,all_letters(trialpars{trial}.letternumbers),KbName(keypressed), answerCorrect};
            datam(trial,1:size(data,2)) = data;
            datatab = [datatab; cell2table(datacell)];

            %             %Say if correct or incorrect
            %             if answerCorrect == 1
            %                 DrawFormattedText(winPtr,'Correct!','center',Centre(2),[0 255 0]);
            %                 vbl = Screen('Flip', winPtr, vbl +  0.5 * ifi);
            %                 WaitSecs(1)
            %             elseif answerCorrect ~= 1
            %                 DrawFormattedText(winPtr,'Wrong!','center',Centre(2),[255 0 0]);
            %                 vbl = Screen('Flip', winPtr, vbl +  0.5 * ifi);
            %                 WaitSecs(1)
            %             end
        end

        datatab.Properties.VariableNames = {'NoiseLevel','LetterNumber','LetterResize','CheckResize','PresentedLetter','ReportedLetter','AnswerCorrect'};

        %% Thank participant
        DrawFormattedText(winPtr,['You are done with BLOCK 3 \n \n Thank you. Press ANY KEY to exit'],'center',Centre(2));
        vbl = Screen('Flip', winPtr, vbl +  0.5 * ifi);
        KbStrokeWait;

        %% closing down & Record additional information
        experiment.time_start           = expstart;
        experiment.time_end             = datestr(now,'ddmmmyyyy-HH.MM');
        experiment.PTB                  = Screen('Version');
        experiment.Computer             = Screen('Computer');
        experiment.AdditionalWindowInfo = Screen('GetWindowInfo', winPtr);

        %% Save all data in one struct
        answermat = datam(:,1:size(data,2));
        subject.data = answermat;
        subject.datatab = datatab;
        subject.meandata = cellfun(@(x) mean(x(:,2)),combineconditions([subject.data(:,1) subject.data(:,3)==subject.data(:,4)],1));
        subject.StimThSD = [savedTh savedsd];
        subject.p = p;
        subject.win = win;
        subject.experiment = experiment;
        subject.trialpars = trialpars;
        subject.randomnoisefields = randomnoisefields;
        subject.noisetexture = noiseTexture;
        subject.ntorder = ntorder;

        %% save this file's content
        subject.program_code = fileread([ExperimentName '.m']);
        savefilename = fullfile(datadir,[filenamebase '.mat']);
        save(savefilename,'subject','in','p');

        %Show accuracy in command window
        outPutThresh = sum(datatab.AnswerCorrect)/length(trialpars)

        ShowCursor;
        Screen('LoadNormalizedGammaTable', winPtr, oldGammaTable);
        % -------> CHANGE  Priority(oldPriority);
        CleanUpExp;

    end
    clear screen;
    Screen('CloseAll')
    ListenChar;
catch ME
    ShowCursor;
    clear screen
    CleanUpExp;
    Screen('CloseAll')
    if exist('oldPriority','var')
        Priority(oldPriority);
    end
    subject.experiment.error = ME;
    rethrow(ME);
    Screen('LoadNormalizedGammaTable', winPtr, oldGammaTable);

end