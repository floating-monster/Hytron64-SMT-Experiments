#!/usr/bin/env python3
"""Check actual per-hart retirement traces and software success; no RTL changes."""
import argparse,json,re
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('case',type=int,choices=range(3));p.add_argument('log',type=Path)
p.add_argument('--metrics',type=Path);p.add_argument('--host-seconds',type=float);a=p.parse_args()
text=a.log.read_text(errors='replace');N=1024;M=(1<<64)-1
def require(ok,msg):
    if not ok: raise SystemExit('SMP2_CHECK_FAIL: '+msg)
require(len(re.findall(r'^SMP2_SOFTWARE_EXIT=0$',text,re.M))==1,'software/simulator success absent')
require(not re.search(r'Assertion failed|%Error|%Fatal|\*\*\* FAILED \*\*\*',text),'simulator failure')
pattern=re.compile(r'^C(?P<hart>\d+):\s*(?P<cycle>\d+)\s+\[(?P<valid>[01])\]\s+pc=\[(?P<pc>[0-9a-fA-F]+)\]\s+W\[r\s*(?P<rd>\d+)=(?P<value>[0-9a-fA-F]+)\]\[(?P<wen>[01])\].*?inst=\[(?P<inst>[0-9a-fA-F]+)\]')
rows=[]
for line in text.splitlines():
    m=pattern.search(line)
    if not m: continue
    r={k:int(v,16 if k in ('pc','value','inst') else 10) for k,v in m.groupdict().items()}
    if r['valid']: rows.append(r)
require({r['hart'] for r in rows}=={0,1},'retirement trace must contain both hart IDs')
seeds=[17,123] if a.case<2 else [M,(1<<63)-1];steps=[[1,3],[25,-5],[1,1]][a.case]
metrics={'case':a.case,'operations_per_hart':N,'total_target_operations':2*N,'harts':[],
         'host_wall_seconds_with_verbose':a.host_seconds,
         'timing_note':'overall release-to-join uses only hart0 timer; local hart intervals use each own timer; no cross-hart absolute counter subtraction'}
starts=[];firsts=[];lasts=[];ends=[]
for h in (0,1):
    trace=[r for r in rows if r['hart']==h]
    for x,y in zip(trace,trace[1:]): require(x['cycle']<=y['cycle'],f'hart{h}: timer wrap/reorder')
    def marker(pc):
        hits=[r for r in trace if r['pc']==pc]
        require(len(hits)==1 and hits[0]['inst']==0x13,f'hart{h}: marker at {pc:x}')
        return hits[0]['cycle']
    start=marker(0x80000100+0x1000*h);done=marker(0x80000300+0x1000*h)
    target=[r for r in trace if r['pc']==0x80000200+0x1000*h]
    require(len(target)==N,f'hart{h}: expected {N} retired target operations, got {len(target)}')
    prev=seeds[h]
    inst=0x005383b3 if a.case==1 and h==0 else ((steps[h]&4095)<<20 |7<<15|7<<7|0x13)
    for i,r in enumerate(target):
        prev=(prev+steps[h])&M
        require(r['inst']==inst and r['rd']==7 and r['wen']==1,f'hart{h} op{i}: opcode/RF write')
        require(r['value']==prev,f'hart{h} op{i}: dependent RF result')
    require(start<target[0]['cycle']<=target[-1]['cycle']<done,f'hart{h}: marker order')
    item={'hart':h,'start_marker_cycle':start,'first_target_retire_cycle':target[0]['cycle'],
          'last_target_retire_cycle':target[-1]['cycle'],'rf_checked_marker_cycle':done,
          'target_retire_window_cycles':target[-1]['cycle']-target[0]['cycle']+1,
          'start_to_rf_checked_cycles':done-start+1,'final_rf':f'0x{prev:016x}'}
    metrics['harts'].append(item);starts.append(start);firsts.append(target[0]['cycle']);lasts.append(target[-1]['cycle']);ends.append(done)
join=[r for r in rows if r['hart']==0 and r['pc']==0x80000380]
require(len(join)==1 and join[0]['inst']==0x13 and join[0]['cycle']>ends[0],'hart0 successful join marker')
metrics['hart0_release_to_join_cycles']=join[0]['cycle']-starts[0]+1
if a.metrics:a.metrics.write_text(json.dumps(metrics,indent=2)+'\n')
print(f'SMP2_CASE{a.case}_2HART_1024_DEPENDENCY_RF=PASS')
for item in metrics['harts']:
    print(f'SMP2_CASE{a.case}_HART{item["hart"]}_TARGET_RETIRE_CYCLES={item["target_retire_window_cycles"]} START_TO_RF_CHECK_CYCLES={item["start_to_rf_checked_cycles"]}')
print(f'SMP2_CASE{a.case}_HART0_RELEASE_TO_BOTH_JOIN_CYCLES={metrics["hart0_release_to_join_cycles"]}')
if a.host_seconds is not None:print(f'SMP2_CASE{a.case}_HOST_SECONDS_WITH_VERBOSE={a.host_seconds:.6f}')
