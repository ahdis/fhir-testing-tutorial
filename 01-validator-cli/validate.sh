#!/bin/bash
# Validate a document against the European Patient Summary with the HL7 FHIR validator.
#   ./validate.sh ../examples/eps-broken.json
# The first run downloads validator_cli.jar (about 200 MB) and the FHIR packages (into ~/.fhir).
# the file may be given relative to where you are; remember it before changing directory
abspath() { case "$1" in /*) echo "$1" ;; *) echo "$PWD/$1" ;; esac; }
[ $# -gt 0 ] && set -- "$(abspath "$1")" "${@:2}"
cd "$(dirname "$0")"
FILE=${1:-$(cd ../examples && pwd)/eps-minimal.json}
VERSION=${VALIDATOR_VERSION:-7.0.6}
JAR=validator_cli-$VERSION.jar
[ -f "$JAR" ] || curl -L -o "$JAR" \
  "https://github.com/hapifhir/org.hl7.fhir.core/releases/download/$VERSION/validator_cli.jar"
java -jar "$JAR" "$FILE" -version 4.0.1 -ig 'hl7.fhir.eu.eps#1.0.0-ballot' "${@:2}"
