#!/usr/bin/env python3
"""Independent deterministic Keccak round/permutation/vector tooling."""

from __future__ import annotations

import argparse
import hashlib
import json
import random
from pathlib import Path

MASK64 = (1 << 64) - 1
RC = [
    0x0000000000000001,0x0000000000008082,0x800000000000808A,
    0x8000000080008000,0x000000000000808B,0x0000000080000001,
    0x8000000080008081,0x8000000000008009,0x000000000000008A,
    0x0000000000000088,0x0000000080008009,0x000000008000000A,
    0x000000008000808B,0x800000000000008B,0x8000000000008089,
    0x8000000000008003,0x8000000000008002,0x8000000000000080,
    0x000000000000800A,0x800000008000000A,0x8000000080008081,
    0x8000000000008080,0x0000000080000001,0x8000000080008008,
]
RHO = [
     0, 1,62,28,27, 36,44, 6,55,20, 3,10,43,25,39,
    41,45,15,21, 8, 18, 2,61,56,14,
]

def rol(v: int, n: int) -> int:
    return v if n == 0 else ((v << n) | (v >> (64 - n))) & MASK64

def round_trace(state: list[int], rnd: int) -> dict[str, list[int] | int]:
    a = state[:]
    c = [a[x] ^ a[x+5] ^ a[x+10] ^ a[x+15] ^ a[x+20] for x in range(5)]
    d = [c[(x-1)%5] ^ rol(c[(x+1)%5], 1) for x in range(5)]
    theta = [a[x+5*y] ^ d[x] for y in range(5) for x in range(5)]
    b = [0] * 25
    for y in range(5):
        for x in range(5):
            b[y + 5*((2*x+3*y)%5)] = rol(theta[x+5*y], RHO[x+5*y])
    chi = [0] * 25
    for y in range(5):
        for x in range(5):
            chi[x+5*y] = b[x+5*y] ^ ((~b[(x+1)%5+5*y]) & b[(x+2)%5+5*y] & MASK64)
    out = chi[:]
    out[0] ^= RC[rnd]
    return {"c":c,"d":d,"theta":theta,"rho_pi":b,"chi":chi,"rc":RC[rnd],"out":out}

def keccak_round(state: list[int], rnd: int) -> list[int]:
    return round_trace(state, rnd)["out"]  # type: ignore[return-value]

def permute(state: list[int]) -> list[int]:
    for rnd in range(24):
        state = keccak_round(state, rnd)
    return state

def lanes_to_int(lanes: list[int]) -> int:
    return sum(v << (64*i) for i, v in enumerate(lanes))

def int_to_lanes(value: int) -> list[int]:
    return [(value >> (64*i)) & MASK64 for i in range(25)]

def sponge(data: bytes, rate: int, suffix: int, out_len: int) -> bytes:
    state = [0] * 25
    offset = 0
    for value in data:
        state[offset//8] ^= value << (8*(offset%8))
        offset += 1
        if offset == rate:
            state = permute(state)
            offset = 0
    state[offset//8] ^= suffix << (8*(offset%8))
    state[(rate-1)//8] ^= 0x80 << (8*((rate-1)%8))
    state = permute(state)
    output = bytearray()
    offset = 0
    while len(output) < out_len:
        if offset == rate:
            state = permute(state)
            offset = 0
        output.append((state[offset//8] >> (8*(offset%8))) & 0xff)
        offset += 1
    return bytes(output)

def selftest() -> None:
    cases = [b"", b"abc", bytes(range(256)), bytes((i*29+7)&255 for i in range(337))]
    for data in cases:
        assert sponge(data,136,0x06,32) == hashlib.sha3_256(data).digest()
        assert sponge(data,72,0x06,64) == hashlib.sha3_512(data).digest()
        assert sponge(data,168,0x1f,401) == hashlib.shake_128(data).digest(401)
        assert sponge(data,136,0x1f,401) == hashlib.shake_256(data).digest(401)

def write_round(path: Path) -> int:
    rng = random.Random(0x4d35201)
    vectors: list[tuple[int,int]] = []
    for rnd in range(24):
        vectors.extend([(rnd,0),(rnd,(1<<1600)-1)])
        lanes = [((rnd+1)<<56) ^ (i*0x0101010101010101) for i in range(25)]
        vectors.append((rnd,lanes_to_int(lanes)))
    for bit in range(1600):
        vectors.append((bit%24,1<<bit))
    for i in range(400):
        vectors.append((i%24,rng.getrandbits(1600)))
    with path.open("w", encoding="ascii") as f:
        for rnd, value in vectors:
            out = lanes_to_int(keccak_round(int_to_lanes(value),rnd))
            f.write(f"{rnd} {value:0400x} {out:0400x}\n")
    return len(vectors)

def write_perm(path: Path) -> int:
    rng = random.Random(0x4d351600)
    values = [0,(1<<1600)-1,lanes_to_int(list(range(25))),
              lanes_to_int([i*0x0101010101010101 & MASK64 for i in range(25)])]
    values += [rng.getrandbits(1600) for _ in range(128)]
    with path.open("w", encoding="ascii") as f:
        for value in values:
            out=lanes_to_int(permute(int_to_lanes(value)))
            f.write(f"{value:0400x} {out:0400x}\n")
    return len(values)

def write_trace(path: Path) -> int:
    rng=random.Random(0x4d35face)
    with path.open("w",encoding="ascii") as f:
        for rnd in range(24):
            value=rng.getrandbits(1600);tr=round_trace(int_to_lanes(value),rnd)
            fields=[str(rnd),f"{value:0400x}"]
            fields += [f"{v:016x}" for v in tr["c"]]  # type: ignore[index]
            fields += [f"{v:016x}" for v in tr["d"]]  # type: ignore[index]
            for name in ("theta","rho_pi","chi","out"):
                fields.append(f"{lanes_to_int(tr[name]):0400x}")  # type: ignore[arg-type,index]
            f.write(" ".join(fields)+"\n")
    return 24

def write_metadata(path: Path, round_count: int, perm_count: int) -> None:
    obj={"schema":"keccak-m5-vector-v1","source":"pure-python-fips202",
         "deterministic_seed":"0x4d35201/0x4d351600","byte_order":"little-endian",
         "lane_order":"x+5*y","round_vectors":round_count,"permutation_vectors":perm_count,
         "round_constants":[f"{v:016x}" for v in RC],"rho_offsets":RHO}
    path.write_text(json.dumps(obj,sort_keys=True,indent=2)+"\n",encoding="ascii")

def main() -> None:
    p=argparse.ArgumentParser();p.add_argument("--output-dir",type=Path,required=True)
    args=p.parse_args();args.output_dir.mkdir(parents=True,exist_ok=True);selftest()
    nr=write_round(args.output_dir/"keccak_round.vec")
    np=write_perm(args.output_dir/"keccak_perm.vec")
    write_trace(args.output_dir/"keccak_trace.vec")
    write_metadata(args.output_dir/"metadata.json",nr,np)
    print(f"KECCAK_VECTOR_STATUS=PASS ROUND_VECTORS={nr} PERMUTATION_VECTORS={np}")
if __name__ == "__main__": main()
