#!/usr/bin/env python3
"""Deterministic SHA3/SHAKE byte-stream vectors from hashlib."""
from __future__ import annotations
import argparse,hashlib,json,random
from pathlib import Path
from gen_keccak_round_vectors import selftest,sponge

MODES={0:(136,512,0x06,32,"sha3-256"),1:(72,1024,0x06,64,"sha3-512"),
       2:(168,256,0x1f,None,"shake128"),3:(136,512,0x1f,None,"shake256")}
def digest(mode:int,msg:bytes,n:int)->bytes:
    if mode==0:return hashlib.sha3_256(msg).digest()
    if mode==1:return hashlib.sha3_512(msg).digest()
    if mode==2:return hashlib.shake_128(msg).digest(n)
    return hashlib.shake_256(msg).digest(n)
def hx(data:bytes)->str:return f"{int.from_bytes(data,'little'):x}" if data else "0"
def main()->None:
    p=argparse.ArgumentParser();p.add_argument("--output-dir",type=Path,required=True);a=p.parse_args();a.output_dir.mkdir(parents=True,exist_ok=True)
    selftest();rng=random.Random(0x4d352520);vectors=[];counts={}
    shake_lengths=[1,2,3,4,31,32,33,167,168,169,353]
    for mode,(rate,cap,suffix,fixed,name) in MODES.items():
        messages=[b"",b"abc",b"\x00",bytes(range(256))]
        for n in [0,1,2,3,4,rate-1,rate,rate+1,2*rate-1,2*rate,2*rate+1]:
            messages.append(bytes((i*37+n*11+mode)&255 for i in range(n)))
        while len(messages)<80:
            n=rng.randrange(0,2*rate+38);messages.append(bytes(rng.randrange(256) for _ in range(n)))
        for i,msg in enumerate(messages):
            outlen=fixed if fixed is not None else shake_lengths[i%len(shake_lengths)]
            expected=digest(mode,msg,outlen)
            assert sponge(msg,rate,suffix,outlen)==expected
            vectors.append((mode,len(msg),outlen,hx(msg),hx(expected)))
        counts[name]=len(messages)
    with (a.output_dir/"keccak_hash.vec").open("w",encoding="ascii") as f:
        for v in vectors:f.write("%d %d %d %s %s\n"%v)
    meta={"schema":"keccak-sponge-vector-v1","source":"python-hashlib",
          "cross_check":"pure-python-fips202","deterministic_seed":"0x4d352520",
          "byte_order":"little-endian","lane_order":"x+5*y","counts":counts,
          "modes":[{"mode":m,"name":v[4],"rate":v[0],"capacity":v[1],"suffix":f"{v[2]:02x}"} for m,v in MODES.items()]}
    (a.output_dir/"metadata.json").write_text(json.dumps(meta,sort_keys=True,indent=2)+"\n",encoding="ascii")
    print("SPONGE_VECTOR_STATUS=PASS "+" ".join(f"{k.upper().replace('-','_')}={v}" for k,v in counts.items()))
if __name__=="__main__":main()
