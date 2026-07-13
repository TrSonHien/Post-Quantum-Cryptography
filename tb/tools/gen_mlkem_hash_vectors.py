#!/usr/bin/env python3
from __future__ import annotations
import argparse,hashlib,json,random
from pathlib import Path
def hx(b:bytes)->str:return f"{int.from_bytes(b,'little'):x}" if b else "0"
def main()->None:
 p=argparse.ArgumentParser();p.add_argument("--output-dir",type=Path,required=True);a=p.parse_args();a.output_dir.mkdir(parents=True,exist_ok=True);r=random.Random(0x4d355203)
 hgj=[]
 for mode in (0,1,3):
  for i in range(80):
   n=[0,1,2,3,4,71,72,73,135,136,137,167,168,169,255,256][i%16] if i<16 else r.randrange(0,360)
   msg=bytes((r.randrange(256) for _ in range(n)))
   out=hashlib.sha3_256(msg).digest() if mode==0 else hashlib.sha3_512(msg).digest() if mode==1 else hashlib.shake_256(msg).digest(32)
   hgj.append((mode,n,len(out),hx(msg),hx(out)))
 with (a.output_dir/"mlkem_hgj.vec").open("w") as f:
  for v in hgj:f.write("%d %d %d %s %s\n"%v)
 prf=[]
 fixed=[bytes(32),bytes([255])*32,bytes(range(32))]
 for i in range(128):
  eta=2+(i&1);seed=fixed[i%3] if i<9 else bytes(r.randrange(256) for _ in range(32));nonce=[0,1,255][i%3]
  out=hashlib.shake_256(seed+bytes([nonce])).digest(64*eta);prf.append((eta,nonce,hx(seed),hx(out)))
 with (a.output_dir/"mlkem_prf.vec").open("w") as f:
  for v in prf:f.write("%d %d %s %s\n"%v)
 xof=[];lengths=[3,168,171,353,1,2,31,32,33]
 for i in range(64):
  seed=bytes(32) if i==0 else bytes([255])*32 if i==1 else bytes(range(32)) if i==2 else bytes(r.randrange(256) for _ in range(32));i0=(i*17)&255;i1=(255-i*29)&255;n=lengths[i%len(lengths)];out=hashlib.shake_128(seed+bytes([i0,i1])).digest(n);xof.append((i0,i1,n,hx(seed),hx(out)))
 with (a.output_dir/"mlkem_xof.vec").open("w") as f:
  for v in xof:f.write("%d %d %d %s %s\n"%v)
 meta={"schema":"mlkem-hash-vector-v1","source":"python-hashlib","seed":"0x4d355203","byte_order":"little-endian","h":80,"g":80,"j":80,"prf":128,"xof":64}
 (a.output_dir/"metadata.json").write_text(json.dumps(meta,sort_keys=True,indent=2)+"\n")
 print("MLKEM_HASH_VECTOR_STATUS=PASS H=80 G=80 J=80 PRF=128 XOF=64")
if __name__=="__main__":main()
