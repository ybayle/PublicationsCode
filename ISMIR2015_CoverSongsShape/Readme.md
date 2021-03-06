#Overview
This repository contains all of the code used to generate the results presented in the paper.



<table border = "1"><tr><td>
Christopher J Tralie and Paul Bendich. Cover song identification with timbral shape. In <i>16th International
Society for Music Information Retrieval (ISMIR) Conference,</i> 2015.
</td></tr></table>

<h3><a href = "https://www.youtube.com/watch?v=GrWIrR1dLak">Click here</a> to see a narrated Youtube video which explains this paper at a high level</h3>

Most of the code is written in Matlab to take advantage of fast matrix multiplication routines and existing libraries for music feature extraction, but a few files (sequence alignment) are written in C++, and the GUI is written in Python.  There is also a GUI written in Javascript/WebGL

#Getting Started and Running Experiments
Below is a list of instructions to replicate the results reported in the paper


1. Download the <a href = "http://labrosa.ee.columbia.edu/projects/coversongs/covers80/">"covers 80"</a> benchmark dataset (<a href = "http://labrosa.ee.columbia.edu/projects/coversongs/covers80/covers80.tgz">covers80.tgz</a>) and extract to the root of this directory.  When this is done, you should have a folder "coversongs" at the root of this directory which contains two folders: "covers32k" and "src"
2. Download the <a href = "http://labrosa.ee.columbia.edu/matlab/rastamat/rastamat.tgz">rastamat</a> library for computing MFCC features and extract to the <b>BeatSyncFeatures</b> directory
2. Run the Matlab file "getAllTempoEmbeddings.m" in <b>BeatSyncFeatures/</b> to precompute all MFCC features.  This may take a while the first time.  If it fails because your version of Matlab cannot read .mp3 files, you can convert them to .ogg format with the file "convertMp3sToOggs.py" found in coversongs/
3. Choose a set of parameters and loop through all combinations of these parameters in a series of batch tests.  Each parameter is described more in the paper.  Run the following Matlab code at the root of this directory to perform experiments on the covers80 dataset

~~~~~ matlab
%Parameters to try
dims = 50; %Resized dimension of self-similarity matrices
BeatsPerBlocks = 12; %Number of beats per block
Kappas = 0.1; %Fraction of mutual nearest neighbors to take when converting a cross-similarity matrix to a binary cross-similarity matrix
beatIdxs1 = 1:3;%Tempo levels to try for the first song (1: 60bpm bias, 2: 120bmp bias, 3:180bmp bias)
beatIdxs2 = 1:3;%Tempo levels to try for the second song

doAllExperiments;
~~~~~

To loop through additional parameters, you simply make the corresponding parameter variables into lists.  For instance, to try out a self-similarity dimension of 25, 50, and 100 along with the other parameter choices, change dims to
~~~~~ matlab
dims = [25, 50, 100];
~~~~~

The script will try all combinations of parameters that are specified.  
<b>NOTE:</b> If you have access to a cluster computer with the SLURM system, you can parallelize the different parameter choices by modifying and running the script "doBatchExperiments.q."  Otherwise, it will take about an hour for one experiment run, fixing Kappa/BeatsPerBlock/dim and varying through all beat biases

<b>NOTE ALSO:</b> If you want to view the cross-similarity and self-similarity matrices for two songs of your own choosing, you can bypass the Covers80 dataset completely, as long as you have downloaded and extracted the <a href = "http://labrosa.ee.columbia.edu/matlab/rastamat/rastamat.tgz">rastamat</a> library to the <b>BeatSyncFeatures</b> directory.  See the documentation in the "CoverSongsGUI" folder for more information

4. To see the results after this script has run, change into the "Results" directory and run the "processResults.m" script.  This script will report the number of cover songs correct, along with the mean and median rank of each cover song, and it will output this information in an HTML table format

#Code Folders Information:
Below is a description of the code in each directory in this repository

* BeatSyncFeatures: Code used to precompute beat-synchronous MFCC and Chroma embeddings for all of the songs in the covers80 database given

* BlurredLinesExperiment: Some code for running the experiment that compares Robin Thicke's "Blurred Lines" to Marvin Gaye's "Got To Give It Up"

* CoverSongsGUI: Code for interactively viewing cross-similarity matrices and the self-similarity matrices that were used to generate each pixel on the cross-similarity matrix, as well as PCA on blocks down to 3D synchronized with the music in OpenGL

* CoverSongsGUIWeb: A subset of the Python GUI which is easily deployable in the browser (it is best to start here if you want to visually explore features)

* EMD: Code for doing L1 Earth mover's distance between self-similarity matrices (results not reported in paper)

* PatchMatch: Code for computing cross-similarity matrices and for performing Patch Match (Patch Match results not reported in paper)

* Results: Directory used for storing processing the results of a batch tests

* SequenceAlignment: C++ implementations of Smith Waterman and constrained Smith Waterman, which have MEX interfaces so they can be called from Matlab

* SimilarityMatrices: Code for computing self-similarity matrices for the blocks 

#Running Individual Pairs outside Covers80
If you want to compare two songs outside of the covers80 framework, use the file "compareTwoSongs.m."  For instance,

~~~~~ matlab
filename1 = 'song1.mp3';
filename2 = 'song2.mp3';
dim = 50; %Resized dimension of self-similarity matrices
BeatsPerBlock = 12; %Number of beats per block
Kappa = 0.1; %Fraction of mutual nearest neighbors to take when converting a cross-similarity matrix to a binary cross-similarity matrix


[Score, CSM] = compareTwoSongs(filename1, filename2, dim, BeatsPerBlock, Kappa);
~~~~~
