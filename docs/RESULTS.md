# Recorded results and timing boundaries

These figures come from the retained final logs and metrics. Rechecking those
logs is not a new RTL simulation. The complete final evidence is under
`evidence/`, and `scripts/verify_evidence.py` checks it using the final supplied
test checkers.

## B1 and B2

| Evidence | Recorded conclusion |
|---|---|
| B1 hart-0 smoke | `HYTRON64-010L UART MEM PASS` |
| B1 two-hart handoff | `HYTRON64-B1 SMP L2 ROUNDTRIP PASS` |
| B2 original one-core arithmetic benchmark | HARTS=1, expected checksum |
| B2 original SMP arithmetic benchmark | HARTS=2 on the two-core B1 Config, expected checksum |
| B2 two-context benchmark | HARTS=2 on the one-core two-context Config, expected checksum |
| B2 CSR banking regression/isolation-labelled logs | Expected checksum; scope is the supplied corresponding firmware |
| B2 synchronous trap test | `HYTRON64-B2 CSR TRAP PASS`, expected checksum |

The common checksum is `0x00000004A8194EA0`. The synchronous-trap log records
`CYCLES=0x000000000015BFBF`. Its time is for that historical checksum/trap
workload; it is not comparable with the later 1,024-operation B4/SMP2 workload.
No additional independent register banking claim is inferred from a filename.

## B3: four one-shot pairs

| Case | Context 0 computed result | Context 1 computed result | Scope |
|---|---:|---:|---|
| 0 | 42 | 118 | ADD / ADDI with distinct values at the same RF destination |
| 1 | 93 | 234 | ADDI / ADD role exchange |
| 2 | 0xffffffffffffffff | 777, discarded at x0 | x0 read/write behavior; context-1 x7 remains 88 |
| 3 | 0 | 0x8000000000000000 | 64-bit wraparound |

All four final archived logs passed the original simultaneous issue/execute,
sequential commit, reference-value, and successful software RF-check termination
requirements. A COMMIT print alone is not treated as a completed RF readback.

## B4: 1,024 dependent pairs

| Case | Final context-0 x7 | Final context-1 x7 | Pair window | Software-checked window |
|---|---|---|---:|---:|
| 0 | 1041 | 3195 | 42,016 | 42,332 |
| 1 | 25617 | -4997 | 42,016 | 42,329 |
| 2 | 1023 | 0x80000000000003ff | 42,020 | 42,337 |

All times in this table are core-counter cycles, inclusive of both endpoints.

- **Pair window:** first normal target CAPTURE to the final context-1 COMMIT.
- **Software-checked window:** the same first CAPTURE to the actual retired
  context-1 NOP reached after both contexts' final software RF checks.

| Case | Collect | Drain | Issue | Execute | Commit | Redirect |
|---|---:|---:|---:|---:|---:|---:|
| 0 | 36,897 | 0 | 1,024 | 1,024 | 2,048 | 1,023 |
| 1 | 36,897 | 0 | 1,024 | 1,024 | 2,048 | 1,023 |
| 2 | 36,901 | 0 | 1,024 | 1,024 | 2,048 | 1,023 |

The six categories are disjoint and sum to the pair window. Collect includes
frontend supply, ordinary loop work and context-switch waiting. Drain counts
the narrower state where ordinary issue is held for a target/slot and the
defined ordinary-pipeline/long-latency conditions have not emptied. Zero drain
does not mean switching is free. The final redirect lies outside the pair
window. No aggregate cache-miss attribution is inferred from collect.

## SMP2: two independent harts

| Case | Hart-0 target-retirement window | Hart-1 target-retirement window | Hart-0 release to both-hart join |
|---|---:|---:|---:|
| 0 | 6,139 | 6,139 | 6,370 |
| 1 | 6,139 | 6,139 | 6,370 |
| 2 | 6,139 | 6,139 | 6,373 |

Each hart retires and checks 1,024 target operations, with the same final values
as B4. Target-retirement windows run from first to last target retirement in
that hart. The overall interval runs from hart 0's release marker before the
go store to its join marker after observing both completion flags. It uses only
hart 0's counter, so it does not require subtracting different harts' counters.

## Interpretation

The current repeated-pair mechanism spends most of its pair window collecting
and preparing the next pair. SMP2 has independent frontends/pipelines and its
recorded workload interval is substantially shorter. The ratio of the displayed
software-checked figures is about 6.6, but start/end definitions and control
work differ; this is **not a controlled architectural speedup claim**.

Host runs with verbose logging took about 7.45-7.60 seconds for B4 and
5.60-5.92 seconds for SMP2. Those process times include boot/logging and host
load. They are not CPU execution seconds. Bus frequency and DTS timebase values
are not substituted for a measured core operating frequency.

No synthesis area, power, maximum clock, or resource-normalized performance
comparison was performed. The result supports retaining this implementation as
a research reference and proceeding with SMP2 development; it does not establish
that a different fine-grained multithreaded or SMT design is unhelpful.
