#!/bin/bash
# Mode B, the system under test is a client: ITB plays the Document Access Provider (ITI-67, ITI-68).
#   ./consumer.sh            start a session and act as a correct document consumer
#   ./consumer.sh --manual   start a session and print the base URL: you are the client (see README)
#   ./consumer.sh --no-token act as a consumer that forgets the Authorization header
set -euo pipefail
cd "$(dirname "$0")"
MODE=${1:-}
ITB=http://127.0.0.1:9000
s() { jq -r ".$1" .state.json; }
api() { curl -sS -f -X POST "$ITB/api/rest$1" -H "ITB_API_KEY: $(s organisation)" -H 'Content-Type: application/json' -d "$2"; }
BASE="http://127.0.0.1:8081/itbsrv/api/http/$(s system)"

SESSION=$(api /tests/start "{\"system\":\"$(s system)\",\"actor\":\"$(s actors.DocumentConsumer)\",\"testCase\":[\"eps-002-find-and-retrieve\"],\"waitForCompletion\":false}" | jq -r '.createdSessions[0].session')
echo "session  $SESSION"
echo "base URL $BASE"
[ "$MODE" = --manual ] && { echo "ITB waits five minutes per step. Send the two requests, then look at the session in the ITB UI."
  echo "Run one session at a time: requests go to the oldest session that is waiting."; exit 0; }
AUTH=(-H 'Authorization: Bearer tutorial-token'); [ "$MODE" = --no-token ] && AUTH=()
sleep 2

echo; echo "ITI-67  GET DocumentReference?patient=eps-pat-1&category=Patient-Summaries"
URL=$(curl -sS ${AUTH[@]+"${AUTH[@]}"} -H 'Accept: application/fhir+json' \
  "$BASE/DocumentReference?patient=eps-pat-1&category=http://hl7.eu/fhir/health-data-api/CodeSystem/eehrxf-document-priority-category-cs%7CPatient-Summaries" |
  jq -r '.entry[0].resource.content[0].attachment.url // empty' 2>/dev/null || true)
echo "        -> ${URL:-no answer (the checks of the step failed)}"
if [ -n "$URL" ]; then
  sleep 2
  echo "ITI-68  GET $URL"
  curl -sS ${AUTH[@]+"${AUTH[@]}"} -H 'Accept: application/fhir+json' "$BASE/$URL" |
    jq -r '"        -> \(.resourceType) \(.type), \(.entry | length) entries, \(.entry[0].resource.title)"' 2>/dev/null || echo "        -> no document"
fi
for i in $(seq 1 30); do
  RESULT=$(api /tests/status "{\"session\":[\"$SESSION\"],\"withLogs\":false}" | jq -r '.sessions[0].result // "UNDEFINED"')
  [ "$RESULT" != UNDEFINED ] && break; sleep 1
done
echo; echo "ITB result: $RESULT"
if [ "$RESULT" = UNDEFINED ]; then
  # a session that still waits would receive the requests meant for the next one
  api /tests/stop "{\"session\":[\"$SESSION\"]}" >/dev/null
  echo "(ITB was still waiting for a request it could accept; the session was stopped)"
fi
