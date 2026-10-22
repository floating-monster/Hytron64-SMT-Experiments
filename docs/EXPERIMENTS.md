# Experiment scope

## B1: SMP/L2 foundation

`Hytron64SmallSmpL2B1Config` instantiates two Small Rocket cores with the shared
inclusive L2 inherited from the local AbstractConfig. It is not a two-context
SMT configuration. The retained hart-0 smoke log contains UART/memory PASS.
The round-trip firmware exchanges payload, completion, acknowledgment and a
second response within one 64-byte shared cache line at 0x81000000, using fences.
Its log contains `HYTRON64-B1 SMP L2 ROUNDTRIP PASS`.

An earlier boot UART log contains interleaved output; it is retained for context
and is not treated as an additional clean pass. The original pristine B1 core
checkout and a pinned upstream revision were not supplied. The archived B1
result is a limited functional handoff test, not exhaustive coherence validation.

## B2: two contexts, single issue

The supplied final B2 checkpoint implements two integer register files, a selected
active context, context resume PCs, and scalar issue. After the retirement quota
the scheduler stops issuing and waits for pipeline/scoreboard/long-latency
conditions before switching. Context 1 initially starts at 0x80001000.

Selected M-mode state is banked, including mstatus, mie, mtvec, mepc, mcause,
mtval and mscratch. Other state, counters, interrupt/debug machinery and hardware
interfaces are not thereby converted into independent architectural harts.
The old RocketCore comment describing all CSR state as shared is historical;
CSR.scala and this documented scope are the relevant descriptions.

The CSR/trap firmware checks different mscratch and MIE settings, an M-mode
ECALL and a compressed breakpoint path, trap cause/PC/status fields and return.
The final log contains `HYTRON64-B2 CSR TRAP PASS` and the expected checksum.
This is synchronous-trap evidence, not general interrupt/debug isolation proof.

Historical firmware/logs use `HARTS=2` for both SMP and two-context test modes.
For the one-core B2 Config that label denotes two logical test participants;
it does not establish two physical harts.

## B3: selected simultaneous issue and execute

Targets are one legal, exception-free, non-replay 32-bit ADD/ADDI at 0x80000200
for context 0 and 0x80001200 for context 1. A valid target is held while the
ordinary pipeline drains and is saved in its context slot. The other context
is fetched using the existing drained context switch. Both ready slots read
their own RF and issue in one cycle. In the next cycle the ordinary Rocket ALU
and one added Rocket ALU compute the two results. Results retire through two
successive scalar cycles with their context-specific RF destination and PC.

The four tests cover ADD/ADDI role exchange, negative immediates, x0 handling
and 64-bit wraparound. Software reads and compares RF results after execution.
R1.1 lets frontend replay and exception entries follow the ordinary Rocket path;
it does not park those entries as normal target instructions. TESTFIX R2 removes
an unverified UART address and uses successful HTIF termination after both RF
checks. The capture assertions and hardware-result checks remain in place.

## B4: repeated dependent pairs

The B3 state machine re-arms after each completed pair for 1,024 rounds. Every
target instruction reads/writes x7, and every next operand must match its own
preceding result. The three tests are the same arithmetic workloads used by
the SMP2 reference. Both final software comparisons and every logged target
write are checked. The default repeat count remains 1 for B3 configurations.

This mechanism repeatedly serializes frontend collection and ordinary-pipeline
drainage. It is not a design that accepts two arbitrary instructions every cycle.
The pair subpath is restricted to ordinary M-mode and the stated integer
instructions. Asynchronous interrupt/debug handling, general memory operations,
FPU/vector/RoCC paths and general precise dual retirement are outside its scope.

## SMP2 reference

Two ordinary Small Rocket cores execute the same per-hart dependent arithmetic
and scalar loop control. Hart 0 releases hart 1 with CLINT MSIP1, waits for ready,
publishes go, and later joins both completion flags. Every target retirement is
checked for hart ID, instruction, destination and expected accumulated value.
Both software RF checks must pass before successful HTIF termination.

This is a two-core arithmetic reference, not full SMP validation. Cache stress,
atomic synchronization, general interprocessor interrupt handling, operating
system bring-up and fault tolerance remain future SMP work.
