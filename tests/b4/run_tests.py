#!/usr/bin/env python3
import argparse,datetime,os,pathlib,shutil,subprocess,sys,time
p=argparse.ArgumentParser();p.add_argument('chipyard',type=pathlib.Path);a=p.parse_args()
chip=a.chipyard.expanduser().resolve();here=pathlib.Path(__file__).resolve().parent
config=os.environ.get('B4_CONFIG','Hytron64SmallB4RepeatConfig')
sim=chip/'sims/verilator'/('simulator-chipyard.harness-'+config)
if not sim.is_file(): raise SystemExit('SIMULATOR_MISSING: '+str(sim))
for case in range(3):
    elf=here/f'build/case{case}.elf';log=here/f'build/case{case}.run.log'
    if not elf.is_file(): raise SystemExit('ELF_MISSING: '+str(elf))
    if log.exists(): shutil.copyfile(log,log.with_name(log.name+'.before_'+datetime.datetime.now().strftime('%Y%m%d_%H%M%S_%f')))
    start=time.perf_counter()
    with log.open('w') as stream:
        result=subprocess.run([str(sim),'+permissive','+verbose','+max-cycles=2000000','+permissive-off',str(elf)],
            cwd=chip/'sims/verilator',stdout=stream,stderr=subprocess.STDOUT)
    elapsed=time.perf_counter()-start
    if result.returncode!=0:
        print(f'B4_CASE{case}_SIMULATOR_EXIT={result.returncode}',file=sys.stderr)
        print('\n'.join(log.read_text(errors='replace').splitlines()[-40:]),file=sys.stderr)
        raise SystemExit(1)
    with log.open('a') as stream: stream.write('\nB4_SOFTWARE_EXIT=0\n')
    result=subprocess.run([sys.executable,str(here/'check_log.py'),str(case),str(log),
        '--metrics',str(here/f'build/case{case}.metrics.json'),'--host-seconds',str(elapsed)])
    if result.returncode: raise SystemExit(result.returncode)
