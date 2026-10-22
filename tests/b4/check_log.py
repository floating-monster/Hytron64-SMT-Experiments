#!/usr/bin/env python3
"""Verify every dependent operation, both timing boundaries and cycle accounting."""
import argparse,json,re
from pathlib import Path

p=argparse.ArgumentParser()
p.add_argument('case',type=int,choices=range(3))
p.add_argument('log',type=Path)
p.add_argument('--metrics',type=Path)
p.add_argument('--host-seconds',type=float)
a=p.parse_args()
text=a.log.read_text(errors='replace')
N=1024;MASK=(1<<64)-1
def require(ok,msg):
    if not ok: raise SystemExit('B4_CHECK_FAIL: '+msg)
require(len(re.findall(r'^B4_SOFTWARE_EXIT=0$',text,re.M))==1,'successful software/simulator termination absent')
require(not re.search(r'Assertion failed|%Error|%Fatal|\*\*\* FAILED \*\*\*',text),'simulator failure')
def parse(prefix,fields,hex_fields=()):
    result=[]
    for line in text.splitlines():
        if prefix not in line: continue
        values=dict(re.findall(r'(\w+)=\s*([0-9a-fA-F]+)',line))
        require(all(k in values for k in fields),'malformed '+line)
        result.append({k:int(values[k],16 if k in hex_fields else 10) for k in fields})
    return result
events={}
for kind,fields,hfields in [
    ('CAPTURE',('cycle','ctx','pc','inst'),('pc','inst')),
    ('ISSUE',('cycle','ctx','pc','inst','a','b'),('pc','inst','a','b')),
    ('EXEC',('cycle','ctx','result'),('result',)),
    ('COMMIT',('cycle','ctx','pc','rd','result'),('pc','result'))]:
    rows=parse('[B3-PAIR] '+kind+' ',fields,hfields)
    require(len(rows)==2*N,kind+' total count')
    require(all(r['ctx'] in (0,1) for r in rows),kind+' invalid context')
    events[kind]=[[r for r in rows if r['ctx']==c] for c in (0,1)]
    require(all(len(rows)==N for rows in events[kind]),kind+' per-context count')
rounds=parse('[B4-ROUND] ',('round','cycle'))
require(len(rounds)==N and [r['round'] for r in rounds]==list(range(N)),'round sequence/count')
seeds=[17,123] if a.case in (0,1) else [MASK,(1<<63)-1]
steps=[1,3] if a.case==0 else ([25,-5] if a.case==1 else [1,1])
previous=seeds[:]
last_commit=-1
for r in range(N):
    issue=[events['ISSUE'][c][r] for c in (0,1)]
    ex=[events['EXEC'][c][r] for c in (0,1)]
    commit=[events['COMMIT'][c][r] for c in (0,1)]
    require(issue[0]['cycle']==issue[1]['cycle']==rounds[r]['cycle'],f'round{r}: simultaneous issue')
    require(ex[0]['cycle']==ex[1]['cycle']==issue[0]['cycle']+1,f'round{r}: simultaneous execute')
    require(commit[0]['cycle']==ex[0]['cycle']+1 and commit[1]['cycle']==commit[0]['cycle']+1,f'round{r}: retire order')
    for c in (0,1):
        cap=events['CAPTURE'][c][r];i=issue[c];inst=i['inst'];co=commit[c]
        require(last_commit<cap['cycle']<i['cycle'],f'round{r}: capture order')
        require(cap['pc']==i['pc']==co['pc']==0x80000200+0x1000*c,f'round{r}: PC')
        require(cap['inst']==inst,f'round{r}: captured instruction')
        require((inst>>15 & 31)==7 and (inst>>7 & 31)==7 and co['rd']==7,f'round{r}: dependent x7 read/write')
        expected_inst=0x005383b3 if a.case==1 and c==0 else ((steps[c]&4095)<<20 | 7<<15 | 7<<7 | 0x13)
        require(inst==expected_inst,f'round{r}: ADD/ADDI encoding')
        require(i['a']==previous[c] and i['b']==steps[c]&MASK,f'round{r}: RF dependency/operand ctx{c}')
        expected=(previous[c]+steps[c])&MASK
        require(ex[c]['result']==co['result']==expected,f'round{r}: result ctx{c}')
        previous[c]=expected
    last_commit=commit[1]['cycle']
summary=parse('[B4-SUMMARY] ',('pairs','paired_instructions','start','end','cycles','collect','drain','issue','execute','commit','redirect'))
software=parse('[B4-SOFTWARE] ',('start','end','cycles','pairs'))
require(len(summary)==len(software)==1,'single hardware summary/software completion marker')
s=summary[0];sw=software[0]
require(s['pairs']==N and s['paired_instructions']==2*N,'summary operation count')
require(s['start']==min(events['CAPTURE'][c][0]['cycle'] for c in (0,1)),'window start')
require(s['end']==last_commit and s['cycles']==s['end']-s['start']+1,'window end/duration')
require(s['issue']==s['execute']==N and s['commit']==2*N and s['redirect']==N-1,'phase cycle counts')
require(sum(s[k] for k in ('collect','drain','issue','execute','commit','redirect'))==s['cycles'],'cycle accounting')
require(sw['start']==s['start'] and sw['end']>s['end'] and sw['cycles']==sw['end']-sw['start']+1 and sw['pairs']==N,'software completion window')
metrics={'case':a.case,'pairs':N,'paired_instructions':2*N,'final_rf':[f'0x{x:016x}' for x in previous],
         'pair_window':s,'software_checked_window':sw,
         'paired_instructions_per_pair_window_cycle':2*N/s['cycles'],
         'host_wall_seconds_with_verbose':a.host_seconds}
if a.metrics: a.metrics.write_text(json.dumps(metrics,indent=2)+'\n')
print(f'B4_CASE{a.case}_REPEAT_1024_DEPENDENCY_RF=PASS')
print(f'B4_CASE{a.case}_PAIR_WINDOW_CYCLES={s["cycles"]} SOFTWARE_CHECKED_CYCLES={sw["cycles"]}')
print('B4_CASE%d_PHASE_CYCLES='%a.case+' '.join(f'{k}={s[k]}' for k in ('collect','drain','issue','execute','commit','redirect')))
if a.host_seconds is not None: print(f'B4_CASE{a.case}_HOST_SECONDS_WITH_VERBOSE={a.host_seconds:.6f}')
