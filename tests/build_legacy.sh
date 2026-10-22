#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
gcc=${RISCV_GCC:-riscv64-unknown-elf-gcc}
flags=(-march=rv64imac_zicsr -mabi=lp64 -mcmodel=medany -nostdlib -nostartfiles -static -Wl,--no-relax)
mkdir -p b1/build b2/build
for name in boot_uart_b1_hart0 boot_uart_b1_smp_l2; do
  "$gcc" "${flags[@]}" -Wl,-T,b1/boot_uart.ld "b1/$name.S" -o "b1/build/$name.elf"
done
for harts in 1 2; do
  "$gcc" "${flags[@]}" -DBENCH_HARTS="$harts" -Wl,-T,b2/boot_uart.ld \
    b2/boot_uart_b2_bench.S -o "b2/build/bench_harts${harts}.elf"
done
for name in boot_uart_b2_2ctx boot_uart_b2_2ctx_csr_bank boot_uart_b2_2ctx_csr_trap; do
  "$gcc" "${flags[@]}" -DBENCH_HARTS=2 -Wl,-T,"b2/$name.ld" "b2/$name.S" -o "b2/build/$name.elf"
done
printf 'LEGACY_FIRMWARE_BUILD=PASS (simulation not run)\n'
