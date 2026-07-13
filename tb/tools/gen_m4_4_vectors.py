#!/usr/bin/env python3
from __future__ import annotations
import argparse,json,random
from pathlib import Path
from ref_model.python_model.ntt import ntt,intt
from ref_model.python_model.params import Q,N
SEED=0x4D343456;K=3;COUNT=16
def flat(v):return [x for p in v for x in p]
def write(path,blocks):
 with path.open('w',encoding='ascii',newline='\n') as f:
  for vec in blocks:
   for block in vec:
    for x in block:f.write(f'{x:03x}\n')
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--output-dir',required=True);a=ap.parse_args();o=Path(a.output_dir);o.mkdir(parents=True,exist_ok=True);r=random.Random(SEED)
 add=[];sub=[];red=[];nv=[];iv=[];rounds=[]
 for vid in range(COUNT):
  if vid==0:A=[[0]*N for _ in range(K)];B=[[0]*N for _ in range(K)]
  elif vid==1:A=[[Q-1]*N for _ in range(K)];B=[[1]*N for _ in range(K)]
  else:A=[[r.randrange(Q) for _ in range(N)]for _ in range(K)];B=[[r.randrange(Q) for _ in range(N)]for _ in range(K)]
  af,bf=flat(A),flat(B);add.append((af,bf,[(x+y)%Q for x,y in zip(af,bf)]));sub.append((af,bf,[(x-y)%Q for x,y in zip(af,bf)]));red.append((af,af))
  nf=flat([ntt(p) for p in A]);nv.append((af,nf));raw=[[r.randrange(Q) for _ in range(N)]for _ in range(K)];iv.append((flat(raw),flat([intt(p) for p in raw])));rounds.append((af,nf,flat([intt(ntt(p)) for p in A])))
 write(o/'polyvec_add.mem',add);write(o/'polyvec_sub.mem',sub);write(o/'polyvec_reduce.mem',red);write(o/'polyvec_ntt.mem',nv);write(o/'polyvec_intt.mem',iv);write(o/'polyvec_roundtrip.mem',rounds)
 m={'schema':'m4-polyvec-vector-v1','version':1,'seed':SEED,'q':Q,'N':N,'K':K,'count':COUNT,'coefficient_encoding':'canonical_unsigned_integer','operations':['polyvec_add','polyvec_sub','polyvec_reduce','polyvec_ntt','polyvec_intt','polyvec_roundtrip'],'domains':{'normal':1,'ntt':2}}
 (o/'m4_4_vectors.json').write_text(json.dumps(m,sort_keys=True,indent=2)+'\n',encoding='ascii');print('PASS gen_m4_4_vectors operations=6 vectors_each=16');return 0
if __name__=='__main__':raise SystemExit(main())
