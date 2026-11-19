#!/bin/zsh
# usage: run.sh <script.js> [jobs.json]  -> runs the script in Affinity (jobs substituted for __JOBS__), prints console output
cd "${0:A:h}"
python3 -I - "$1" "$2" <<'PY'
import json, sys
s = open(sys.argv[1]).read()
if len(sys.argv) > 2 and sys.argv[2]:
    s = s.replace('__JOBS__', open(sys.argv[2]).read())
open('.last.json', 'w').write(json.dumps({'script': s}))
PY
python3 -I aff.py call read_sdk_documentation_topic '{"filename":"preamble"}' execute_script @.last.json | awk 'BEGIN{skip=1} /^\[read_sdk_documentation_topic\] System preamble/{skip=1; next} skip && /^\[/{skip=0} !skip{print}'
