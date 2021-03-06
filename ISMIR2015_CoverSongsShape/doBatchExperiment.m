%A wrapper around doSingleExperiment for SLURM
%Input Parameter: ExperimentIdx

[a, b, c, d, e] = ind2sub([length(dims), length(BeatsPerBlocks), length(Kappas), length(beatIdxs1), length(beatIdxs2)], ExperimentIdx);

dim = dims(a);
BeatsPerBlock = BeatsPerBlocks(b);
Kappa = Kappas(c);
beatIdx1 = beatIdxs1(d);
beatIdx2 = beatIdxs2(e);

DOPATCHMATCH = 0;
if Kappa == -1
    DOPATCHMATCH = 1;
end

%Make directory to hold the results if it doesn't exist
if DOPATCHMATCH
    dirName = sprintf('Results/%i_%i_%i_%i_%g', dim, BeatsPerBlock, NIters, K, Alpha);
else
    dirName = sprintf('Results/%i_%i_%g', dim, BeatsPerBlock, Kappa);
end
if ~exist(dirName);
    mkdir(dirName);
end

outfilename = sprintf('%s/%i_%i.mat', dirName, beatIdx1, beatIdx2);
if ~exist(outfilename)
    doSingleExperiment;
end
