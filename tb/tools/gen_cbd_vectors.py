#!/usr/bin/env python3
from __future__ import annotations
import argparse,json,random,hashlib
from pathlib import Path
from ref_model.python_model.sampling import sample_poly_cbd
from ref_model.python_model.symmetric import prf
Q=3329;SEED=0x4d365f53
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--output-dir',required=True);a=ap.parse_args();o=Path(a.output_dir);o.mkdir(parents=True,exist_ok=True);r=random.Random(SEED)
 with (o/'cbd_pair.mem').open('w') as f:
  for eta,limit in ((2,256),(3,4096)):
   for bits in range(limit):
    mask=(1<<eta)-1;x0=(bits&mask).bit_count();y0=((bits>>eta)&mask).bit_count();x1=((bits>>(2*eta))&mask).bit_count();y1=((bits>>(3*eta))&mask).bit_count()
    f.write(f'{eta} {bits:03x} {(x0-y0)%Q:03x} {(x1-y1)%Q:03x}\n')
 for eta in (2,3):
  with (o/f'cbd_eta{eta}.mem').open('w') as f:
   for v in range(128):
    data=bytes(64*eta) if v==0 else bytes([255])*(64*eta) if v==1 else bytes(r.randrange(256) for _ in range(64*eta));exp=sample_poly_cbd(eta,data)
    for i in range(0,len(data),4):f.write(f'{int.from_bytes(data[i:i+4],"little"):08x}\n')
    for x in exp:f.write(f'{x:03x}\n')
 with (o/'noise.mem').open('w') as f:
  for v in range(128):
   eta=2 if v<64 else 3;seed=bytes(32) if v%64==0 else bytes([255])*32 if v%64==1 else bytes(r.randrange(256) for _ in range(32));nonce=(v*37)&255;exp=sample_poly_cbd(eta,prf(eta,seed,nonce))
   f.write(f'{eta} {nonce:02x} {int.from_bytes(seed,"little"):064x}\n');
   for x in exp:f.write(f'{x:03x}\n')
 meta={'schema':'m6-cbd-v1','version':1,'seed':SEED,'eta2_vectors':128,'eta3_vectors':128,'noise_vectors':128}
 (o/'cbd_manifest.json').write_text(json.dumps(meta,sort_keys=True,indent=2)+'\n');print('PASS gen_cbd_vectors pair=4352 cbd=256 noise=128')
if __name__=='__main__':main()
