#!/usr/bin/env python3
"""Deterministic FIPS-first M8 vectors from the independent Python model."""
from __future__ import annotations
import argparse, hashlib, json
from pathlib import Path
from ref_model.python_model.mlkem import keygen_internal, encaps_internal, decaps_internal
from ref_model.python_model.kpke import decrypt as kpke_decrypt, encrypt as kpke_encrypt
from ref_model.python_model.symmetric import G, H, J

def derive(tag: str, index: int) -> bytes:
    return hashlib.shake_256(f"mlkem-vector-v1:{tag}:{index}".encode()).digest(32)

def hx(x: bytes) -> str: return x.hex()
def write_mem(path: Path, data: bytes) -> None:
    path.write_text("".join(f"{b:02x}\n" for b in data), encoding="ascii")

def main() -> None:
    ap=argparse.ArgumentParser();ap.add_argument("--output-dir",required=True);ap.add_argument("--count",type=int,default=1);a=ap.parse_args()
    out=Path(a.output_dir);out.mkdir(parents=True,exist_ok=True);vectors=[]
    for i in range(a.count):
        # Vector zero is deliberately structured; subsequent vectors are
        # deterministic SHAKE-derived values.  This keeps reduced regressions
        # reproducible while covering both simple and non-patterned inputs.
        if i == 0:
            d=bytes(range(32));z=bytes(range(31,-1,-1));m=bytes([0xa5,0x5a])*16
        else:
            d=derive("d",i);z=derive("z",i);m=derive("m",i)
        ek,dk=keygen_internal(d,z)
        k,c=encaps_internal(ek,m,require_checked_ek=False);recovered=decaps_internal(dk,c,require_checked_inputs=False)
        dkpke=dk[:1152];h=dk[2336:2368];mp=kpke_decrypt(dkpke,c);gout=G(mp+h);kp,rp=gout
        cp=kpke_encrypt(ek,mp,rp);kbar=J(z+c)
        # Four reduced fallback cases cover beginning, middle, end, and a
        # deterministic interior byte; all execute the RTL's full comparison.
        mutation_offsets=(0,len(c)//2,len(c)-1,137)
        bad=bytearray(c);bad[mutation_offsets[i%len(mutation_offsets)]]^=1;bad=bytes(bad);fallback=J(z+bad)
        vectors.append({"schema":"mlkem-vector-v1","operation":"complete_internal_chain","vector_id":f"m8-{i:04d}","parameter_set":"ML-KEM-768","source":f"shake256-index-{i}","byte_order":"increasing-address-low-byte-first","key_layout":{"dkpke":[0,1152],"ek":[1152,2336],"h":[2336,2368],"z":[2368,2400]},"lengths":{"d":32,"z":32,"m":32,"ek":1184,"dk":2400,"c":1088,"k":32},"d":hx(d),"z":hx(z),"m":hx(m),"ek":hx(ek),"dk":hx(dk),"h_ek":hx(H(ek)),"encaps_g_input":hx(m+H(ek)),"encaps_g_output":hx(G(m+H(ek))[0]+G(m+H(ek))[1]),"k":hx(k),"c":hx(c),"decaps_m_prime":hx(mp),"decaps_g_input":hx(mp+h),"decaps_g_output":hx(kp+rp),"k_prime":hx(kp),"r_prime":hx(rp),"j_input":hx(z+c),"k_bar":hx(kbar),"c_prime":hx(cp),"mismatch":c!=cp,"recovered_k":hx(recovered),"modified_c":hx(bad),"modified_expected_k":hx(fallback),"modified_implicit_rejection":True})
        mem_data=(("d",d),("z",z),("m",m),("ek",ek),("dk",dk),("h",H(ek)),("c",c),("k",k),("modified_c",bad),("modified_k",fallback))
        for name,data in mem_data:write_mem(out/f"v{i:04d}_{name}.mem",data)
        if i==0:
            for name,data in mem_data:write_mem(out/f"smoke_{name}.mem",data)
    (out/"mlkem_vectors.json").write_text(json.dumps(vectors,sort_keys=True,separators=(",",":"))+"\n",encoding="utf-8")
    meta={"schema":"mlkem-vector-v1","count":a.count,"parameter_set":"ML-KEM-768","deterministic":True}
    (out/"metadata.json").write_text(json.dumps(meta,sort_keys=True,separators=(",",":"))+"\n",encoding="utf-8")
    print(f"MLKEM_VECTORS={a.count}")
if __name__=="__main__":main()
