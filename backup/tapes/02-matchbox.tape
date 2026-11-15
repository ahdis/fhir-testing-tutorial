# Recorded with vhs (https://github.com/charmbracelet/vhs), from the repository root:  vhs backup/tapes/02-matchbox.tape
Output backup/02-matchbox.mp4
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
Type "# Mode A: the same validation with matchbox, a validator that keeps running"
Enter
Sleep 1s
Type "(cd 02-matchbox && docker compose up -d)"
Enter
Wait+Screen@180s /(Started|Running)/
Sleep 2s
Type "02-matchbox/validate.sh examples/eps-minimal.json"
Enter
Wait+Screen@120s /information: \d/
Sleep 3s
Type "02-matchbox/validate.sh examples/eps-broken.json | cut -c1-170"
Enter
Wait+Screen@120s /error: \d+/
Sleep 8s
Screenshot backup/02-matchbox.png
Sleep 2s
