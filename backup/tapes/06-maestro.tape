# Recorded with vhs (https://github.com/charmbracelet/vhs), from the repository root:  vhs backup/tapes/06-maestro.tape
# Needs the stack of step 5 and the Maestro demo running (see "Demo: Gazelle Maestro" in the main README);
# run.sh is the demo's runner: one POST of the test run to Maestro, then it prints the step results.
Output backup/06-maestro.mp4
Set Shell bash
Set FontSize 17
Set Width 1600
Set Height 900
Set Padding 24
Set Theme "GitHub Dark"
Set TypingSpeed 35ms
Hide
Type "export PS1='$ ' && cd ../maestro-tutorial/wgm-demo && clear"
Enter
Show
Type "# Mode C: one Maestro test run. Step 1 validates with matchbox, step 2 runs dap-001 in ITB"
Enter
Sleep 1s
Type "./run.sh"
Enter
Wait+Screen@180s /full report/
Sleep 6s
Type "./run.sh --broken     # the broken document: Maestro does not start ITB"
Enter
Wait+Screen@180s /broken patient summary/
Sleep 5s
Type "./run.sh --dap-002    # a valid document, and a test case the server fails"
Enter
Wait+Screen@180s /ITB: dap-002/
Sleep 8s
Screenshot backup/06-maestro.png
Sleep 2s
