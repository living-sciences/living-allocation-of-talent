addpath([pwd '/shims']);
save_default_options('-mat7-binary');
more off; warning('off','all');
try, graphics_toolkit('gnuplot'); catch, end
set(0,'defaultfigurevisible','off');
tic
clear all; global CaseName;
CaseName='Benchmark';
SetParameters;
HighQualityFigures=0;
ReadCohortData
EstimateTauZ_main
CleanandShowTauAZ
SolveEqmBasic
HowMuchPoorer
toc
