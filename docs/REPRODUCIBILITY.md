# Reproduction and provenance limits

## Recorded environment

The build logs identify sbt 1.8.2, Scala 2.13 output directories, Temurin Java
17.0.20.1, and Verilator 5.032. The final B3/B4/SMP2 ELF scripts use the external
`riscv64-unknown-elf-gcc`/`objdump` toolchain, `rv64i_zicsr`, and `lp64`.
The declared original environment used GCC 15.2.0 and firtool 1.75.0; this review
does not independently establish those versions from compiler-version output.

The workspace Git root was the enclosing workspace, not an established upstream
Chipyard repository revision. The rocket-chip upstream revision was not found.
Do not substitute that workspace commit as a pinned upstream dependency SHA.

## Source snapshots

B2 source is recovered from the supplied baseline tar members. B3 source is the
R1 core plus its zero-fuzz R1.1 patch; the recovered core hash exactly matches
the supplied R1.1 manifest. Its deeply nested overlay file was not included by
the review collector's depth limit. B4 source is copied from the supplied live
tree. `RocketContextParams.scala` is included in **all three** stage overlays.
Config dependencies are included per stage.

Publication changes are English comment translation, local-path redaction,
trailing-whitespace normalization and prominent modification notices. Raw source
content and published hashes are recorded in PROVENANCE.json. No instruction or
hardware behavior change is intended by publication normalization. Publication
copies have not been recompiled in a full external toolchain during review.

## Apply to a compatible external Chipyard tree

Use a separate checkout or preserve existing work. The helper accepts only
recognized source hashes and backs up the managed files before writing. It also
removes managed Config files that do not belong to the selected stage, so a B4
Config cannot accidentally refer to a parameter absent from B2.

```bash
python3 scripts/apply_snapshot.py /path/to/chipyard --stage b4
python3 scripts/apply_snapshot.py /path/to/chipyard --stage b4 --apply
```

An unknown baseline causes a stop, not a forced overwrite. This guard is not a
general upstream-porting tool. A fresh, unmatched upstream Rocket checkout may
need a separately reviewed port because its exact compatibility is not pinned.

For b4, build each relevant Config in the external tree:

```bash
cd /path/to/chipyard
make -C sims/verilator CONFIG=Hytron64SmallB4RepeatConfig -j2
make -C sims/verilator CONFIG=Hytron64SmallSMP2BenchConfig -j2
```

From this archive, build/run the final tests:

```bash
bash tests/b4/build.sh
bash tests/b4/run.sh /path/to/chipyard
bash tests/smp2/build.sh
bash tests/smp2/run.sh /path/to/chipyard
```

For the historical B3 stage, apply `--stage b3`, build
`Hytron64SmallB3DualAddR1p1Config`, then run `tests/b3/build.sh` and
`tests/b3/run.sh /path/to/chipyard`. The finalized B3 runner uses verbose logging
and successful simulator exit rather than a UART PASS message.

Use the matching external Java/firtool/Verilator environment. JDK21 failed
before source compilation in the historical local setup; the final builds used
JDK17. A misleading old logfile name mentioning JDK11 is not version evidence.

## Historical B1/B2 firmware

`tests/build_legacy.sh` compiles the retained assembly inputs. It does not assert
that all historical configurations can be regenerated in a newly fetched tree.
B1's old hart-0 memory smoke includes the then-used 0x08000000 region; inspect
the matching historical memory map before rerunning it on a current platform.
UART-based legacy tests use 0x10020000 in their sources.

For B2 use its snapshot, build `Hytron64SmallB2TwoContextConfig`, and run its
matching context/trap ELF in the external simulator. The CSR/trap source uses
a compressed breakpoint and therefore needs a toolchain ISA including `c`.
The helper builds legacy firmware with `rv64imac_zicsr`.

The retained 1-core/SMP two-hart benchmark logs and the B2 context logs refer to
different Configs; do not run the physical-hart firmware in place of the
context-1-at-0x80001000 firmware.

## What was rechecked for this publication

- The input archive SHA256 and all 198 inventory entries matched.
- Final B3/B4/SMP2 archived logs passed their original supplied checkers.
- Regenerated B4/SMP2 metrics matched the supplied recorded JSON data.
- B1 clean hart-0 and round-trip markers and B2 checksum/trap markers were read.
- Publication source hashes, English text, scripts and Git whitespace checks
  were checked locally.

These are publication/evidence checks, not new Scala/RTL/ELF simulation runs.
Historical simulator binaries and full generated RTL are intentionally absent.
