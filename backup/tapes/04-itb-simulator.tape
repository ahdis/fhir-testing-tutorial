# Recorded with vhs (https://github.com/charmbracelet/vhs), from the repository root:  vhs backup/tapes/04-itb-simulator.tape
Output backup/04-itb-simulator.mp4
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
Type "# Mode B, client under test: ITB plays the Document Access Provider (ITI-67, ITI-68)"
Enter
Sleep 1s
Type "03-itb/consumer.sh"
Enter
Wait+Screen@120s /ITB result: SUCCESS/
Sleep 5s
Type "# a consumer that forgets the Authorization header"
Enter
Type "03-itb/consumer.sh --no-token"
Enter
Wait+Screen@120s /ITB result: FAILURE/
Sleep 8s
Screenshot backup/04-itb-simulator.png
Sleep 2s
