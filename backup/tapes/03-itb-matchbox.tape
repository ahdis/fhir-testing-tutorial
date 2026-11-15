# Recorded with vhs (https://github.com/charmbracelet/vhs), from the repository root:  vhs backup/tapes/03-itb-matchbox.tape
Output backup/03-itb-matchbox.mp4
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
Type "# Mode C: ITB receives a document and has matchbox validate it"
Enter
Sleep 1s
Type "03-itb/setup.sh 2>&1 | tail -n 5"
Enter
Wait+Screen@400s /your system calls/
Sleep 3s
Type "03-itb/run.sh examples/eps-minimal.json"
Enter
Wait+Screen@120s /ITB result: SUCCESS/
Sleep 3s
Type "clear"
Enter
Type "03-itb/run.sh examples/eps-broken.json | cut -c1-130"
Enter
Wait+Screen@120s /ITB result: FAILURE/
Sleep 8s
Screenshot backup/03-itb-matchbox.png
Sleep 2s
