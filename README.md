# Testing FHIR implementations: hands-on material

Material for the tutorial *FHIR Validation ecosystem and testing approaches* (HL7 Europe Working Group Meeting,
Tuesday 17 November 2026, 09:00–10:30). One document, the European Patient Summary (EPS), goes through every step.

Status: work in progress. Steps 1 to 5 are tested as described in each section.

## Prerequisites

- Java 21
- Docker with Compose, and 6 GB of memory for the Docker VM
- `curl`, `jq` and Python 3; Node.js 22 or newer for step 5

## The document

| File | What |
|---|---|
| `examples/eps-minimal.json` | a valid EPS with no known problems, medications or allergies |
| `examples/eps-broken.json` | the same document with five mistakes |
| `examples/make-examples.py` | builds both from the example in the EPS package, and lists the five mistakes |

Both are validated against `hl7.fhir.eu.eps#1.0.0-ballot`, the latest published version of the EPS
(<http://hl7.eu/fhir/eps/1.0.0-ballot>).

## 1. The HL7 FHIR validator on the command line

```bash
01-validator-cli/validate.sh examples/eps-minimal.json   # Success: 0 errors
01-validator-cli/validate.sh examples/eps-broken.json    # *FAILURE*: 12 errors, 1 warnings
```

The first run takes a few minutes: it downloads the validator and the FHIR packages. Later runs take about 40 seconds,
almost all of it loading the packages.

## 2. matchbox

```bash
(cd 02-matchbox && docker compose up -d)                 # http://127.0.0.1:8080/matchboxv3
02-matchbox/validate.sh examples/eps-minimal.json        # information: 3
02-matchbox/validate.sh examples/eps-broken.json         # error: 12, information: 5, warning: 2
```

matchbox loads the EPS package on its first start (about two minutes). After that a validation takes less than a second
(the first one a few seconds). Open <http://127.0.0.1:8080/matchboxv3> for the web GUI.

## 3. ITB with matchbox as its validation service

The EU Interoperability Test Bed plays the receiver of a patient summary. The system under test sends the document to
the test bed, and the test bed has matchbox validate it. matchbox is plugged in as ITB's validation service
(GITB REST API, in matchbox since 5.0.0-rc4), so the findings of matchbox become the report of the test step.

```bash
03-itb/setup.sh                                 # starts ITB next to matchbox and loads the test suite
03-itb/run.sh examples/eps-minimal.json         # matchbox report in ITB: 0 errors   -> ITB result: SUCCESS
03-itb/run.sh examples/eps-broken.json          # matchbox report in ITB: 12 errors  -> ITB result: FAILURE
```

`run.sh` starts a test session through ITB's REST API, acts as the system under test with one `curl`, and prints the
findings from ITB's report. To watch it in the browser, open <http://127.0.0.1:9000> and log in as `admin@itb`; the
one-time password is printed by
`(cd 03-itb && docker compose --env-file .env logs gitb-ui | grep -A2 'one-time password')`.

- The test case is `03-itb/suite/eps-001-valid-patient-summary.xml` (GITB TDL): a `receive` step that waits for the
  document, and a `verify` step whose handler is matchbox:
  `<verify handler="http://matchbox:8080/matchboxv3/itb/fhir" handlerApiType="REST">` with the inputs
  `contentToValidate` and `profiles`.
- Another matchbox (5.0.0-rc4 or later): `MATCHBOX_URL=https://<host>/matchboxv3/fhir 03-itb/setup.sh`. The address
  must be reachable from the ITB container.
- The first start pulls about 2 GB of images and takes a few minutes.

## 4. ITB as a simulator: your system is the client

The same ITB plays the Document Access Provider of the EU Health Data API. The system under test is a document
consumer: it finds a patient summary (Find Document References, ITI-67) and retrieves it (Retrieve Document, ITI-68).
The test bed waits for each request, checks it, and answers.

```bash
03-itb/consumer.sh              # a correct consumer            -> ITB result: SUCCESS
03-itb/consumer.sh --no-token   # forgets the Authorization     -> ITB result: FAILURE
03-itb/consumer.sh --manual     # starts a session and prints the base URL: you are the client
```

With `--manual`, send the two requests yourself (replace `$BASE` with the printed base URL):

```bash
curl -H 'Authorization: Bearer tutorial-token' \
  "$BASE/DocumentReference?patient=eps-pat-1&category=Patient-Summaries"
curl -H 'Authorization: Bearer tutorial-token' "$BASE/Binary/eps-minimal"
```

- The test case is `03-itb/suite/eps-002-find-and-retrieve.xml`. It checks the method, the resource, the `patient`
  parameter, a `category` or `type` parameter, and that a bearer token is sent. It does not check the token itself:
  the token request of SMART Backend Services is left out to keep the exercise short.
- ITB waits five minutes per step. Run one session at a time: a request goes to the session that is waiting.
- The document ITB hands out is `examples/eps-minimal.json`, so the retrieved Bundle can go straight back into step 1 or 2.

## 5. The EU Health Data API tests: your system is the server

The [EU Health Data API tests](https://euridice-org.github.io/eu-health-data-api-test/en/) by Jens Villadsen are
67 ITB test cases for the six actors of the EU Health Data API. They are a demonstration, not an approved test
specification. Here the system under test is a server: a plain HAPI FHIR server with the tests' 27 fixture resources.

The test cases use a validator for three things: to load the implementation guide, to validate resources against
its profiles, and to evaluate the FHIRPath expressions of nearly every check. As published they use the
HL7 validator. Here matchbox does it (three GITB REST services, complete since 5.0.0-rc5).

```bash
(cd 03-itb && docker compose --env-file .env stop)   # free memory and ports: this step brings its own ITB
04-eu-health-data-api/setup.sh                       # clones the tests, starts HAPI, loads the fixtures, starts ITB and matchbox
04-eu-health-data-api/run.sh                         # SUCCESS dap-001, FAILURE dap-002
```

`setup.sh` prints the address (<http://127.0.0.1:9001>), the login, and the ids the test cases ask for.
In the browser, choose the system *Implementation under test*, the actor *DocumentAccessProvider*, and run a case.
The list shows ten cases per page.

- `dap-001` passes: HAPI declares `DocumentReference` and `Binary`. `dap-002` fails: HAPI does not declare
  SMART on FHIR security. That is the point of the exercise: a general FHIR server is not yet a Document Access
  Provider of the EU Health Data API.
- `dap-012` shows all three services of matchbox: it loads the implementation guide, reads the patient from HAPI,
  validates it against the EU Core Patient profile and counts the errors with FHIRPath. It asks for an access token
  (`Bearer anything`) and the patient id that `setup.sh` printed.
- HAPI accepts any token, and the authorization cases report that.
- `04-eu-health-data-api/setup.sh --hl7-validator` runs the tests as published, with the HL7 validator.
- Needs Node.js 22 or newer, and about 6 GB of memory for Docker. The first start takes several minutes.

What `setup.sh` changes in the tests so that matchbox can take the validator's place:

- the validator's address in the feature files (`http://matchbox:8080/matchboxv3`);
- where the test steps read the validation report. They read it by position, and matchbox returns the report's
  context as an object with an `item` list, with one more item before the OperationOutcome
  (`/report/context/4/value` becomes `/report/context/item/5/value`).

Until [eu-health-data-api-test#1](https://github.com/euridice-org/eu-health-data-api-test/pull/1) is merged,
`setup.sh` clones the branch with the fix for the download of the HL7 validator (only `--hl7-validator` needs it).

Tested on 2026-11-16:

- With matchbox v5.0.0-rc5: `setup.sh`, then `dap-001`, `dap-002` and `dap-014` from the command line, and `dap-012`
  in the browser.
- With matchbox built from the change that added the two services
  ([matchbox#682](https://github.com/ahdis/matchbox/pull/682), part of rc5): the 48 cases of the three server actors
  (`dap`, `rap`, `grp`) give the same result with matchbox and with the HL7 validator, step by step: 37 pass,
  11 fail. For that comparison the steps that ask for a token or an id were removed and the values given through
  ITB's REST API.
- Not run: the 19 cases of the client actors, and the cases that need a person.

## Demo: Gazelle Maestro runs matchbox and ITB in one test

Steps 1 to 5 use one engine at a time. [Maestro](https://gitlab.inria.fr/gazelle/public/core/maestro), the test
engine of Gazelle, can chain engines: one test run, one report. This is a demonstration by the presenter, not a
hands-on step, because Maestro has to be built from source (see below). It runs on top of step 5.

The test has two steps:

1. **`VALIDATION`**: Maestro sends the patient summary to matchbox, through the Gazelle Validation Service API
   (`/matchboxv3/gazelle`), with the EPS Bundle profile.
2. **`ITB`**: Maestro starts the test case `dap-001` of step 5 in ITB through ITB's REST API, waits for it, and
   takes over ITB's verdict and report.

```json
{ "id": "validate", "type": "VALIDATION", "properties": [
    { "name": "validationService", "type": "STRING", "value": "Matchbox" },
    { "name": "validationProfile", "type": "STRING", "value": "http://hl7.eu/fhir/eps/StructureDefinition/bundle-eu-eps|1.0.0-ballot" },
    { "name": "contentToValidate", "type": "BYTE_ARRAY", "fileName": "eps-minimal.json", "value": "…base64…" } ] },
{ "id": "itb", "type": "ITB", "timeout": 120000, "properties": [
    { "name": "testCase", "type": "STRING", "value": "dap-001-the-capabilitystatement-declares-documentreference-and-binary" },
    { "name": "actorID", "type": "STRING", "value": "…API key of the actor…" },
    { "name": "systemID", "type": "STRING", "value": "…API key of the system…" },
    { "name": "executionMode", "type": "STRING", "value": "SYNC" } ] }
```

```
Maestro test run: PASSED
  PASSED    matchbox: valid patient summary
  PASSED    ITB: dap-001 against the server
              ITB SUCCESS  Step 1: GET /metadata
              ITB SUCCESS  Step 2: Response status is 200
              ITB SUCCESS  Step 3: Evaluate FHIRPath
              …
```

- With `examples/eps-broken.json` the run is `FAILED` after the first step, and Maestro does not start ITB:
  a step only runs if the one before it passed.
- With `dap-002` in the second step the document is valid and the run is `FAILED` at the ITB step, for the reason
  of step 5: HAPI does not declare SMART on FHIR security.

What it needs beyond step 5:

- Maestro 1.3.1 built from source, with one change: it reads ITB's verdict by name
  ([ahdis/maestro#1](https://github.com/ahdis/maestro/issues/1)). Without the change an ITB step reports
  `UNDEFINED` with a live ITB.
- Gazelle's service registry, which tells Maestro where matchbox (`Validation Service API`) and ITB (the name
  `ITB`, interface `ITB API`) are, and a token endpoint for Maestro's lookups.
- The organisation's API key of ITB as Maestro's `itb.api.key`, and the EPS package in the matchbox of step 5
  (loaded through `/itb/igManager/process`).

Tested on 2026-11-16 with Maestro 1.3.1 (with the change), ITB 1.30.2, matchbox v5.0.0-rc5 and HAPI FHIR 8.6.0:
the three runs give `PASSED`, `FAILED` at step 1 and `FAILED` at step 2.

## Backup

Recordings and screenshots of every step are in [backup/](backup/README.md), in case a step does not run on your laptop.

## Licence

Apache License 2.0, see [LICENSE](LICENSE). The example documents are derived from an example of the HL7 Europe
European Patient Summary implementation guide.

Tested with validator 7.0.6, matchbox v5.0.0-rc5 (a release candidate) and ITB 1.30.2 on 2026-11-16.
