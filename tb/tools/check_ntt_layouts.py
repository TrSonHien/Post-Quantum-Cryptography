#!/usr/bin/env python3
"""Exhaustively prove the committed forward and reversed inverse NTT layouts."""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class Layout:
    pair_bit: int
    addr_bit: int
    xor_layout: bool

    def physical(self, index: int) -> tuple[int, int]:
        bank = ((index >> self.pair_bit) ^
                ((index >> self.addr_bit) if self.xor_layout else 0)) & 1
        low = index & ((1 << self.addr_bit) - 1)
        high = index >> (self.addr_bit + 1)
        return bank, low | (high << self.addr_bit)

    def label(self) -> str:
        bank = f"i{self.pair_bit}"
        if self.xor_layout:
            bank += f"^i{self.addr_bit}"
        return f"b={bank},a=rm{self.addr_bit}"


FORWARD = (
    Layout(7, 7, False),
    Layout(7, 6, True),
    Layout(6, 5, True),
    Layout(5, 4, True),
    Layout(4, 3, True),
    Layout(3, 2, True),
    Layout(2, 1, True),
    Layout(1, 1, False),
)
INVERSE = tuple(reversed(FORWARD))


def prove_layout(layout: Layout) -> None:
    locations = {layout.physical(index) for index in range(256)}
    assert len(locations) == 256
    assert locations == {(bank, addr) for bank in range(2) for addr in range(128)}


def prove_stage(source: Layout, destination: Layout, pair_bit: int) -> None:
    writes: set[tuple[int, int]] = set()
    for base in range(256):
        if (base >> pair_bit) & 1:
            continue
        other = base ^ (1 << pair_bit)
        assert source.physical(base)[0] != source.physical(other)[0]
        assert destination.physical(base)[0] != destination.physical(other)[0]
        writes.add(destination.physical(base))
        writes.add(destination.physical(other))
    assert len(writes) == 256


def main() -> int:
    for layout in set(FORWARD):
        prove_layout(layout)

    print("direction stage pair_bit source destination")
    for stage in range(7):
        pair_bit = 7 - stage
        prove_stage(FORWARD[stage], FORWARD[stage + 1], pair_bit)
        print(f"forward {stage} {pair_bit} {FORWARD[stage].label()} "
              f"{FORWARD[stage + 1].label()}")

    for stage in range(7):
        pair_bit = stage + 1
        prove_stage(INVERSE[stage], INVERSE[stage + 1], pair_bit)
        print(f"inverse {stage} {pair_bit} {INVERSE[stage].label()} "
              f"{INVERSE[stage + 1].label()}")

    print("PASS check_ntt_layouts layouts=8 forward_requests=896 inverse_requests=896")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
