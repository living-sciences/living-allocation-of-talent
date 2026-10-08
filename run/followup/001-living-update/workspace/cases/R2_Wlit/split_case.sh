#!/usr/bin/env bash
# split_case.sh CASE [stage]  -- the ORIGINAL (6-period) pipeline, stage-split. Used by gate 1.
# Run ONE stage per foreground tool call:  ./split_case.sh Benchmark S1 ; ... S2 ; S3 ; H1 ... H5
# Stage-specific parameter overrides (theta=4 etc.) go in the S1 statement, as in replication_log.json.
CASE=$1; ST=$2; R="$(dirname "$0")/run_stage.sh"
case $ST in
  S1) $R $CASE "SetParameters; HighQualityFigures=0; ReadCohortData; EstimateTauZ_main;" S1 ;;
  S2) $R $CASE "CleanandShowTauAZ;" S2 ;;
  S3) $R $CASE "SolveEqmBasic;" S3 ;;
  H[1-5]) $R $CASE "global HMPChunk; HMPChunk=${ST#H}; HowMuchPoorer_chunk;" $ST ;;
  *) echo "stage must be S1 S2 S3 H1..H5"; exit 2 ;;
esac
