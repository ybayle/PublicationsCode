%Perform an experiment on covers80
%for a particular choice of beatIdx1 and beatIdx2 for the tempos in the
%first group and the tempos in the second group, as well as the parameters
%NIters, K, and Alpha for PatchMatch and dim, BeatsPerBlock
addpath('BeatSyncFeatures');
addpath('SequenceAlignment');
addpath('SimilarityMatrices');
addpath('PatchMatch');

%Initialize parameters for matching
list1 = 'coversongs/covers32k/list1.list';
list2 = 'coversongs/covers32k/list2.list';
files1 = textread(list1, '%s\n');
files2 = textread(list2, '%s\n');
N = length(files1);


%Run all cross-similarity experiments between songs and covers
fprintf(1, '\n\n\n');
disp('======================================================');
fprintf(1, 'RUNNING EXPERIMENTS\n');
fprintf(1, 'dim = %i, BeatsPerBlock = %i\n', dim, BeatsPerBlock);
if DOPATCHMATCH
    fprintf(1, 'PatchMatch K = %i, NIters = %i, Alpha = %g\n', K, NIters, Alpha);
else
    fprintf(1, 'Nearest Neighbor Kappa = %g\n', Kappa);
end
fprintf(1, 'beatIdx1 = %i, beatIdx2 = %i\n', beatIdx1, beatIdx2);
disp('======================================================');
fprintf(1, '\n\n\n');


%Scores for ordinary Smith Waterman
ScoresChroma = zeros(N, N); %Chroma by itself
ScoresMFCC = zeros(N, N); %MFCC by itself
Scores = zeros(N, N); %Combined
MaxTransp = zeros(N, N); %Transposition that led to the highest score
MaxTranspCombined = zeros(N, N);


%Scores for Smith Waterman with constraints
CScoresChroma = zeros(N, N); %Chroma by itself
CScoresMFCC = zeros(N, N); %MFCC by itself
CScores = zeros(N, N); %Combined
CMaxTransp = zeros(N, N); %Transposition that led to the highest score
CMaxTranspCombined = zeros(N, N);

%Keep track of the sizes of all of the cross-similarity matrices for
%convenience
CrossSizes = cell(N, N);


%Split the precomputation of distance matrices into 4 groups to save memory
%(at the cost of some computation time since the cover distance matrices are
%recomputed 4 times)
for batch = 0:3
    fprintf(1, 'Precomputing self-similarity matrices for original songs batch %i of 4...\n', batch+1);
    DsOrig = cell(1, N/4);
    ChromasOrig = cell(1, N/4);
    for ii = 1:N/4
        tic;
        song = load(['BeatSyncFeatures', filesep, files1{ii+batch*N/4}, '.mat']);
        fprintf(1, 'Getting self-similarity matrices for %s\n', files1{ii+batch*N/4});
        DsOrig{ii} = single(getBeatSyncDistanceMatrices(song.allMFCC{beatIdx1}, ...
            song.allSampleDelaysMFCC{beatIdx1}, song.allbts{beatIdx1}, dim, BeatsPerBlock));
        ChromasOrig{ii} = song.allBeatSyncChroma{beatIdx1};
        toc;
    end

    %Now loop through the cover songs
    for jj = 1:N
        fprintf(1, 'Comparing cover song %i of %i\n', jj, N);
        tic
        song = load(['BeatSyncFeatures', filesep, files2{jj}, '.mat']);
        fprintf(1, 'Getting self-similarity matrices for %s\n', files2{jj});
        thisDs = single(getBeatSyncDistanceMatrices(song.allMFCC{beatIdx2}, ...
            song.allSampleDelaysMFCC{beatIdx2}, song.allbts{beatIdx2}, dim, BeatsPerBlock));
        ChromaY = song.allBeatSyncChroma{beatIdx2};

        thisMsMFCC = cell(N, 1);
        for ii = 1:N/4
            %Step 1: Compute MFCC Self-Similarity features
            %Precompute L2 cross-similarity matrix and find Kappa percent mutual nearest
            %neighbors
            CSM = bsxfun(@plus, dot(DsOrig{ii}, DsOrig{ii}, 2), dot(thisDs, thisDs, 2)') - 2*(DsOrig{ii}*thisDs');
            CrossSizes{ii+batch*N/4, jj} = size(CSM);
            if DOPATCHMATCH
                MMFCC = patchMatch1DIMPMatlab( CSM, NIters, K, Alpha );
            else
                MMFCC = groundTruthKNN( CSM, round(size(CSM, 2)*Kappa) );
                MMFCC = MMFCC.*groundTruthKNN( CSM', round(size(CSM', 2)*Kappa) )';
            end
            ScoresMFCC(ii+batch*N/4, jj) = swalignimp(double(full(MMFCC)));
            CScoresMFCC(ii+batch*N/4, jj) = swalignimpconstrained(double(full(MMFCC)));

            %Step 2: Compute transposed chroma delay features
            ChromaX = ChromasOrig{ii};
            ChromaX = getBeatSyncChromaDelay(ChromaX, BeatsPerBlock, 0);
            allScoresChroma = zeros(1, size(ChromaY, 2));
            allScoresCombined = zeros(1, size(ChromaY, 2));
            CallScoresChroma = zeros(1, size(ChromaY, 2));
            CallScoresCombined = zeros(1, size(ChromaY, 2));
			%Optimal transposition index
            for oti = 0:size(ChromaY, 2) - 1 
                %Transpose chroma features
                thisY = getBeatSyncChromaDelay(ChromaY, BeatsPerBlock, 0);
                %Compute the OTI of each delay window
                Comp = zeros(size(ChromaX, 1), size(thisY, 1), size(ChromaX, 2));
                for cc = 0:size(ChromaY, 2)-1
                    thisY = getBeatSyncChromaDelay(ChromaY, BeatsPerBlock, oti + cc);
                    Comp(:, :, cc+1) = ChromaX*thisY'; %Cosine distance
                end
                [~, Comp] = max(Comp, [], 3);
                CSMChroma = (Comp == 1);%Only keep elements with no shift

                allScoresChroma(oti+1) = swalignimp(double(CSMChroma));
                CallScoresChroma(oti+1) = swalignimpconstrained(double(CSMChroma));
                dims = [size(CSMChroma); size(MMFCC)];
                dims = min(dims, [], 1);
                M = double(CSMChroma(1:dims(1), 1:dims(2)) + MMFCC(1:dims(1), 1:dims(2)) );
                M = double(M > 0);
                M = full(M);
                allScoresCombined(oti+1) = swalignimp(M);
                CallScoresCombined(oti+1) = swalignimpconstrained(M);
            end
            %Find best scores over transpositions
            [ChromaScore, idx] = max(allScoresChroma);
            ScoresChroma(ii+batch*N/4, jj) = ChromaScore;
            MaxTransp(ii+batch*N/4, jj) = idx;
            [ChromaScore, idx] = max(CallScoresChroma);
            CScoresChroma(ii+batch*N/4, jj) = ChromaScore;
            CMaxTransp(ii+batch*N/4, jj) = idx;            
            
            [Score, idx] = max(allScoresCombined);
            Scores(ii+batch*N/4, jj) = Score;
            MaxTranspCombined(ii+batch*N/4, jj) = idx;
            [Score, idx] = max(CallScoresCombined);
            CScores(ii+batch*N/4, jj) = Score;
            CMaxTranspCombined(ii+batch*N/4, jj) = idx;
            fprintf(1, '.');
        end
    end
end

save(outfilename, ...
    'CrossSizes', 'ScoresChroma', 'ScoresMFCC', 'Scores', 'MaxTransp', 'MaxTranspCombined', ...
    'CScoresChroma', 'CScoresMFCC', 'CScores', 'CMaxTransp', 'CMaxTranspCombined');
