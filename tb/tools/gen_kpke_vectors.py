#!/usr/bin/env python3
"""Deterministic M7 K-PKE vectors from the independent FIPS-first model."""
from __future__ import annotations
import argparse
import hashlib
import json
import random
from pathlib import Path

from ref_model.python_model.codec import byte_decode, decompress
from ref_model.python_model.kpke import decrypt, encrypt, generate_matrix, keygen
from ref_model.python_model.ntt import intt, multiply_ntts, ntt
from ref_model.python_model.sampling import sample_ntt, sample_poly_cbd
from ref_model.python_model.symmetric import G, prf

SEED = 0x4D375F4B
Q = 3329


def packed_le(data: bytes) -> str:
    return f"{int.from_bytes(data, 'little'):0{2*len(data)}x}"


def poly_line(poly: list[int]) -> str:
    return " ".join(f"{x:03x}" for x in poly)


def deterministic_inputs() -> list[bytes]:
    rng = random.Random(SEED)
    fixed = [bytes(32), bytes([0xff])*32, bytes(range(32)),
             bytes([0x55,0xaa])*16]
    return fixed + [bytes(rng.randrange(256) for _ in range(32)) for _ in range(16)]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--output-dir", required=True)
    args = ap.parse_args()
    out = Path(args.output_dir)
    out.mkdir(parents=True, exist_ok=True)
    rho_values = deterministic_inputs()[:16]

    with (out / "matrix_rows.mem").open("w") as f:
        for rho in rho_values:
            matrix = generate_matrix(rho)
            for transpose in (0, 1):
                for row in range(3):
                    f.write(f"{packed_le(rho)} {row} {transpose}\n")
                    for elem in range(3):
                        poly = matrix[elem][row] if transpose else matrix[row][elem]
                        f.write(poly_line(poly) + "\n")

    with (out / "noise_vectors.mem").open("w") as f:
        for vector_id, seed in enumerate(deterministic_inputs()[:16]):
            eta = 2 if vector_id < 12 else 3
            start_nonce = (vector_id * 11) & 0xff
            f.write(f"{packed_le(seed)} {start_nonce:02x} {eta}\n")
            for elem in range(3):
                nonce = (start_nonce + elem) & 0xff
                poly = sample_poly_cbd(eta, prf(eta, seed, nonce))
                f.write(poly_line(poly) + "\n")

    cases = []
    messages = [bytes(32), bytes([0xff])*32, bytes([0x55,0xaa])*16,
                bytes(range(32))]
    with (out / "keygen.mem").open("w") as keygen_file:
     for vector_id, d in enumerate(deterministic_inputs()):
        rho, sigma = G(d + b"\x03")
        matrix = generate_matrix(rho)
        s = [sample_poly_cbd(2, prf(2, sigma, nonce)) for nonce in range(3)]
        e = [sample_poly_cbd(2, prf(2, sigma, nonce)) for nonce in range(3, 6)]
        s_hat = [ntt(poly) for poly in s]
        e_hat = [ntt(poly) for poly in e]
        t_hat = []
        for row in range(3):
            acc = [0] * 256
            for col in range(3):
                product = multiply_ntts(matrix[row][col], s_hat[col])
                acc = [(a+b) % Q for a,b in zip(acc, product)]
            t_hat.append([(a+b) % Q for a,b in zip(acc, e_hat[row])])
        ek, dk = keygen(d)
        m = messages[vector_id % len(messages)] if vector_id < 4 else hashlib.sha3_256(b"m"+d).digest()
        r = bytes(32) if vector_id == 0 else (bytes([0xff])*32 if vector_id == 1 else hashlib.sha3_256(b"r"+d).digest())
        c = encrypt(ek, m, r)
        cases.append({
            "id": f"kpke-{vector_id:03d}", "d": d.hex(), "m": m.hex(),
            "r": r.hex(), "ek": ek.hex(), "dk": dk.hex(), "c": c.hex(),
            "decrypted": decrypt(dk, c).hex(),
        })
        keygen_file.write(f"{packed_le(d)} {packed_le(rho)} {packed_le(sigma)}\n")
        for vec in (s, e, s_hat, e_hat, t_hat):
            for poly in vec:
                keygen_file.write(poly_line(poly)+"\n")
        keygen_file.write(" ".join(f"{b:02x}" for b in ek)+"\n")
        keygen_file.write(" ".join(f"{b:02x}" for b in dk)+"\n")
    with (out / "encrypt.mem").open("w") as encrypt_file:
        for case in cases:
            ek = bytes.fromhex(case["ek"]); m = bytes.fromhex(case["m"]); randomness = bytes.fromhex(case["r"])
            t_hat = [byte_decode(12, ek[p*384:(p+1)*384]) for p in range(3)]
            rho = ek[1152:]
            matrix = generate_matrix(rho)
            y = [sample_poly_cbd(2, prf(2, randomness, nonce)) for nonce in range(3)]
            e1 = [sample_poly_cbd(2, prf(2, randomness, nonce)) for nonce in range(3,6)]
            e2 = sample_poly_cbd(2, prf(2, randomness, 6))
            y_hat = [ntt(poly) for poly in y]
            u = []
            for row in range(3):
                acc = [0]*256
                for col in range(3):
                    prod = multiply_ntts(matrix[col][row], y_hat[col])
                    acc = [(a+b)%Q for a,b in zip(acc,prod)]
                u.append([(a+b)%Q for a,b in zip(intt(acc),e1[row])])
            acc = [0]*256
            for p in range(3):
                prod = multiply_ntts(t_hat[p],y_hat[p]);acc=[(a+b)%Q for a,b in zip(acc,prod)]
            mu = [decompress(1,x) for x in byte_decode(1,m)]
            v = [(a+b+c)%Q for a,b,c in zip(intt(acc),e2,mu)]
            encrypt_file.write(" ".join(f"{b:02x}" for b in ek)+"\n")
            encrypt_file.write(f"{packed_le(m)} {packed_le(randomness)} {packed_le(rho)}\n")
            for vec in (t_hat,y,e1,y_hat,u):
                for poly in vec: encrypt_file.write(poly_line(poly)+"\n")
            encrypt_file.write(poly_line(e2)+"\n")
            encrypt_file.write(poly_line(mu)+"\n")
            encrypt_file.write(poly_line(v)+"\n")
            encrypt_file.write(" ".join(f"{b:02x}" for b in bytes.fromhex(case["c"]))+"\n")
    with (out / "decrypt.mem").open("w") as decrypt_file:
        for case in cases:
            dk = bytes.fromhex(case["dk"]); ciphertext = bytes.fromhex(case["c"])
            s_hat = [byte_decode(12,dk[p*384:(p+1)*384]) for p in range(3)]
            u = []
            for p in range(3):
                raw=byte_decode(10,ciphertext[p*320:(p+1)*320]);u.append([decompress(10,x) for x in raw])
            vp=[decompress(4,x) for x in byte_decode(4,ciphertext[960:])]
            u_hat=[ntt(poly) for poly in u];acc=[0]*256
            for p in range(3):
                prod=multiply_ntts(s_hat[p],u_hat[p]);acc=[(a+b)%Q for a,b in zip(acc,prod)]
            product=intt(acc);wpoly=[(a-b)%Q for a,b in zip(vp,product)]
            decrypt_file.write(" ".join(f"{b:02x}" for b in dk)+"\n")
            decrypt_file.write(" ".join(f"{b:02x}" for b in ciphertext)+"\n")
            for vec in (u,s_hat,u_hat):
                for poly in vec: decrypt_file.write(poly_line(poly)+"\n")
            for poly in (vp,product,wpoly): decrypt_file.write(poly_line(poly)+"\n")
            decrypt_file.write(packed_le(bytes.fromhex(case["decrypted"]))+"\n")
    with (out / "roundtrip.mem").open("w") as roundtrip_file:
        for case in cases:
            roundtrip_file.write(f'{packed_le(bytes.fromhex(case["d"]))} {packed_le(bytes.fromhex(case["m"]))} {packed_le(bytes.fromhex(case["r"]))}\n')
            for field in ("ek","dk","c"):
                roundtrip_file.write(" ".join(f"{b:02x}" for b in bytes.fromhex(case[field]))+"\n")
    document = {
        "schema": "m7-kpke-v1", "version": 1,
        "metadata": {
            "parameter_set": "ML-KEM-768", "n": 256, "q": Q, "k": 3,
            "eta1": 2, "eta2": 2, "du": 10, "dv": 4,
            "source": "independent ref_model.python_model; not CAVP/ACVP",
            "seed": f"0x{SEED:08x}",
            "byte_order": "increasing address; earliest stream byte in data[7:0]",
            "coefficient_convention": "canonical unsigned; *_hat is NTT domain",
        },
        "vectors": cases,
    }
    (out / "kpke_vectors.json").write_text(json.dumps(document, sort_keys=True, indent=2)+"\n")
    print("PASS gen_kpke_vectors matrix_rows=96 noise_vectors=16 kpke_vectors=20")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
