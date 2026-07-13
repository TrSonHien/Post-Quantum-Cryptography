#!/usr/bin/env python3
from __future__ import annotations
import argparse, json, random
from pathlib import Path
from ref_model.python_model.codec import byte_decode, byte_encode, compress, decompress
from ref_model.python_model.params import Q, N

SEED=0x4d365f43

def arrays(d:int, rng:random.Random):
    m=Q if d==12 else 1<<d
    a=[[0]*N,[m-1]*N,[i%m for i in range(N)],[(i&1)*(m-1) for i in range(N)]]
    while len(a)<68:a.append([rng.randrange(m) for _ in range(N)])
    return a

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--output-dir',required=True);a=ap.parse_args()
    out=Path(a.output_dir);out.mkdir(parents=True,exist_ok=True);rng=random.Random(SEED)
    with (out/'compress.mem').open('w') as f:
        for d in (1,4,10):
            for x in range(Q):f.write(f'{d} {x:03x} {compress(d,x):03x}\n')
    with (out/'decompress.mem').open('w') as f:
        for d in (1,4,10):
            for y in range(1<<d):
                assert compress(d,decompress(d,y)) == y
                f.write(f'{d} {y:03x} {decompress(d,y):03x}\n')
    meta={"schema":"m6-codec-v1","version":1,"seed":SEED,"q":Q,"n":N,
          "byte_order":"increasing_address","bit_order":"least_significant_first","vectors":{}}
    for d in (1,4,10,12):
        aa=arrays(d,rng)
        with (out/f'encode_d{d}.mem').open('w') as f:
            for v in aa:
                enc=byte_encode(d,v)
                for x in v:f.write(f'{x:03x}\n')
                for i in range(0,len(enc),4):f.write(f'{int.from_bytes(enc[i:i+4],"little"):08x}\n')
        with (out/f'decode_d{d}.mem').open('w') as f:
            for v in aa:
                enc=byte_encode(d,v)
                for i in range(0,len(enc),4):f.write(f'{int.from_bytes(enc[i:i+4],"little"):08x}\n')
                for x in v:f.write(f'{x:03x}\n')
        meta['vectors'][f'd{d}']={"count":len(aa),"output_bytes":32*d}
    raw=[0,Q-1,Q,Q+1,4095]+[(37*i+19)&4095 for i in range(N-5)]
    bits=sum((x<<(12*i) for i,x in enumerate(raw)))
    enc=bits.to_bytes(384,'little')
    with (out/'decode_d12_noncanonical.mem').open('w') as f:
        for i in range(0,384,4):f.write(f'{int.from_bytes(enc[i:i+4],"little"):08x}\n')
        for x in raw:f.write(f'{x%Q:03x}\n')
    (out/'codec_manifest.json').write_text(json.dumps(meta,sort_keys=True,indent=2)+'\n')
    print('PASS gen_codec_vectors arrays=272 compress=9987 decompress=1042')
if __name__=='__main__':main()
