addpath('..\Noise_Bias_LessLetters');
addpath('..\Noise_Bias_LessLetters\auxfiles');
%%
opengl('save', 'software'); %save settings for OpenGL instead of graphics hardware

%Open GL
AssertOpenGL;                   % Is the script running in OpenGL Psychtoolbox? Abort, if not.
InitializeMatlabOpenGL;         % Setup Psychtoolbox for OpenGL 3D rendering support and initialize the mogl OpenGL for Matlab wrapper:
window.OpenGL = 1;

%%
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

    %The sync tests can be run if opengl is loaded above
    Screen('Preference', 'SkipSyncTests', 1);

    %% START EXPERIMENT
    ExperimentName = mfilename; %'sr_letter_001';
    parentPlusExpFolder = fullfile('StochasticResonance', ExperimentName);

    subject = ExpDialogBox;
    ListenChar(2); %%% UNCOMMENT THIS IN REAL EXPERIMENT
  %  HideCursor; %%% UNCOMMENT THIS IN REAL EXPERIMENT
    if ~isempty(subject)
        dirname     = ['Data_' ExperimentName '\' subject.name];      % output data folder
        datadir     = ['.\' dirname '\'];       % output data folder
        if ~exist(datadir,'dir'); mkdir('.',dirname); end
        filenamestart = [struct2str(subject,'_',[5:7]) '_'];
        
        expstart      = datestr(now,'ddmmmyyyy-HH.MM');
        s             = RandStream.create('mrg32k3a','Seed',subject.randseed); % set random seed generator
        RandStream.setGlobalStream(s);
        filenamebase = [filenamestart, ExperimentName];
        datatab = table;

        win= max(Screen('Screens')); % selects the maximum number of screen to project to in multiple screen condition
     %   winInfo=SetScreen('BGColor',127,'FontSize',14,'OpenGL',1);
       [winPtr, rect] = Screen('OpenWindow',win,127);%,[0 0 1000 700]);  %find window point and screen size
        %The above is from Kate's scripts
  
       % SetBlending(winPtr,'Transparent')
        Screen('BlendFunction', winPtr, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

        if p.gammaloaded
            oldGammaTable = Screen('ReadNormalizedGammaTable', winPtr);
            Screen('LoadNormalizedGammaTable', winPtr, myGammaTableApprox);
        end

       % Screen('BlendFunction', winPtr, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
        Screen('TextFont', winPtr,'Arial');
        Screen('Flip', winPtr);% Flip to clear
        ifi         = Screen('GetFlipInterval', winPtr);% Query the frame duration
        topPriority = MaxPriority(winPtr);  % Query the maximum priority level
      %  oldPriority = Priority(topPriority);
        refreshRateHz = FrameRate(winPtr);

        %Stimulus lasts for 1 second(?) that is, 60 frames (at 60 Hz)
        trialDurFrames = p.stimdur*(round(refreshRateHz));
        vbl = Screen('Flip', winPtr);

        %Find the centre of the screen for display purposes
        Centre(1) = rect(3)/2; %check all these
        Centre(2)= rect(4)/2;

        %% Welcome participant to the experiment (instructions)
        DrawFormattedText(winPtr,'Welcome to BLOCK 1 of the experiment \n \n Report which letter you see on screen \n \n Press ANY KEY to begin...',...
            'center',Centre(2),[255 255 255]);
        vbl = Screen('Flip', winPtr, vbl +  0.5 * ifi);
        KbWait
        Screen('Flip', winPtr);% Flip to clear

        %% QUEST PROFILE #1 (suggested profile)
        QuestLetters = {'C','H','B','O','E','U'}; %Itzcovich (altered)
        tGuess      = 0; % estimated threshold
        tGuessSd    = 2; % estimated standard deviation of the estimated threshold guess
        
        pThreshold  = 0.6; %percentage correct threshold
        beta        = 3.5; % beta controls the steepness of the psychometric function. Typically 3.5.
        delta       = 0.1; %fraction of blind guesses by participant (this was 0.1 and 0.01)
        gamma       = 0.5; % gamma is the fraction of trials that will generate response 1 when	intensity==-inf.
        grain       = 0.05;  % grain is the quantization (step size) of the internal table. E.g. 0.01.
        range       = 1;  % range is the intensity difference between the largest and smallest
                                % 	intensity that the internal table can store. E.g. 5. This interval will
                                % 	be centered on the initial guess tGuess, i.e. tGuess+(-range/2:grain:range/2).
        trialsDesired = 40;
        q=QuestCreate(tGuess,tGuessSd,pThreshold,beta,delta,gamma,grain,range);
        q.normalizePdf=1; % This adds a few ms per call to QuestUpdate, but otherwise the pdf will underflow after about 1000 trials.
        

        % RUN THE EXPERIMENT
%% 
        vbl = Screen('Flip', winPtr);

        for trial=1:trialsDesired
            Screen('TextFont', winPtr,'Sloan');
            
            % Get recommended level.
            tTest = QuestQuantile(q);	% Recommended by Pelli (1987)
            contr = 10^tTest; % ORIGINAL
 %           contr = 127+10^tTest; % ORIGINAL

            correctletter = randi(length(QuestLetters));

            tTest_vals(:,trial) = tTest; %lets save all the output vals
            contr_vals(:,trial) = contr; %lets save all the contrast vals
            
%             %Create the noise patterns for each trials
%             randomnoisefields = MakeNoisePattern('imagesize',p.size_noisefields,'checksize',...
%                 1,'nFrames', p.n_noisefields,'normmean',127,'normstd',...
%                 0,'type','randn','clipping',[0 255]);

 
            %Create noise pattern like Kate
            randomnoisefields = 127+0*randn([fliplr(p.size_noisefields) p.n_noisefields]);


            for nTi = 1:size(randomnoisefields,3)
                noiseTexture(nTi) = Screen('MakeTexture',winPtr,randomnoisefields(:,:,nTi));
            end

            ntorder = randperm(size(randomnoisefields,3));

            for fr = 1:trialDurFrames

                    Screen('BlendFunction', winPtr, 'GL_ONE', 'GL_ZERO');

                    %Setup the screen with rectangle and frame
                    Screen('FillRect',winPtr,[0 0 0],CenterRectOnPoint([0 0 100 100],Centre(1), Centre(2)));
                    Screen('FrameRect',winPtr,[255 255 255],CenterRectOnPoint([0 0 100 100],Centre(1), Centre(2)));             

                    %Setup the text and font parameters
                    Screen('TextFont', winPtr,'Sloan');
                    fontSizeTarget = p.fontsizeTarget;
                    Screen(winPtr,'TextSize',fontSizeTarget);
                    DrawFormattedText(winPtr,QuestLetters{correctletter},'center','center',[contr contr contr])
                    Screen('BlendFunction', winPtr, 'GL_ONE', 'GL_ONE');

                    %Only draw the noise fields if noise level = 0
                    destinationrect = CenterRectOnPoint([0 0 100 100],Centre(1), Centre(2));
                    Screen('DrawTexture',winPtr,noiseTexture(ntorder(fr)),[],destinationrect);
                    vbl = Screen('Flip', winPtr, vbl +  0.5 * ifi);

            end

            Screen('TextFont', winPtr,'Arial');
            Screen(winPtr,'TextSize',p.fontsizeTarget/2);
            DrawFormattedText(winPtr,['Which letter did you see?'],'center','center',[255 255 255])
            Screen('BlendFunction', winPtr, 'GL_ONE', 'GL_ZERO');
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

            AnswerCorrect = strcmpi(QuestLetters{correctletter},KbName(keypressed));
            
            % Update the pdf
            q=QuestUpdate(q,tTest,AnswerCorrect); % Add the new datum (actual test intensity and observer response) to the database.
        end

        %% Thank participant
        DrawFormattedText(winPtr,['You are done with BLOCK 1 \n \n Thank you. Press ANY KEY to exit'],'center',Centre(2));
        vbl = Screen('Flip', winPtr, vbl +  0.5 * ifi);
        KbStrokeWait;

       %% closing down & Record additional information
        experiment.time_start           = expstart;
        experiment.time_end             = datestr(now,'ddmmmyyyy-HH.MM');
        experiment.PTB                  = Screen('Version');
        experiment.Computer             = Screen('Computer');
        experiment.AdditionalWindowInfo = Screen('GetWindowInfo', winPtr);
        
        %% Save all data in one struct
        subject.data = q;
        subject.p = p;
        subject.win = win;
        subject.experiment = experiment;
        
        %% save this file's content
        subject.program_code = fileread([ExperimentName '.m']);
        
        
        savefilename = fullfile(datadir,[filenamebase '.mat']);
        save(savefilename,'subject');
        
        %% save threshold to transport to experiment
        savedTh = QuestMean(q);		% Recommended by Pelli (1989) and King-Smith et al. (1994).
        savedsd = QuestSd(q);%q.intensity(40);
        savedPThreshold = q.xThreshold; 

        save(['QUESTparams_all10Letters_' subject.name],'savedTh','savedsd', ...
            'savedPThreshold','tTest_vals','contr_vals');
        
        save(['QUEST_allData_' subject.name '_' expstart '.mat'])
        
        % save all dependency files, so that experiment can be repeated if
        % needed
        %         myd=MyDependencyTest([ExperimentName '.m']);
        %         CreateDependencyFolder([[ExperimentName '.m'] myd],[datadir 'ExpFold']);
        %         currfol = pwd;
        %         cd(datadir);
        %         zip('ExpFold', 'ExpFold');
        %         rmdir('ExpFold','s');
        %         cd(currfol);
        
% -----> CHANGE WINDOWS Priority(oldPriority);
        Screen('LoadNormalizedGammaTable', winPtr, oldGammaTable);
        ShowCursor;
        CleanUpExp;
        

end