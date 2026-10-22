# HYTRON64 SMT Experiments: B1-B4

**Status: development paused; retained as a research reference.**

This archive records the progression from a two-core Rocket foundation to
two-context execution experiments on one Rocket core. It includes source
snapshots, assembly tests, log checkers, recorded simulation evidence, and an
independent SMP2 reference. Main development is moving to SMP2.

The two-context implementation is deliberately limited. B3/B4 can issue and
execute a selected pair of independently fetched ADD/ADDI instructions in the
same cycle. They collect that pair through one frontend, drain the ordinary
pipeline, execute on two ALUs, and retire the results sequentially. This is
**not a general-purpose, continuously dual-issue SMT processor**.

## Stages and evidence

| Stage | Configuration | Established result |
|---|---|---|
| B1 | Two Small Rocket cores, shared inclusive L2 | Hart-0 UART/memory smoke test and a shared-cache-line round trip; foundation work, not SMT |
| B2 | One Rocket core, two experimental contexts, scalar issue | Context switching with pipeline drainage, separate integer RFs, selected banked M-mode CSR state, synchronous trap/return test |
| B3 | One Rocket core, two contexts, one selected instruction per context | Same-cycle pair issue and execution, sequential retirement, four arithmetic/RF cases |
| B4 | B3 mechanism repeated for 1,024 pairs | Three dependent arithmetic cases, every recorded result checked and final software RF checks passed |
| SMP2 reference | Two ordinary Small Rocket cores, one context each | Same three 1,024-operation arithmetic workloads per hart, every recorded RF write checked and both software results verified |

The B3 checkpoint is **R1.1 hardware plus TESTFIX R2 software**. The original
R1 capture boundary and UART-dependent test are not the final working version.
See [experiment scope](docs/EXPERIMENTS.md) and [results](docs/RESULTS.md).

## Recorded timing

| Case | B4 first capture to last pair commit | B4 first capture to software-checked marker | SMP2 release to both-hart join |
|---|---:|---:|---:|
| 0 | 42,016 cycles | 42,332 cycles | 6,370 cycles |
| 1 | 42,016 cycles | 42,329 cycles | 6,370 cycles |
| 2 | 42,020 cycles | 42,337 cycles | 6,373 cycles |

Each case performs **1,024 target arithmetic operations per context/hart**,
2,048 in total. Loop-control and verification instructions are additional.
The timing boundaries above differ. Their quotient is not a controlled SMT/SMP
speedup measurement. Host wall time includes boot and verbose logging and is
not a hardware performance metric. No area, power, or maximum-frequency result
is claimed.

## Check the archived evidence

Python 3 and Git are sufficient for the following checks; no RTL simulator is run:

```bash
python3 scripts/verify_release.py
python3 scripts/verify_evidence.py
```

The second command runs the published checkers against the recorded final logs:
four B3 cases, three B4 cases, and three SMP2 cases. It also checks the retained
B1/B2 success/checksum evidence and regenerates the recorded B4/SMP2 metrics.
These checks validate archived evidence; they are not a new hardware simulation.

## Source and reproduction

- `snapshots/b2/overlay`: final supplied B2 source checkpoint.
- `snapshots/b3/overlay`: working B3 R1.1 source checkpoint.
- `snapshots/b4/overlay`: working B4 source, including the SMP2 reference Config.
- `tests/b1`, `tests/b2`: historical firmware and linker inputs.
- `tests/b3`, `tests/b4`, `tests/smp2`: final working test inputs/checkers.
- `evidence`: selected final recorded logs, metrics, and the SMP2 DTS.
- `PROVENANCE.json`: original/reconstructed and publication-copy hashes.

Full Chipyard dependencies, PDKs, generated RTL, simulator binaries and ELF
binaries are not bundled. The supplied files do not establish an upstream
Chipyard or rocket-chip revision. Reproduction requires a compatible external
checkout; this is not a pinned, turnkey Chipyard distribution.
See [reproduction instructions and limits](docs/REPRODUCIBILITY.md).

## Project direction

The SMT branch is paused at its verified experimental scope. The experiment
established functional feasibility of selected paired execution, but did not
establish a general SMT throughput benefit or quantified resource savings.
The SMP2 reference is a functional starting point for separate SMP development.
This decision does not establish a general limitation of SMT architectures.

## Licensing and attribution

Project-authored publication material uses Apache License 2.0. Upstream source
portions retain their applicable licenses and attribution. Read [NOTICE](NOTICE)
and [third-party notices](THIRD_PARTY_NOTICES.md), including the preserved
Berkeley and SiFive license texts. No upstream endorsement is implied.
