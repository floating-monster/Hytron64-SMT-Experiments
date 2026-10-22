# Publication review checks

Input review archive SHA256:

```
0af2864ccaf32a513b3e3051a594737174d07a26af068c1b4a7f44be2212bf2c
```

The review archive and all 198 entries of its inventory matched their hashes.
Selected public artifacts are indexed separately in PROVENANCE.json and
RELEASE_SHA256SUMS; the public repository does not reproduce all 198 review files.

Completed checks:

- The preserved final B3 checker passed four actual archived simulation logs.
- The preserved final B4 checker passed three actual archived simulation logs.
- The preserved final SMP2 checker passed three actual archived simulation logs.
- B4/SMP2 regenerated JSON metrics matched their original supplied metrics.
- The B1 clean hart-0 and round-trip success markers were found.
- The six retained B2 checksum/trap logs matched the expected checksum; the
  CSR/trap log also contained its explicit PASS marker.
- The B3 R1.1 core was reconstructed with a zero-fuzz patch from the supplied
  R1 source; its reconstructed hash matched the supplied R1.1 manifest.
- Non-comment source tokens matched before/after publication normalization for
  33 selected Scala/assembly copies. This is a text-equivalence check, not a
  compilation or binary-equivalence claim.
- Python/shell syntax, relative Markdown links, English text, path redaction,
  snapshot-stage switching and unknown-source rejection were checked.
- Git's staged whitespace check and the public file hash manifest were checked.

No fresh Scala/RTL/ELF build or hardware simulation was performed as part of the
publication review. No new upstream version pin, area/power result or controlled
SMT/SMP speedup claim was established.
