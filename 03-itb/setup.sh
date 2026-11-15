#!/bin/bash
# Start ITB next to matchbox and load the test suite of this directory.
#   ./setup.sh                                            matchbox of step 2 (http://matchbox:8080/matchboxv3/fhir)
#   MATCHBOX_URL=https://host/matchboxv3/fhir ./setup.sh  another matchbox, as seen from the ITB container
# Safe to run again: it reuses what exists and redeploys the suite.
set -euo pipefail
cd "$(dirname "$0")"
MATCHBOX_URL=${MATCHBOX_URL:-http://matchbox:8080/matchboxv3/fhir}
ITB=http://127.0.0.1:9000

[ -f .env ] || (umask 077; echo "ITB_AUTOMATION_API_MASTER_KEY=$(openssl rand -hex 32)" > .env)
. ./.env
[ -f .state.json ] || (umask 077; echo '{}' > .state.json)
docker compose --env-file .env up -d

api() { # method path key [json]
  curl -sS -f -X "$1" "$ITB/api/rest$2" -H "ITB_API_KEY: $3" -H 'Content-Type: application/json' ${4:+-d "$4"}
}
ensure() { # name path key json  -> creates once, remembers the returned API key
  local key; key=$(jq -r --arg n "$1" '.[$n] // empty' .state.json)
  if [ -z "$key" ]; then
    key=$(api PUT "$2" "$3" "$4" | jq -r .apiKey)
    jq --arg n "$1" --arg k "$key" '.[$n]=$k' .state.json > .state.tmp && mv .state.tmp .state.json
    echo "created $1" >&2
  fi
  echo "$key"
}

echo "waiting for ITB ..."
for i in $(seq 1 120); do curl -s -o /dev/null -f "$ITB/api/rest/swagger" && break; sleep 3; done

DOMAIN=$(ensure domain /domain "$ITB_AUTOMATION_API_MASTER_KEY" '{"shortName":"FHIR testing tutorial","fullName":"FHIR testing tutorial"}')
COMMUNITY=$(ensure community /community "$ITB_AUTOMATION_API_MASTER_KEY" "{\"shortName\":\"Tutorial\",\"fullName\":\"FHIR testing tutorial\",\"domain\":\"$DOMAIN\"}")
SPEC=$(ensure specification /specification "$COMMUNITY" "{\"shortName\":\"EPS 1.0.0-ballot\",\"fullName\":\"European Patient Summary 1.0.0-ballot\",\"domain\":\"$DOMAIN\"}")
ORG=$(ensure organisation /organisation "$COMMUNITY" '{"shortName":"My organisation","fullName":"My organisation"}')
SYSTEM=$(ensure system /system "$COMMUNITY" "{\"shortName\":\"My system\",\"fullName\":\"My system under test\",\"organisation\":\"$ORG\"}")

rm -rf build && mkdir build
for f in suite/*.xml; do sed "s|@MATCHBOX_URL@|$MATCHBOX_URL|g" "$f" > "build/$(basename "$f")"; done
(cd build && zip -q suite.zip *.xml)
DEPLOY=$(api POST /testsuite/deploy "$COMMUNITY" "$(jq -n --arg s "$SPEC" --arg z "$(base64 < build/suite.zip | tr -d '\n')" \
  '{specification:$s, testSuite:$z, ignoreWarnings:false, replaceTestHistory:false, updateSpecification:true, showIdentifiers:true}')")
echo "$DEPLOY" > build/deploy.json
[ "$(jq -r .completed build/deploy.json)" = true ] || { echo "deploy failed:"; jq . build/deploy.json; exit 1; }

ACTOR=$(api GET "/specification/$SPEC/actors" "$COMMUNITY" | jq -r '.[] | select(.identifier=="DocumentSource") | .apiKey')
api GET "/conformance/$SYSTEM" "$ORG" | jq -e --arg a "$ACTOR" 'any(.[]; .actor==$a)' >/dev/null ||
  api PUT "/conformance/$SYSTEM/$ACTOR" "$ORG" >/dev/null
jq --arg a "$ACTOR" --arg t "$(jq -r '.identifiers.testCases[0]' build/deploy.json)" '.actor=$a | .testCase=$t' .state.json > .state.tmp && mv .state.tmp .state.json

echo
echo "ITB is ready:      $ITB   (administrator admin@itb; its one-time password is in: docker compose logs gitb-ui)"
echo "validator:         $MATCHBOX_URL"
echo "send documents to: http://127.0.0.1:8081/itbsrv/api/http/$SYSTEM/Bundle   (while a test session is waiting)"
