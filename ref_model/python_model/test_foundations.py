"""Unit tests for the M0.4a ML-KEM-768 Python foundations."""

from __future__ import annotations

import unittest

from ref_model.python_model.codec import (
    byte_decode,
    byte_encode,
    bytes_to_bits,
    compress,
    decompress,
)
from ref_model.python_model.kpke import decrypt as kpke_decrypt
from ref_model.python_model.kpke import encrypt as kpke_encrypt
from ref_model.python_model.kpke import generate_matrix, keygen as kpke_keygen
from ref_model.python_model.mlkem import (
    check_ciphertext,
    check_decapsulation_key,
    check_encapsulation_key,
    decaps_internal,
    encaps_internal,
    keygen_internal,
)
from ref_model.python_model.ntt import (
    intt,
    multiply_ntts,
    naive_mul_mod_xn_plus_1,
    ntt,
)
from ref_model.python_model.params import N, Q
from ref_model.python_model.sampling import sample_ntt, sample_poly_cbd
from ref_model.python_model.symmetric import G, H, J, prf, shake128, shake256


class TestCodec(unittest.TestCase):
    def test_bits_little_endian(self) -> None:
        self.assertEqual(bytes_to_bits(bytes([0x8B]))[:8], [1, 1, 0, 1, 0, 0, 0, 1])

    def test_byte_encode_decode(self) -> None:
        for d in (1, 4, 10, 12):
            modulus = Q if d == 12 else 1 << d
            coeffs = [(17 * i + 9) % modulus for i in range(N)]
            self.assertEqual(byte_decode(d, byte_encode(d, coeffs)), coeffs)

    def test_compress_decompress_identity(self) -> None:
        for d in (1, 4, 10):
            for y in range(1 << d):
                self.assertEqual(compress(d, decompress(d, y)), y)


class TestSymmetric(unittest.TestCase):
    def test_lengths(self) -> None:
        self.assertEqual(len(H(b"x")), 32)
        g0, g1 = G(b"x")
        self.assertEqual((len(g0), len(g1)), (32, 32))
        self.assertEqual(len(J(b"x")), 32)
        self.assertEqual(len(shake128(b"x", 17)), 17)
        self.assertEqual(len(shake256(b"x", 19)), 19)
        self.assertEqual(len(prf(2, b"\x00" * 32, 0)), 128)


class TestNTT(unittest.TestCase):
    def test_roundtrip(self) -> None:
        poly = [(i * i + 3 * i + 5) % Q for i in range(N)]
        self.assertEqual(intt(ntt(poly)), poly)

    def test_multiplication_property(self) -> None:
        f = [(7 * i + 1) % Q for i in range(N)]
        g = [(11 * i * i + 2) % Q for i in range(N)]
        self.assertEqual(intt(multiply_ntts(ntt(f), ntt(g))), naive_mul_mod_xn_plus_1(f, g))


class TestSampling(unittest.TestCase):
    def test_sample_ntt_shape(self) -> None:
        out = sample_ntt(b"A" * 32 + b"\x00\x01")
        self.assertEqual(len(out), N)
        self.assertTrue(all(0 <= x < Q for x in out))

    def test_sample_poly_cbd_shape(self) -> None:
        out = sample_poly_cbd(2, bytes(range(128)))
        self.assertEqual(len(out), N)
        self.assertTrue(all((0 <= x <= 2) or (Q - 2 <= x < Q) for x in out))


class TestKpkeAndMlkemInternal(unittest.TestCase):
    def test_matrix_transposition_order_observable(self) -> None:
        rho = bytes(range(32))
        matrix = generate_matrix(rho)
        self.assertEqual(matrix[0][1], generate_matrix(rho)[0][1])
        self.assertNotEqual(matrix[0][1], matrix[1][0])

    def test_kpke_deterministic_roundtrip(self) -> None:
        d = bytes(range(32))
        m = bytes(range(32, 64))
        r = bytes(range(64, 96))
        ek, dk = kpke_keygen(d)
        ciphertext = kpke_encrypt(ek, m, r)
        self.assertEqual(kpke_decrypt(dk, ciphertext), m)

    def test_mlkem_internal_success(self) -> None:
        d = bytes(range(32))
        z = bytes(range(32, 64))
        m = bytes(range(64, 96))
        ek, dk = keygen_internal(d, z)
        self.assertTrue(check_encapsulation_key(ek))
        self.assertTrue(check_decapsulation_key(dk))
        shared_secret, ciphertext = encaps_internal(ek, m)
        self.assertTrue(check_ciphertext(ciphertext))
        self.assertEqual(decaps_internal(dk, ciphertext), shared_secret)

    def test_modified_ciphertext_selects_fallback(self) -> None:
        d = bytes(range(32))
        z = bytes(range(32, 64))
        m = bytes(range(64, 96))
        ek, dk = keygen_internal(d, z)
        _, ciphertext = encaps_internal(ek, m)
        modified = bytearray(ciphertext)
        modified[-1] ^= 0x01
        modified_ct = bytes(modified)
        self.assertEqual(decaps_internal(dk, modified_ct), J(z + modified_ct))

    def test_input_checks_reject_bad_key_and_ciphertext(self) -> None:
        d = bytes(range(32))
        z = bytes(range(32, 64))
        ek, dk = keygen_internal(d, z)
        bad_ek = bytearray(ek)
        bad_ek[0] = 0xFF
        bad_ek[1] = 0xFF
        self.assertFalse(check_encapsulation_key(bytes(bad_ek)))
        self.assertFalse(check_decapsulation_key(dk[:-1]))
        self.assertFalse(check_ciphertext(b"short"))


if __name__ == "__main__":
    unittest.main()
