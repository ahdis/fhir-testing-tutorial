#!/bin/bash
# Mode B, the system under test is a server: the EU Health Data API tests by Jens Villadsen
# (https://github.com/euridice-org/eu-health-data-api-test) in their own local ITB, against a HAPI FHIR server.
#
#   ./setup.sh     clone the tests, start HAPI, load the 27 fixture resources, start ITB with the 67 test cases
#
# Needs Node.js 22 or newer and about 6 GB for Docker. Stop the stack of step 3 first:
#   (cd ../03-itb && docker compose --env-file .env stop)
set -euo pipefail
cd "$(dirname "$0")"
# Until euridice-org/eu-health-data-api-test#1 is merged, the fix for the validator download is on this branch.
REPO=${TESTS_REPO:-https://github.com/oliveregger/eu-health-data-api-test.git}
BRANCH=${TESTS_BRANCH:-fix/validator-pin}
SUT=http://host.docker.internal:8090/fhir

[ -d eu-health-data-api-test ] || git clone -q --depth 1 -b "$BRANCH" "$REPO" eu-health-data-api-test
docker compose up -d
echo "waiting for HAPI FHIR ..."
for i in $(seq 1 90); do curl -s -o /dev/null -f http://127.0.0.1:8090/fhir/metadata && break; sleep 4; done

cd eu-health-data-api-test
mkdir -p itb/build
if [ ! -f ../fixture-bindings.json ]; then
  FHIR_BASE_URL=http://127.0.0.1:8090/fhir node scripts/fixture-data.mjs load ../fixture-bindings.json
fi
# the features name a placeholder server; point them at HAPI
sed -i.bak "s|http://ehr.example.org/fhir|$SUT|" input/testing/gherkin/*.feature && rm -f input/testing/gherkin/*.bak
# ports next to the other steps of the tutorial
[ -f itb/.env ] || (umask 077; printf 'ITB_AUTOMATION_API_MASTER_KEY=%s\nITB_PORT=9001\nITB_CALLBACK_PORT=8082\n' "$(openssl rand -hex 32)" > itb/.env)
./itb/start.sh

echo
echo "ITB with the EU Health Data API tests: http://127.0.0.1:9001"
echo "  user      eu-api-test@itb"
echo "  password  $(jq -r .password itb/.users.json)"
echo "system under test: $SUT (from your laptop: http://127.0.0.1:8090/fhir)"
echo "inputs the test cases ask for:"
echo "  patient id   $(jq -r '.resourceIds["patient-target"]' ../fixture-bindings.json)"
echo "  document id  $(jq -r '.resourceIds["document-target"]' ../fixture-bindings.json)"
echo "  binary id    $(jq -r '.resourceIds["binary-target"]' ../fixture-bindings.json)"
echo "  access token Bearer anything   (HAPI does not check tokens; see what the authorization cases say about that)"
