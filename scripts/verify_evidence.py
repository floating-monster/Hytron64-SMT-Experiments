#!/usr/bin/env python3
"""Validate retained evidence without running hardware simulation."""
from pathlib import Path
import subprocess,sys,json,tempfile
root=Path(__file__).resolve().parent.parent
def require(ok,msg):
    if not ok:raise SystemExit('EVIDENCE_FAIL: '+msg)
for name,token in [('HYTRON64_B1_HART0_UART.log','HYTRON64-010L UART MEM PASS'),
                   ('HYTRON64_B1_SMP_L2_ROUNDTRIP.log','HYTRON64-B1 SMP L2 ROUNDTRIP PASS')]:
    require(token in (root/'evidence/b1'/name).read_text(),name)
print('B1_RETAINED_MARKERS=PASS')
for path in (root/'evidence/b2').glob('*.log'):
    text=path.read_text();require('CHECKSUM=0x00000004A8194EA0' in text,path.name)
    if 'CSR_TRAP' in path.name:require('CSR TRAP PASS' in text,path.name)
print('B2_RETAINED_CHECKSUM_TRAP_MARKERS=PASS')
for stage,count in [('b3',4),('b4',3),('smp2',3)]:
    for case in range(count):
        cmd=[sys.executable,str(root/'tests'/stage/'check_log.py'),str(case),str(root/'evidence'/stage/f'case{case}.run.log')]
        with tempfile.TemporaryDirectory() as tmp:
            expected_path=root/'evidence'/stage/f'case{case}.metrics.json'
            if expected_path.exists():
                expected=json.loads(expected_path.read_text());host=expected['host_wall_seconds_with_verbose']
                output=Path(tmp)/'metrics.json'
                cmd+=['--metrics',str(output),'--host-seconds',str(host)]
            result=subprocess.run(cmd)
            require(result.returncode==0,f'{stage} case{case}')
            if expected_path.exists():require(json.loads(output.read_text())==expected,f'{stage} case{case} metrics mismatch')
print('ALL_ARCHIVED_EVIDENCE=PASS (no new hardware simulation)')
