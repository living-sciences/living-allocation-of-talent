#!/usr/bin/env bash
# setup_case_lean.sh SRC DEST [CSV]  -- model-pipeline case (no .dta; only the CSV is needed)
set -e
WS=/workspace/eval/followup/001-living-update/workspace
SRC=$(cd "$1" && pwd); DEST="$2"; CSV=${3:-}
case "$DEST" in /*) : ;; *) DEST="$WS/$DEST" ;; esac
rm -rf "$DEST"; mkdir -p "$DEST"
( cd "$SRC" && find . -maxdepth 1 -type f ! -name '*.dta' -exec cp -t "$DEST" {} + )
cp -r "$SRC/ChadMatlab" "$DEST/"; cp -r "$SRC/shims" "$DEST/"
cd "$DEST"
rm -f *.mat *.log stage_timings.csv 2>/dev/null || true
[ -f ChadMatlab/lookup.m ] && mv ChadMatlab/lookup.m ChadMatlab/lookup.m.bak || true
[ -f shims/keyboard.m ] || printf 'function keyboard(varargin)\nend\n' > shims/keyboard.m
cp "$WS"/octave_stage/split_case.sh .; cp "$WS"/octave_stage/HowMuchPoorer_chunk.m .
cp "$WS"/run_stage_patched.sh run_stage.sh
chmod +x run_stage.sh split_case.sh
if [ -n "$CSV" ]; then cp "$WS/$CSV" chad_output_file_2019_01_24.csv; fi
echo "lean case ready: $DEST ($(ls *.m|wc -l) m-files, csv=$(stat -c%s chad_output_file_2019_01_24.csv))"
