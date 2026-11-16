#!/bin/bash
# Validate a document against the EPS Bundle profile with matchbox's $validate.
#   ./validate.sh ../examples/eps-broken.json
# the file may be given relative to where you are; remember it before changing directory
abspath() { case "$1" in /*) echo "$1" ;; *) echo "$PWD/$1" ;; esac; }
[ $# -gt 0 ] && set -- "$(abspath "$1")" "${@:2}"
cd "$(dirname "$0")"
FILE=${1:-$(cd ../examples && pwd)/eps-minimal.json}
MATCHBOX=${MATCHBOX:-http://127.0.0.1:8080/matchboxv3/fhir}
PROFILE=${PROFILE:-http://hl7.eu/fhir/eps/StructureDefinition/bundle-eu-eps}
[ -f "$FILE" ] || { echo "no such file: $FILE" >&2; exit 1; }
# fail loudly if matchbox is not (yet) up: it needs about two minutes to load the packages on the first start
RESULT=$(curl -sS --fail-with-body -X POST "$MATCHBOX/\$validate?profile=$PROFILE" \
  -H 'Content-Type: application/fhir+json' -H 'Accept: application/fhir+json' \
  --data-binary @"$FILE") || { echo "matchbox at $MATCHBOX did not answer; is it up? (docker compose logs -f)" >&2; echo "$RESULT" >&2; exit 1; }
echo "$RESULT" | jq -r '.issue | (group_by(.severity) | map("\(.[0].severity): \(length)") | join(", ")),
         (.[] | select(.severity=="error" or .severity=="warning") | "  \(.severity) @ \(.expression[0] // "-"): \(.diagnostics // .details.text)")'
