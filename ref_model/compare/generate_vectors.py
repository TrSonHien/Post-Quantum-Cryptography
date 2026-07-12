"""Generate deterministic ML-KEM-768 smoke vectors from the Python oracle."""

from __future__ import annotations

import argparse

from ref_model.compare.vector_schema import SCHEMA, write_document
from ref_model.python_model.codec import byte_decode, byte_encode, compress, decompress
from ref_model.python_model.kpke import decrypt, encrypt, keygen
from ref_model.python_model.mlkem import decaps_internal, encaps_internal, keygen_internal
from ref_model.python_model.ntt import intt, multiply_ntts, ntt
from ref_model.python_model.params import DU, DV, ETA1, ETA2, K, N, Q
from ref_model.python_model.sampling import sample_ntt, sample_poly_cbd

DEFAULT_SEED = bytes(range(32))
GENERATION_COMMAND = (
    "python3 -m ref_model.compare.generate_vectors "
    "--output ref_model/compare/vectors/mlkem768_smoke.json"
)


def _poly(multiplier: int, offset: int) -> list[int]:
    return [(multiplier * i + offset) % Q for i in range(N)]


def build_document(seed: bytes = DEFAULT_SEED) -> dict:
    if len(seed) != 32:
        raise ValueError("generation seed must be 32 bytes")
    poly = _poly(17, 9)
    other = _poly(29, 5)
    encoded = byte_encode(12, poly)
    transformed = ntt(poly)
    other_transformed = ntt(other)
    sample_input = seed + b"\x01\x02"
    cbd_input = bytes((x * 13 + 7) & 0xFF for x in range(128))
    d = seed
    z = bytes((x + 32) & 0xFF for x in seed)
    message = bytes((x + 64) & 0xFF for x in seed)
    randomness = bytes((x + 96) & 0xFF for x in seed)
    ek_pke, dk_pke = keygen(d)
    pke_ciphertext = encrypt(ek_pke, message, randomness)
    ek, dk = keygen_internal(d, z)
    shared_secret, ciphertext = encaps_internal(ek, message)
    modified = ciphertext[:-1] + bytes([ciphertext[-1] ^ 1])

    def case(identifier: str, category: str, operation: str, inputs: dict, expected: dict) -> dict:
        return {"id": identifier, "category": category, "operation": operation,
                "inputs": inputs, "expected": expected}

    vectors = [
        case("arithmetic-compress-10", "arithmetic", "Compress_10/Decompress_10",
             {"coefficient": 1729},
             {"compressed": compress(10, 1729), "decompressed": decompress(10, compress(10, 1729))}),
        case("codec-byteencode-12", "codec", "ByteEncode_12/ByteDecode_12",
             {"coefficients": poly}, {"encoded_hex": encoded.hex(), "decoded": byte_decode(12, encoded)}),
        case("ntt-roundtrip", "ntt", "NTT/INTT", {"coefficients": poly},
             {"ntt": transformed, "intt": intt(transformed)}),
        case("multiply-ntts", "multiply_ntts", "MultiplyNTTs",
             {"f_hat": transformed, "g_hat": other_transformed},
             {"product_hat": multiply_ntts(transformed, other_transformed)}),
        case("sampling-samplentt", "sampling", "SampleNTT",
             {"input_hex": sample_input.hex()}, {"coefficients": sample_ntt(sample_input)}),
        case("sampling-cbd2", "sampling", "SamplePolyCBD_eta2",
             {"input_hex": cbd_input.hex()}, {"coefficients": sample_poly_cbd(2, cbd_input)}),
        case("kpke-deterministic", "kpke", "K-PKE.KeyGen/Encrypt/Decrypt",
             {"d_hex": d.hex(), "m_hex": message.hex(), "r_hex": randomness.hex()},
             {"ek_hex": ek_pke.hex(), "dk_hex": dk_pke.hex(),
              "ciphertext_hex": pke_ciphertext.hex(), "decrypted_hex": decrypt(dk_pke, pke_ciphertext).hex()}),
        case("mlkem-deterministic", "mlkem", "ML-KEM internal algorithms",
             {"d_hex": d.hex(), "z_hex": z.hex(), "m_hex": message.hex()},
             {"ek_hex": ek.hex(), "dk_hex": dk.hex(), "ciphertext_hex": ciphertext.hex(),
              "shared_secret_hex": shared_secret.hex(),
              "decapsulated_hex": decaps_internal(dk, ciphertext).hex(),
              "modified_ciphertext_hex": modified.hex(),
              "fallback_secret_hex": decaps_internal(dk, modified).hex()}),
    ]
    return {
        "schema": SCHEMA,
        "metadata": {
            "algorithm": "FIPS 203 deterministic internal algorithms",
            "parameter_set": "ML-KEM-768",
            "parameters": {"n": N, "q": Q, "k": K, "eta1": ETA1, "eta2": ETA2, "du": DU, "dv": DV},
            "source": "ref_model/python_model independent FIPS 203 model; not CAVP/ACVP validated",
            "seed": seed.hex(),
            "generation_command": GENERATION_COMMAND,
            "byte_order": "hex bytes in increasing address order; ByteEncode bits are least-significant-bit first",
            "coefficient_representation": "canonical unsigned integers in [0,3328]; normal domain except explicit *_hat NTT values",
        },
        "vectors": vectors,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True)
    parser.add_argument("--seed", default=DEFAULT_SEED.hex())
    args = parser.parse_args()
    try:
        seed = bytes.fromhex(args.seed)
    except ValueError as exc:
        parser.error(f"invalid --seed hex: {exc}")
    write_document(build_document(seed), args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
