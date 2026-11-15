#!/usr/bin/env python3
"""Build the two example documents of the tutorial.

  eps-minimal.json  a European Patient Summary with no known problems, medications or allergies.
                    Derived from the example Bundle-EPSExampleBundle01NoProblemsMedicationAllergies
                    of hl7.fhir.eu.eps#1.0.0-ballot (titles in English, a synthetic patient).
  eps-broken.json   the same document with five mistakes, each of a different kind.

Usage: make-examples.py <path to the example Bundle from the EPS package>
"""
import copy, json, pathlib, sys

HERE = pathlib.Path(__file__).parent
XHTML = '<div xmlns="http://www.w3.org/1999/xhtml">%s</div>'

src = json.load(open(sys.argv[1]))
doc = copy.deepcopy(src)
doc["id"] = "eps-minimal"
comp, patient, device, org = (e["resource"] for e in doc["entry"])

comp["id"] = "eps-minimal-composition"
comp["title"] = "European Patient Summary"
comp["status"] = "final"
comp["subject"]["display"] = "Anna Example"
comp["author"][0]["display"] = "Tutorial EPS Generator"
comp["custodian"]["display"] = "Example Hospital"
comp["text"] = {"status": "generated", "div": XHTML % "<p>European Patient Summary of Anna Example, 8 February 2024</p>"}
titles = {"10160-0": "Medication Summary", "48765-2": "Allergies and Intolerances", "11450-4": "Problem List",
          "47519-4": "History of Procedures", "46264-8": "Medical Devices"}
for s in comp["section"]:
    s["title"] = titles[s["code"]["coding"][0]["code"]]
    s["text"] = {"status": "generated", "div": XHTML % "<p>No information known.</p>"}

patient.clear()
patient.update({
    "resourceType": "Patient", "id": "eps-minimal-patient",
    "meta": {"profile": ["http://hl7.eu/fhir/eps/StructureDefinition/patient-eu-eps"]},
    "text": {"status": "generated", "div": XHTML % "<p>Anna Example, female, born 24 December 1961</p>"},
    "name": [{"family": "Example", "given": ["Anna"]}],
    "gender": "female", "birthDate": "1961-12-24",
    "address": [{"use": "home", "city": "Sevilla", "country": "ES"}],
})
device["id"] = "eps-minimal-author"
device["deviceName"][0]["name"] = "Tutorial EPS Generator"
device["text"] = {"status": "generated", "div": XHTML % "<p>Tutorial EPS Generator</p>"}
org["id"] = "eps-minimal-custodian"
org["name"] = "Example Hospital"
org["text"] = {"status": "generated", "div": XHTML % "<p>Example Hospital</p>"}

def write(name, bundle):
    (HERE / name).write_text(json.dumps(bundle, indent=2, ensure_ascii=False) + "\n")

write("eps-minimal.json", doc)

broken = copy.deepcopy(doc)
broken["id"] = "eps-broken"
comp, patient, device, org = (e["resource"] for e in broken["entry"])
# 1. structure: an element FHIR does not know
org["website"] = "https://hospital.example.org"
# 2. invariant: a document Bundle must have an identifier (bdl-9)
del broken["identifier"]
# 3. terminology: a code that is not in the required value set (DeviceNameType)
device["deviceName"][0]["type"] = "friendly-name"
# 4. slicing: the mandatory allergies section is missing
comp["section"] = [s for s in comp["section"] if s["code"]["coding"][0]["code"] != "48765-2"]
# 5. reference: the custodian is not in the document
comp["custodian"]["reference"] = "urn:uuid:00000000-0000-4000-8000-000000000000"
write("eps-broken.json", broken)
