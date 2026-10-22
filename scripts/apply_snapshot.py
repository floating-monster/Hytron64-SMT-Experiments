#!/usr/bin/env python3
"""Apply a supplied historical overlay to a recognized compatible source tree."""
from pathlib import Path
import argparse,hashlib,json,datetime,tarfile,shutil
p=argparse.ArgumentParser();p.add_argument('chipyard',type=Path);p.add_argument('--stage',choices=('b2','b3','b4'),required=True)
p.add_argument('--apply',action='store_true');a=p.parse_args()
root=Path(__file__).resolve().parent.parent;chip=a.chipyard.expanduser().resolve()
overlay=root/'snapshots'/a.stage/'overlay';known=json.loads((root/'scripts/snapshot_hashes.json').read_text())
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
if not (chip/'generators/rocket-chip/src/main/scala/rocket/RocketCore.scala').is_file():raise SystemExit('CHIPYARD_SOURCE_NOT_FOUND')
for name,allowed in known.items():
    path=chip/name
    if path.exists() and (not path.is_file() or sha(path) not in allowed):raise SystemExit('UNRECOGNIZED_SOURCE: '+str(path))
print('SNAPSHOT_BASELINE_HASH_CHECK=PASS')
if not a.apply:raise SystemExit(0)
stamp=datetime.datetime.now().strftime('%Y%m%d_%H%M%S_%f');backup=chip.parent/f'HYTRON64_PRE_SNAPSHOT_{a.stage}_{stamp}.tar.gz'
with tarfile.open(backup,'x:gz') as tf:
    for name in known:
        if (chip/name).is_file():tf.add(chip/name,arcname=name)
for name in known:
    source=overlay/name;dest=chip/name
    if source.is_file():
        dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(source,dest)
    elif dest.is_file():dest.unlink()
print('BACKUP='+str(backup));print('SNAPSHOT_APPLY=PASS stage='+a.stage)
