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
    for d in (4,10):
        with (out/f'poly_codec_d{d}.mem').open('w') as f:
            for vid in range(64):
                p=[0]*N if vid==0 else [Q-1]*N if vid==1 else [rng.randrange(Q) for _ in range(N)]
                codes=[compress(d,x) for x in p]; enc=byte_encode(d,codes); dec=[decompress(d,x) for x in codes]
                for x in p:f.write(f'{x:03x}\n')
                for i in range(0,len(enc),4):f.write(f'{int.from_bytes(enc[i:i+4],"little"):08x}\n')
                for x in dec:f.write(f'{x:03x}\n')
    with (out/'message_codec.mem').open('w') as f:
        msgs=[bytes(32),bytes([255])*32,bytes(range(32))]
        for bit in range(256):msgs.append((1<<bit).to_bytes(32,'little'))
        while len(msgs)<388:msgs.append(bytes(rng.randrange(256) for _ in range(32)))
        for m in msgs:
            coeff=[decompress(1,x) for x in byte_decode(1,m)]
            for i in range(0,32,4):f.write(f'{int.from_bytes(m[i:i+4],"little"):08x}\n')
            for x in coeff:f.write(f'{x:03x}\n')
    for d,comp in ((12,False),(10,True)):
        with (out/f'polyvec_d{d}.mem').open('w') as f:
            for vid in range(32):
                pv=[[rng.randrange(Q) for _ in range(N)] for _ in range(3)]
                codes=[[compress(d,x) for x in p] for p in pv] if comp else pv
                enc=b''.join(byte_encode(d,p) for p in codes)
                dec=[[decompress(d,x) for x in p] for p in codes] if comp else pv
                for p in pv:
                    for x in p:f.write(f'{x:03x}\n')
                for i in range(0,len(enc),4):f.write(f'{int.from_bytes(enc[i:i+4],"little"):08x}\n')
                for p in dec:
                    for x in p:f.write(f'{x:03x}\n')
    for name,nbytes,split in (("ek",1184,1152),("dk",1152,1152),("ct",1088,960)):
        with (out/f'kpke_{name}.mem').open('w') as f:
            for vid in range(32):
                data=bytes((vid*17+i*29+3)&255 for i in range(nbytes))
                for i in range(0,nbytes,4):f.write(f'{int.from_bytes(data[i:i+4],"little"):08x}\n')
    (out/'codec_manifest.json').write_text(json.dumps(meta,sort_keys=True,indent=2)+'\n')
    print('PASS gen_codec_vectors arrays=272 compress=9987 decompress=1042')
if __name__=='__main__':main()
