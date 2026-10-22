# Third-party notices

This repository contains locally modified source derived from Rocket/Chipyard.
Original attribution headers are retained and published Scala snapshots carry
an additional prominent local-modification notice. These source snapshots are
not presented as original implementations of Rocket or its CSR machinery.

| Material | Preserved notice |
|---|---|
| Rocket files referring to LICENSE.Berkeley | `LICENSE.Berkeley`, copied from the supplied rocket-chip tree |
| Rocket/Chipyard files referring to LICENSE.SiFive | `LICENSE.SiFive`, Apache License 2.0, copied from the supplied tree |
| Chipyard licensing context | `LICENSES/Chipyard-BSD-3-Clause.txt`, copied from the supplied Chipyard LICENSE |
| Original project publication files | Root `LICENSE`, Apache License 2.0 |

The root Apache license does not replace the applicable Berkeley notices on
upstream portions. Copyright/attribution statements in source and the supplied
license texts remain applicable. Trailing whitespace is normalized in the
publication copies; license wording is retained.

Only selected experiment-related source is included. No JTAG implementation,
third-party dependency tree, simulator binary, PDK, or NVMe/MMC specification PDF
is redistributed in this repository. Links between historical stages and file
hashes are documented in `PROVENANCE.json`.
