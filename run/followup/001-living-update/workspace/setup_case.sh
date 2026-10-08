#!/usr/bin/env bash
# setup_case.sh SRC_CODEBASE DEST_CASE_DIR
# Builds a runnable case dir matching the replication env: copy codebase, clear stale outputs,
# rename ChadMatlab/lookup.m aside, ensure keyboard.m shim, install stage tools + gnuplot-patched runner.
set -e
SRC=$1; DEST=$2
WS=/workspace/eval/followup/001-living-update/workspace
rm -rf "$DEST"; mkdir -p "$DEST"
cp -r "$SRC"/* "$DEST"/
cd "$DEST"
rm -f *.mat *.log *.eps *.pdf *.png stage_timings.csv 2>/dev/null || true
[ -f ChadMatlab/lookup.m ] && mv ChadMatlab/lookup.m ChadMatlab/lookup.m.bak || true
[ -f shims/keyboard.m ] || printf 'function keyboard(varargin)\nend\n' > shims/keyboard.m
cp "$WS"/octave_stage/split_case.sh .
cp "$WS"/octave_stage/HowMuchPoorer_chunk.m .
cp "$WS"/run_stage_patched.sh run_stage.sh
chmod +x run_stage.sh split_case.sh
echo "case ready: $DEST"
