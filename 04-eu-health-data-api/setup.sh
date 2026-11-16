#!/bin/bash
# Mode B, the system under test is a server: the EU Health Data API tests by Jens Villadsen
# (https://github.com/euridice-org/eu-health-data-api-test) in their own local ITB, against a HAPI FHIR server.
#
#   ./setup.sh                   clone the tests, start HAPI, load the 27 fixture resources, start ITB with the
#                                67 test cases; matchbox validates and evaluates the FHIRPath expressions
#   ./setup.sh --hl7-validator   the tests as published: the HL7 validator does that
#
# Needs Node.js 22 or newer and about 6 GB for Docker. Stop the stack of step 3 first:
#   (cd ../03-itb && docker compose --env-file .env stop)
set -euo pipefail
cd "$(dirname "$0")"
VALIDATOR=matchbox; [ "${1:-}" = --hl7-validator ] && VALIDATOR=hl7
# Until euridice-org/eu-health-data-api-test#1 is merged, the fix for the validator download is on this branch.
REPO=${TESTS_REPO:-https://github.com/oliveregger/eu-health-data-api-test.git}
BRANCH=${TESTS_BRANCH:-fix/validator-pin}
SUT=http://host.docker.internal:8090/fhir
HL7_URL=http://fhir-validator:8080
MATCHBOX_URL=http://matchbox:8080/matchboxv3
IG='hl7.fhir.eu.health-data-api#1.0.0-ballot'

[ -d eu-health-data-api-test ] || git clone -q --depth 1 -b "$BRANCH" "$REPO" eu-health-data-api-test
docker compose up -d
echo "waiting for HAPI FHIR ..."
for i in $(seq 1 90); do curl -s -o /dev/null -f http://127.0.0.1:8090/fhir/metadata && break; sleep 4; done

cd eu-health-data-api-test
mkdir -p itb/build
# HAPI keeps its data in memory: load the fixtures again when the reference patient is gone
PATIENT=$(jq -r '.resourceIds["patient-target"] // empty' ../fixture-bindings.json 2>/dev/null || true)
if [ -z "$PATIENT" ] || ! curl -s -o /dev/null -f "http://127.0.0.1:8090/fhir/Patient/$PATIENT"; then
  rm -f ../fixture-bindings.json
  FHIR_BASE_URL=http://127.0.0.1:8090/fhir node scripts/fixture-data.mjs load ../fixture-bindings.json
fi
# the features name a placeholder server; point them at HAPI
sed -i.bak "s|http://ehr.example.org/fhir|$SUT|" input/testing/gherkin/*.feature
# ports next to the other steps of the tutorial
[ -f itb/.env ] || (umask 077; printf 'ITB_AUTOMATION_API_MASTER_KEY=%s\nITB_PORT=9001\nITB_CALLBACK_PORT=8082\n' "$(openssl rand -hex 32)" > itb/.env)

# What follows is the tests' own ./itb/start.sh, with the choice of the validator in between.
npm ci --prefix itb --ignore-scripts --no-audit --no-fund
if [ "$VALIDATOR" = matchbox ]; then
  export COMPOSE_FILE=docker-compose.yml:../docker-compose.matchbox.yml
  sed -i.bak "s|$HL7_URL|$MATCHBOX_URL|" input/testing/gherkin/*.feature
  # The test steps read the validation report by position. matchbox answers with the report's context as an
  # object with an item list (the form of the GITB types) and has one more item before the OperationOutcome.
  for f in itb/node_modules/@opentestbed/dialect-fhir-validator/steps.yml \
           itb/node_modules/@opentestbed/dialect-fhir-validator/steps-v1.yml \
           itb/node_modules/@opentestbed/otb-gherkin/lang/en-1.yml; do
    sed -i.bak -e 's|"/report/context/4/value"|"/report/context/item/5/value"|' \
               -e 's|"/report/context/\([013]\)/value"|"/report/context/item/\1/value"|' "$f"
  done
else
  export COMPOSE_FILE=docker-compose.yml
  sed -i.bak "s|$MATCHBOX_URL|$HL7_URL|" input/testing/gherkin/*.feature
  docker compose --env-file itb/.env rm -sf matchbox >/dev/null 2>&1 || true
fi
rm -f input/testing/gherkin/*.bak
npm run --prefix itb compile
docker compose --env-file itb/.env up -d --build --wait --wait-timeout 360
if [ "$VALIDATOR" = matchbox ]; then
  docker compose --env-file itb/.env stop fhir-validator >/dev/null 2>&1 || true
  echo "matchbox loads $IG (the first time from packages.fhir.org, about a minute) ..."
  for i in $(seq 1 60); do curl -s -o /dev/null -f http://127.0.0.1:8083/matchboxv3/actuator/health && break; sleep 5; done
  curl -sS -f -X POST http://127.0.0.1:8083/matchboxv3/itb/igManager/process -H 'Content-Type: application/json' \
    -d "{\"operation\":\"loadIG\",\"input\":[{\"name\":\"ig\",\"value\":\"$IG\",\"embeddingMethod\":\"STRING\"}]}" \
    | jq -e -r '.output[0] | "  \(.name): \(.value)"' || { echo "matchbox could not load $IG" >&2; exit 1; }
fi
node --env-file=itb/.env itb/setup.mjs
node --env-file=itb/.env itb/users.mjs

echo
echo "ITB with the EU Health Data API tests: http://127.0.0.1:9001"
echo "  user      eu-api-test@itb"
echo "  password  $(jq -r .password itb/.users.json)"
if [ "$VALIDATOR" = matchbox ]; then echo "validator: matchbox, http://127.0.0.1:8083/matchboxv3"; else echo "validator: HL7 validator"; fi
echo "system under test: $SUT (from your laptop: http://127.0.0.1:8090/fhir)"
echo "inputs the test cases ask for:"
echo "  patient id   $(jq -r '.resourceIds["patient-target"]' ../fixture-bindings.json)"
echo "  document id  $(jq -r '.resourceIds["document-target"]' ../fixture-bindings.json)"
echo "  binary id    $(jq -r '.resourceIds["binary-target"]' ../fixture-bindings.json)"
echo "  access token Bearer anything   (HAPI does not check tokens; see what the authorization cases say about that)"
