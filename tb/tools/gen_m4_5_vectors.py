#!/usr/bin/env python3
from __future__ import annotations
import argparse,json,random
from pathlib import Path
from ref_model.python_model.ntt import multiply_ntts
from ref_model.python_model.params import Q,N
SEED=0x4D343541;K=3;COUNT=32
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--output-dir',required=True);a=ap.parse_args();o=Path(a.output_dir);o.mkdir(parents=True,exist_ok=True);r=random.Random(SEED);vectors=[]
 for vid in range(COUNT):
  if vid==0:A=[[0]*N for _ in range(K)];B=[[0]*N for _ in range(K)]
  elif vid==1:A=[[1]*N for _ in range(K)];B=[[1]*N for _ in range(K)]
  elif vid==2:A=[[Q-1]*N for _ in range(K)];B=[[Q-1]*N for _ in range(K)]
  elif vid==3:A=[[0]*N for _ in range(K)];B=[[0]*N for _ in range(K)];A[1][0]=1;B[1][0]=1
  else:A=[[r.randrange(Q)for _ in range(N)]for _ in range(K)];B=[[r.randrange(Q)for _ in range(N)]for _ in range(K)]
  P=[multiply_ntts(A[k],B[k])for k in range(K)];acc1=[(P[0][i]+P[1][i])%Q for i in range(N)];out=[(acc1[i]+P[2][i])%Q for i in range(N)];vectors.append(([x for p in A for x in p],[x for p in B for x in p],out))
 with (o/'polyvec_basemul_acc.mem').open('w',encoding='ascii',newline='\n')as f:
  for v in vectors:
   for b in v:
    for x in b:f.write(f'{x:03x}\n')
 m={'schema':'m4-polyvec-basemul-acc-v1','version':1,'seed':SEED,'q':Q,'N':N,'K':K,'count':COUNT,'input_domain':'ntt','output_domain':'ntt','coefficient_encoding':'canonical_unsigned_integer'}
 (o/'m4_5_vectors.json').write_text(json.dumps(m,sort_keys=True,indent=2)+'\n',encoding='ascii');print('PASS gen_m4_5_vectors vectors=32');return 0
if __name__=='__main__':raise SystemExit(main())
