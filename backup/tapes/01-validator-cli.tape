# Recorded with vhs (https://github.com/charmbracelet/vhs), from the repository root:  vhs backup/tapes/01-validator-cli.tape
Output backup/01-validator-cli.mp4
Set Shell bash
Set FontSize 17
Set Width 1600
Set Height 900
Set Padding 24
Set Theme "GitHub Dark"
Set TypingSpeed 35ms
Hide
Type "export PS1='$ ' && clear"
Enter
Show
Type "# Mode A: the HL7 FHIR validator on the command line"
Enter
Sleep 1s
Type "01-validator-cli/validate.sh examples/eps-minimal.json 2>&1 | tail -n 6"
Enter
Wait+Screen@120s /Max Memory/
Sleep 4s
Type "clear"
Enter
Type "# the same document with five mistakes"
Enter
Type "01-validator-cli/validate.sh examples/eps-broken.json 2>&1 | grep -E 'FAILURE|Error|Warning' | cut -c1-130"
Enter
Wait+Screen@120s /isn't reachable/
Sleep 8s
Screenshot backup/01-validator-cli.png
Sleep 2s
