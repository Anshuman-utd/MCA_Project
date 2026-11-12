# Phase I report and video

## Report handoff

Anshuman prepares the final report from the team’s verified evidence and gives the editable source and exported PDF to Member 5. Member 5 verifies the files and commits the source under `docs/report/` and the PDF as `docs/IEEE_Project_Report.pdf`. Use the [IEEE conference template](https://www.ieee.org/conferences/publishing/templates.html). Include the five required sections:

- Abstract with the design objective and the prototype's verified scope.
- Literature Review with numbered citations from sources the team has actually read.
- Proposed Solution with the block diagram, ROM and RAM organization, controller state sequence, clock-edge timing, and shared-port arbitration. Add available measured results and the conditions under which they were obtained.
- Individual Contributions with all five names and each person's actual work. Each teammate supplies the relevant files, pull request and a short technical explanation. Credit Anshuman for the FPGA timing run and report preparation. Credit Member 4 for the shared-memory benchmark and generic synthesis. Credit Member 5 for the direct Harvard tests, report commit and completed video work.
- References in IEEE order of first citation. Verify edition and publication details for any textbook used.

Use Member 3's `docs/harvard-waveform.png` and Member 4's `docs/comparison-waveform.png` for the prototype evidence. Use the measured Harvard and baseline grant counts to compute operations per cycle. Include the ECP5 device, post-route Fmax, resource counts, and I/O assumptions from the [synthesis and timing results](../synthesis/results.md).

## Video handoff

After upload, Member 5 adds the accessible video link under **Prototype video** in the README.

| Time | Speaker and screen |
| --- | --- |
| 0:00–0:45 | Member 1 states the title and objective, lists the five names and explains the block diagram. |
| 0:45–1:30 | Member 2 introduces themselves and shows the decoder, read/write rules and RAM. |
| 1:30–2:45 | Member 3 introduces themselves, runs `make test-harvard` and shows an overlapping read and write across two fetch cycles, then shows write readback. |
| 2:45–3:40 | Member 4 introduces themselves, runs the comparison and explains the measured cycle counts and any available synthesis results. |
| 3:40–4:30 | Member 5 introduces themselves, shows the direct test proving instruction/data isolation, then points to the report in the repository. |

Member 1 introduces themselves by name in the opening. Keep the final runtime at or below five minutes. Check playback and permissions before submitting.

## Submission checklist

- [ ] Add the IEEE-format PDF to `docs/IEEE_Project_Report.pdf`. Include the abstract, literature review, proposed solution, individual contributions, and references.
- [ ] Add the video link to the README. Confirm that the video opens with the evaluator’s access and lasts at most five minutes.
- [ ] From a fresh clone, run the five Make targets listed in the README. Confirm that the block diagram, two waveform images, benchmark results, and synthesis results are visible in the repository.
- [ ] Confirm that the merged Git history shows all five members’ technical contributions.
- [ ] Submit the GitHub repository URL by **November 16, 2026 at 11:59 PM IST**. [Course submission form](https://docs.google.com/forms/d/e/1FAIpQLSc6Cx8OrOQLGj_X2ZMkyG5jc8mokq36mGRq2x8jGRNV1sbegA/viewform)
