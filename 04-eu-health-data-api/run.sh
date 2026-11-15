#!/bin/bash
# Run test cases of the Document Access Provider that need no operator input, from the command line.
#   ./run.sh              dap-001 and dap-002 (the CapabilityStatement checks)
#   ./run.sh dap-014      any case id prefix
# Cases that ask for a token or an id are run in the browser: http://127.0.0.1:9001
set -euo pipefail
cd "$(dirname "$0")/eu-health-data-api-test/itb"
ITB=http://127.0.0.1:9001
s() { jq -r ".$1" .state.json; }
api() { curl -sS -f -X "$1" "$ITB/api/rest$2" -H "ITB_API_KEY: $3" -H 'Content-Type: application/json' ${4:+-d "$4"}; }
ACTOR=$(api GET "/specification/$(s specification)/actors" "$(s community)" | jq -r '.[] | select(.identifier=="DocumentAccessProvider") | .apiKey')
for PREFIX in "${@:-dap-001 dap-002}"; do for P in $PREFIX; do
  CASE=$(jq -r --arg p "$P" '.suites["eu-api-document-access-provider.feature"].testCases[] | select(startswith($p))' .state.json)
  SESSION=$(api POST /tests/start "$(s organisation)" "{\"system\":\"$(s system)\",\"actor\":\"$ACTOR\",\"testCase\":[\"$CASE\"],\"waitForCompletion\":false}" | jq -r '.createdSessions[0].session')
  for i in $(seq 1 60); do
    RESULT=$(api POST /tests/status "$(s organisation)" "{\"session\":[\"$SESSION\"],\"withLogs\":false}" | jq -r '.sessions[0].result // "UNDEFINED"')
    [ "$RESULT" != UNDEFINED ] && break; sleep 1
  done
  printf '%-8s %s\n' "$RESULT" "$CASE"
done; done
