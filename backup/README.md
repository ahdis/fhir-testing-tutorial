# Backup: recordings and screenshots of the hands-on

If Docker, the network or the time does not cooperate, follow the steps here.
Everything was recorded on 2026-11-15 from the scripts of this repository, with validator 7.0.6, matchbox v5.0.0-rc4 and ITB 1.30.2.

| Step | Recording | Result | In the browser |
|---|---|---|---|
| 1. Validator on the command line | [01-validator-cli.mp4](01-validator-cli.mp4) | [screenshot](01-validator-cli.png) | |
| 2. matchbox | [02-matchbox.mp4](02-matchbox.mp4) | [screenshot](02-matchbox.png) | [matchbox GUI with the broken document](02-matchbox-gui.png) |
| 3. ITB with matchbox as its validation service | [03-itb-matchbox.mp4](03-itb-matchbox.mp4) | [screenshot](03-itb-matchbox.png) | [the test session in ITB](03-itb-session.png), [matchbox's findings as ITB's step report](03-itb-step-report.png) |
| 4. ITB as a simulator, client under test | [04-itb-simulator.mp4](04-itb-simulator.mp4) | [screenshot](04-itb-simulator.png) | |
| 5. EU Health Data API tests, server under test | [05-eu-health-data-api.mp4](05-eu-health-data-api.mp4) | [screenshot](05-eu-health-data-api.png) | |

The recordings cut the waiting: the validator's package loading and the start of the containers are not shown.
In recordings 1 to 3 the output lines are shortened to 130 characters so that they fit the screen.

To record again: install [vhs](https://github.com/charmbracelet/vhs) and run, from the repository root,
`vhs backup/tapes/01-validator-cli.tape` (and the other tapes). Steps 3 and 4 need the stack of step 3 running,
step 5 its own (see the main README). The browser screenshots were taken with Playwright and are not scripted here.
