# Recorded with vhs (https://github.com/charmbracelet/vhs), from the repository root:  vhs backup/tapes/05-eu-health-data-api.tape
Output backup/05-eu-health-data-api.mp4
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
Type "# Mode B, server under test: the EU Health Data API tests against a HAPI FHIR server"
Enter
Sleep 1s
Type "04-eu-health-data-api/setup.sh 2>&1 | tail -n 9 | sed -E 's/(password +).*/\1(printed here)/'"
Enter
Wait+Screen@600s /access token/
Sleep 5s
Type "04-eu-health-data-api/run.sh"
Enter
Wait+Screen@180s /dap-002/
Sleep 8s
Screenshot backup/05-eu-health-data-api.png
Sleep 2s
