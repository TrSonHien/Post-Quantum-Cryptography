#!/usr/bin/env python3
from __future__ import annotations
import argparse,json,random,hashlib
from pathlib import Path
from ref_model.python_model.sampling import sample_ntt
Q=3329;SEED=0x4d365f4e
def group(d1,d2):return (d1&255)|((((d1>>8)&15)|((d2&15)<<4))<<8)|((d2>>4)<<16)
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--output-dir',required=True);a=ap.parse_args();o=Path(a.output_dir);o.mkdir(parents=True,exist_ok=True);r=random.Random(SEED)
 patterns=[[(0,1)],[(3328,3328)],[(3329,0)],[(0,3329)],[(4095,4095),(1,2)],[(3328,3329),(3329,3328)],[(17,19),(3329,3329)],[(Q,Q),(Q+1,Q+2),(3,4)]]
 with (o/'parser.mem').open('w') as f:
  for pat in patterns:
   groups=[];out=[];i=0
   while len(out)<256:
    a1,a2=pat[i%len(pat)];i+=1;groups.append(group(a1,a2))
    if a1<Q:out.append(a1)
    if a2<Q and len(out)<256:out.append(a2)
   f.write(f'{len(groups)}\n');
   for g in groups:f.write(f'{g:06x}\n')
   for x in out:f.write(f'{x:03x}\n')
 stats=[]
 with (o/'sample_ntt.mem').open('w') as f:
  fixed=[(bytes(32),0,0),(bytes([255])*32,0,1),(bytes(range(32)),1,0),(bytes(range(32)),255,255)]
  for v in range(64):
   seed,i0,i1=fixed[v] if v<len(fixed) else (bytes(r.randrange(256) for _ in range(32)),r.randrange(256),r.randrange(256));exp=sample_ntt(seed+bytes([i0,i1]));stream=hashlib.shake_128(seed+bytes([i0,i1])).digest(4096);j=0;acc=[];rej=0
   while len(acc)<256:
    c=stream[3*j:3*j+3];j+=1;d1=c[0]|((c[1]&15)<<8);d2=(c[1]>>4)|(c[2]<<4)
    if d1<Q:acc.append(d1)
    else:rej+=1
    if d2<Q and len(acc)<256:acc.append(d2)
    elif d2>=Q:rej+=1
   assert acc==exp;stats.append((j,rej));f.write(f'{i0:02x} {i1:02x} {int.from_bytes(seed,"little"):064x} {j} {rej}\n');
   for x in exp:f.write(f'{x:03x}\n')
 meta={'schema':'m6-sample-ntt-v1','version':1,'seed':SEED,'vectors':64,'groups_min':min(x for x,_ in stats),'groups_max':max(x for x,_ in stats),'groups_avg_num':sum(x for x,_ in stats),'groups_avg_den':64}
 (o/'sample_ntt_manifest.json').write_text(json.dumps(meta,sort_keys=True,indent=2)+'\n');print(f'PASS gen_sample_ntt_vectors parser=8 sample=64 groups={sum(x for x,_ in stats)}')
if __name__=='__main__':main()
