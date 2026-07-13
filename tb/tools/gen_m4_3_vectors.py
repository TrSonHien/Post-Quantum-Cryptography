#!/usr/bin/env python3
from __future__ import annotations
import argparse, json, random
from pathlib import Path
from ref_model.python_model.ntt import base_case_multiply, multiply_ntts
from ref_model.python_model.params import N, Q

SEED = 0x4D343342

def main() -> int:
    ap=argparse.ArgumentParser();ap.add_argument("--output-dir",required=True);a=ap.parse_args()
    out=Path(a.output_dir);out.mkdir(parents=True,exist_ok=True);rng=random.Random(SEED)
    pairs=[]
    edge=[0,1,Q-2,Q-1]
    for x in edge:
        for y in edge:pairs.append((x,y))
    while len(pairs)<100000:pairs.append((rng.randrange(Q),rng.randrange(Q)))
    with (out/"mod_mul_normal.mem").open("w",encoding="ascii",newline="\n") as f:
        for x,y in pairs:f.write(f"{x:03x} {y:03x} {(x*y)%Q:03x}\n")
    tuples=[(0,0,0,0,0),(1,0,1,0,0),(Q-1,Q-1,Q-1,Q-1,Q-1)]
    while len(tuples)<50000:tuples.append(tuple(rng.randrange(Q) for _ in range(5)))
    with (out/"basecase.mem").open("w",encoding="ascii",newline="\n") as f:
        for t in tuples:
            c=base_case_multiply(*t);f.write(" ".join(f"{x:03x}" for x in (*t,*c))+"\n")
    vectors=[]
    for vid in range(32):
        if vid==0:a0=[0]*N;b0=[0]*N;name="zero"
        elif vid==1:a0=[1]*N;b0=[1]*N;name="one"
        elif vid==2:a0=[Q-1]*N;b0=[Q-1]*N;name="q_minus_1"
        elif vid<10:
            a0=[0]*N;b0=[0]*N;a0[(vid-3)*31%N]=1;b0[(vid-3)*47%N]=1;name=f"impulse_{vid}"
        elif vid==10:a0=[i%Q for i in range(N)];b0=[(7*i+3)%Q for i in range(N)];name="pattern"
        else:a0=[rng.randrange(Q) for _ in range(N)];b0=[rng.randrange(Q) for _ in range(N)];name=f"random_{vid}"
        vectors.append((name,a0,b0,multiply_ntts(a0,b0)))
    with (out/"poly_basemul.mem").open("w",encoding="ascii",newline="\n") as f:
        for vid,(name,x,y,z) in enumerate(vectors):
            for block in (x,y,z):
                for v in block:f.write(f"{v:03x}\n")
    manifest={"schema":"m4-multiply-ntts-v1","version":1,"seed":SEED,"q":Q,"N":N,
      "coefficient_encoding":"canonical_unsigned_integer","operations":{
       "mod_mul_normal":{"count":len(pairs),"input_domain":"mathematical_residue","output_domain":"mathematical_residue"},
       "base_case_multiply":{"count":len(tuples),"gamma_domain":"mathematical_residue","output_domain":"ntt"},
       "multiply_ntts":{"count":len(vectors),"input_domain":"ntt","output_domain":"ntt"}}}
    (out/"m4_3_vectors.json").write_text(json.dumps(manifest,sort_keys=True,indent=2)+"\n",encoding="ascii")
    print("PASS gen_m4_3_vectors mul=100000 basecase=50000 poly=32")
    return 0
if __name__=="__main__":raise SystemExit(main())
