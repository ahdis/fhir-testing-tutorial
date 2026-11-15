#!/bin/bash
# Run the test case from the command line: start a session, send the document as the system under test,
# and print the result.   ./run.sh ../examples/eps-broken.json
set -euo pipefail
cd "$(dirname "$0")"
FILE=${1:-../examples/eps-minimal.json}
ITB=http://127.0.0.1:9000
s() { jq -r ".$1" .state.json; }
api() { curl -sS -f -X POST "$ITB/api/rest$1" -H "ITB_API_KEY: $(s organisation)" -H 'Content-Type: application/json' -d "$2"; }

SESSION=$(api /tests/start "{\"system\":\"$(s system)\",\"actor\":\"$(s actors.DocumentSource)\",\"testCase\":[\"$(jq -r '.testCases[]|select(test("eps-001"))' .state.json)\"],\"waitForCompletion\":false}" | jq -r '.createdSessions[0].session')
echo "session $SESSION"
sleep 2
echo "POST $FILE  ->  matchbox says:"
curl -sS -X POST "http://127.0.0.1:8081/itbsrv/api/http/$(s system)/Bundle" -H 'Content-Type: application/fhir+json' --data-binary @"$FILE" |
  jq -r '[.issue[].severity] | group_by(.) | map("\(.[0]): \(length)") | "  " + join(", ")' 2>/dev/null || echo "  (HTTP 500: the checks failed; the OperationOutcome is in the validation step of the session)"
for i in $(seq 1 30); do
  STATUS=$(api /tests/status "{\"session\":[\"$SESSION\"],\"withLogs\":false}")
  RESULT=$(echo "$STATUS" | jq -r '.sessions[0].result // "UNDEFINED"')
  [ "$RESULT" != UNDEFINED ] && break; sleep 1
done
echo "ITB result: $RESULT"
[ "$RESULT" = UNDEFINED ] && api /tests/stop "{\"session\":[\"$SESSION\"]}" >/dev/null || true
