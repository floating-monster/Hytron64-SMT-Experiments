#!/usr/bin/env python3
"""Require paired hardware events and successful software RF-check termination."""
import re, sys
from pathlib import Path

if len(sys.argv) != 3:
    raise SystemExit('usage: check_log.py CASE RUN.log')
case = int(sys.argv[1])
log = Path(sys.argv[2]).read_text(errors='replace')
mask = (1 << 64)-1
expected = [(42,118), (93,234), (mask,777), (0,1<<63)][case]
def require(ok, msg):
    if not ok:
        raise SystemExit('B3_CHECK_FAIL: '+msg)
require(len(re.findall(r'^B3_SOFTWARE_EXIT=0$', log, re.M)) == 1, 'successful simulator/software exit absent')
require(not re.search(r'DUALADD RF FAIL|Assertion failed|%Error|B3_CHECK_FAIL', log), 'failure in log')
def events(kind, fields):
    rows = []
    for line in log.splitlines():
        if f'[B3-PAIR] {kind} ' not in line:
            continue
        values = dict(re.findall(r'(\w+)=\s*([0-9a-fA-F]+)', line))
        require(all(k in values for k in fields), 'malformed '+line)
        rows.append({k:int(values[k], 10 if k in ('cycle','ctx','rd') else 16) for k in fields})
    require(len(rows) == 2 and sorted(r['ctx'] for r in rows) == [0,1], f'{kind} must occur once per context')
    return sorted(rows, key=lambda r:r['ctx'])
capture = events('CAPTURE', ('cycle','ctx','pc','inst'))
issue = events('ISSUE', ('cycle','ctx','pc','inst','a','b'))
execute = events('EXEC', ('cycle','ctx','result'))
commit = events('COMMIT', ('cycle','ctx','pc','rd','result'))
require(issue[0]['cycle'] == issue[1]['cycle'], 'issue cycles differ')
require(execute[0]['cycle'] == execute[1]['cycle'] == issue[0]['cycle']+1, 'execute cycles differ')
require(commit[0]['cycle'] == execute[0]['cycle']+1 and commit[1]['cycle'] == commit[0]['cycle']+1,
        'commit order differs')
def sext12(x):
    return x-4096 if x & 2048 else x
for c in range(2):
    i, cap, ex, co = issue[c], capture[c], execute[c], commit[c]
    require(cap['cycle'] < i['cycle'], 'issue before capture')
    require(cap['pc'] == i['pc'] == co['pc'] == (0x80000200+0x1000*c), 'PC mismatch')
    require(cap['inst'] == i['inst'], 'instruction changed after capture')
    inst = i['inst']
    add = inst & 0xfe00707f == 0x33
    addi = inst & 0x707f == 0x13
    require(add or addi, 'non ADD/ADDI instruction')
    require(co['rd'] == (inst >> 7 & 31), 'destination mismatch')
    require((i['a']+i['b']) & mask == ex['result'] == co['result'] == expected[c], 'ALU/reference mismatch')
    if inst >> 15 & 31 == 0:
        require(i['a'] == 0, 'x0 operand is nonzero')
    if addi:
        require(i['b'] == sext12(inst >> 20) & mask, 'immediate sign extension mismatch')
require(case != 2 or commit[1]['rd'] == 0, 'case2 must discard the context1 x0 write')
print(f'B3_CASE{case}_SIMULTANEOUS_ISSUE_EXEC_RF=PASS')
