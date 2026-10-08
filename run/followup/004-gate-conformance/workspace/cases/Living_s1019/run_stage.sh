#!/usr/bin/env bash
# run_stage.sh CASE "<octave statements>" [label]
# Runs ONE pipeline stage in a fresh octave-cli inside the current case directory (a copy of the
# ported codebase with shims/ and ChadMatlab/). Hard backstop: 540 s (rc 124 = killed -> split the stage).
# Call it from a foreground Bash tool call that passes timeout: 600000. Never background it.
CASE=$1; BODY=$2; LABEL=${3:-$(echo "$BODY" | tr -cd 'A-Za-z0-9' | rev | cut -c1-28 | rev)}
PRE="addpath([pwd '/shims']); save_default_options('-mat7-binary'); more off; warning('off','all'); try,graphics_toolkit('gnuplot');catch,end; set(0,'defaultfigurevisible','off'); addpath([pwd '/ChadMatlab']); global CaseName; CaseName='$CASE';"
s=$(date +%s)
timeout -s INT -k 15 540 octave-cli -q --eval "$PRE $BODY" > "stage_console_${CASE}_${LABEL}.log" 2>&1; rc=$?
e=$(date +%s)
[ -f stage_timings.csv ] || echo "case,stage,rc,seconds" > stage_timings.csv
echo "$CASE,$LABEL,$rc,$((e-s))" >> stage_timings.csv
echo "$CASE | $LABEL | rc=$rc | $((e-s)) s"
exit $rc
