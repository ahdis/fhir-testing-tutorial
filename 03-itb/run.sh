#!/bin/bash
# Run the test case from the command line: start a session, send the document as the system under test,
# and print the result.   ./run.sh ../examples/eps-broken.json
set -euo pipefail
# the file may be given relative to where you are; remember it before changing directory
abspath() { case "$1" in /*) echo "$1" ;; *) echo "$PWD/$1" ;; esac; }
[ $# -gt 0 ] && set -- "$(abspath "$1")" "${@:2}"
cd "$(dirname "$0")"
FILE=${1:-$(cd ../examples && pwd)/eps-minimal.json}
ITB=http://127.0.0.1:9000
s() { jq -r ".$1" .state.json; }
api() { curl -sS -f -X POST "$ITB/api/rest$1" -H "ITB_API_KEY: $(s organisation)" -H 'Content-Type: application/json' -d "$2"; }

SESSION=$(api /tests/start "{\"system\":\"$(s system)\",\"actor\":\"$(s actors.DocumentSource)\",\"testCase\":[\"$(jq -r '.testCases[]|select(test("eps-001"))' .state.json)\"],\"waitForCompletion\":false}" | jq -r '.createdSessions[0].session')
echo "session $SESSION"
sleep 2
echo "POST ${FILE##*/}  ->  the test bed answers:"
curl -sS -X POST "http://127.0.0.1:8081/itbsrv/api/http/$(s system)/Bundle" -H 'Content-Type: application/fhir+json' --data-binary @"$FILE" |
  jq -r '"  " + (.issue[0].diagnostics // "no answer")' 2>/dev/null || echo "  (no answer)"
for i in $(seq 1 30); do
  STATUS=$(api /tests/status "{\"session\":[\"$SESSION\"],\"withLogs\":false}")
  RESULT=$(echo "$STATUS" | jq -r '.sessions[0].result // "UNDEFINED"')
  [ "$RESULT" != UNDEFINED ] && break; sleep 1
done
# the findings of matchbox, as ITB recorded them in the report of the validation step
api /tests/status "{\"session\":[\"$SESSION\"],\"withLogs\":false,\"withReports\":true}" | jq -r '.sessions[0].report' > build/last-report.xml
python3 - <<'PY'
import re
x = open("build/last-report.xml").read()
found = re.findall(r"<(?:\w+:)?(error|warning)\b.*?<(?:\w+:)?description>(.*?)</", x, re.S)
print(f"matchbox report in ITB: {sum(k == 'error' for k, _ in found)} errors, {sum(k == 'warning' for k, _ in found)} warnings")
for kind, text in found:
    print(f"  {kind}: {text.strip()[:150]}")
PY
echo "ITB result: $RESULT"
[ "$RESULT" = UNDEFINED ] && api /tests/stop "{\"session\":[\"$SESSION\"]}" >/dev/null || true
