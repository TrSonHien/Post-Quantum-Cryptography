# M3 Banked Fmax-oriented NTT/INTT Engine Plan

## 1. Forward and Inverse NTT Stage Schedules

### 1.1 Forward NTT Stage Schedule
The forward NTT uses Cooley-Tukey (decimation-in-time) radix-2 butterflies.
For stage $s \in [0, 6]$:
*   $\text{len} = 2^{7-s}$ (decreases from 128 to 2).
*   $\text{start}$ increments by $2 \cdot \text{len}$ from 0 to 256.
*   Zeta changes once per group (not per butterfly). The twiddle factor $\zeta_{mont}$ is read from `zetas_rom` (forward table `inverse = 0`) using `zeta_addr`.
*   Group count and butterflies-per-zeta (length):
    *   **Stage 1**: 1 group, 128 butterflies per zeta. `zeta_addr` = 1.
    *   **Stage 2**: 2 groups, 64 butterflies per zeta. `zeta_addr` sweeps 2..3.
    *   **Stage 3**: 4 groups, 32 butterflies per zeta. `zeta_addr` sweeps 4..7.
    *   **Stage 4**: 8 groups, 16 butterflies per zeta. `zeta_addr` sweeps 8..15.
    *   **Stage 5**: 16 groups, 8 butterflies per zeta. `zeta_addr` sweeps 16..31.
    *   **Stage 6**: 32 groups, 4 butterflies per zeta. `zeta_addr` sweeps 32..63.
    *   **Stage 7**: 64 groups, 2 butterflies per zeta. `zeta_addr` sweeps 64..127.

### 1.2 Inverse NTT Stage Schedule (Option A)
The inverse NTT uses Gentleman-Sande (decimation-in-frequency) radix-2 butterflies. To map the FIPS-required twiddle factor order, we address the forward table (`inverse = 0`) in descending order:
*   $\text{len} = 2^{s+1}$ (increases from 2 to 128).
*   $\text{start}$ increments by $2 \cdot \text{len}$ from 0 to 256.
*   Zeta changes once per group (not per butterfly).
*   Group count and butterflies-per-zeta (length):
    *   **Stage 1**: 64 groups, 2 butterflies per zeta. `zeta_addr` sweeps 127 down to 64.
    *   **Stage 2**: 32 groups, 4 butterflies per zeta. `zeta_addr` sweeps 63 down to 32.
    *   **Stage 3**: 16 groups, 8 butterflies per zeta. `zeta_addr` sweeps 31 down to 16.
    *   **Stage 4**: 8 groups, 16 butterflies per zeta. `zeta_addr` sweeps 15 down to 8.
    *   **Stage 5**: 4 groups, 32 butterflies per zeta. `zeta_addr` sweeps 7 down to 4.
    *   **Stage 6**: 2 groups, 64 butterflies per zeta. `zeta_addr` sweeps 3 down to 2.
    *   **Stage 7**: 1 group, 128 butterflies per zeta. `zeta_addr` = 1.

---

## 2. Layout-Transition Tables

Bank mapping is computed as: $bank = i[p] \oplus (xor ? i[r] : 0)$.
The address is computed by removing bit $r$: $addr = \text{remove\_bit}(i, r)$, where $i \in [0, 255]$.
Because the read and write operands $(u, v)$ for any butterfly differ only at bit $pair\_bit$, the mapping guarantees $u\_bank \ne v\_bank$. Thus, all stages are bijections (mapping 256 logical indices to 2 banks of 128 locations) and are conflict-free.

### 2.1 Forward NTT Layout Transitions
*   **Initial Input Layout**: Canonical Standard Order (`b=i7, a=rm7`).
*   **Final Output Layout**: Bit-reversed NTT order (`b=i1, a=rm1`).

| Stage | Source Layout | Destination Layout | Conflict/Bijection Result |
| :---: | :---: | :---: | :---: |
| **1** | `b=i7, a=rm7` | `b=i7^i6, a=rm6` | Bijection, Conflict-Free |
| **2** | `b=i7^i6, a=rm6` | `b=i6^i5, a=rm5` | Bijection, Conflict-Free |
| **3** | `b=i6^i5, a=rm5` | `b=i5^i4, a=rm4` | Bijection, Conflict-Free |
| **4** | `b=i5^i4, a=rm4` | `b=i4^i3, a=rm3` | Bijection, Conflict-Free |
| **5** | `b=i4^i3, a=rm3` | `b=i3^i2, a=rm2` | Bijection, Conflict-Free |
| **6** | `b=i3^i2, a=rm2` | `b=i2^i1, a=rm1` | Bijection, Conflict-Free |
| **7** | `b=i2^i1, a=rm1` | `b=i1, a=rm1` | Bijection, Conflict-Free |

### 2.2 Inverse NTT Layout Transitions
*   **Initial Input Layout**: Forward-output order ($p=1, r=1, xor=0$).
*   **Final Output Layout**: Canonical Standard Order ($p=7, r=7, xor=0$).

| Stage | Source Layout (p, r, xor) | Destination Layout (p, r, xor) | Conflict/Bijection Result |
| :---: | :---: | :---: | :---: |
| **1** | $p=1, r=1, xor=0$ | $p=2, r=1, xor=1$ | Bijection, Conflict-Free |
| **2** | $p=2, r=1, xor=1$ | $p=3, r=2, xor=1$ | Bijection, Conflict-Free |
| **3** | $p=3, r=2, xor=1$ | $p=4, r=3, xor=1$ | Bijection, Conflict-Free |
| **4** | $p=4, r=3, xor=1$ | $p=5, r=4, xor=1$ | Bijection, Conflict-Free |
| **5** | $p=5, r=4, xor=1$ | $p=6, r=5, xor=1$ | Bijection, Conflict-Free |
| **6** | $p=6, r=5, xor=1$ | $p=7, r=6, xor=1$ | Bijection, Conflict-Free |
| **7** | $p=7, r=6, xor=1$ | $p=7, r=7, xor=0$ | Bijection, Conflict-Free |

---

## 3. Cycle Timeline

Accounting for nonblocking assignments in both sequential RAM and pipelined butterfly modules, the edge-by-edge timeline for the final transaction (launched at clock edge $M$) is:

| Clock Edge | State / Action | Description |
| :---: | :--- | :--- |
| **$M$** | Read request accepted | RAM read request sampled. |
| **$M+1$** | RAM read complete / butterfly input sampled | Outputs `rd_valid`/`rd_data` are visible and sampled by `butterfly_pipe`. |
| **$M+2$** | Butterfly pipeline stage | `mod_mul_pipe` product path advances. |
| **$M+3$** | Butterfly pipeline stage | Montgomery reduction path advances. |
| **$M+4$** | Butterfly pipeline stage | Montgomery reduction path advances. |
| **$M+5$** | Butterfly pipeline stage | Add/sub input alignment advances. |
| **$M+6$** | Butterfly output visible | `out_valid/out0/out1` and delayed write metadata are visible for the RAM write port. |
| **$M+7$** | RAM write committed / drain detected | Data is written to RAM memory array on this edge. |
| **$M+9$** | Safe role swap / stage advance | The core swaps roles and advances the scheduler only after the final write is committed and pending counters are zero. |

*Note: The synchronous destination write commits on the edge that samples
`dst_wr_en` and write data. M3.2 measured issue-to-write-commit latency as 7
cycles.*

---

## 4. Final INTT Scaling

The final scaling by $128^{-1} \pmod q$ is performed using two parallel `mod_mul_pipe` lanes (scaling two coefficients per cycle) for 128 cycles of requests:
*   **Final Scaler Operand**: **512** ($3303 \cdot R \pmod q$). Since `mod_mul_pipe` divides by $R$, multiplying by 512 results in a canonical normal-domain output scaled by $128^{-1} \equiv 3303 \pmod q$.
*   **Legacy Operand**: **1441** ($3303 \cdot R^2 \pmod q$) is used only for legacy `tomont` representation.
*   **Scaling Timeline** (final request launched at Edge $K$):
    *   **Edge $K$**: Final read request launched.
    *   **Edge $K+1$**: RAM outputs are visible and scaler inputs are sampled.
    *   **Edge $K+5$**: Scaler output becomes visible after four multiplier cycles.
    *   **Edge $K+6$**: Destination RAM write is committed.
    *   **Edge $K+7$**: Final scaler role swap is committed.
    *   **Edge $K+8$**: Public `done` is asserted for one cycle.

---

## 5. Controller contracts & Error handling

*   **Legal Concurrent Access**: Concurrent source-reads and destination-writes to different physical bank addresses are legal and necessary for $II=1$ throughput.
*   **Errors**:
    *   Physical address collisions (reading and writing to the same address of the same bank on the same edge).
    *   Unsafe role swap (asserting `swap_roles` while busy or traffic is pending).
    *   `start` asserted while busy.
    *   Illegal external access (trying to load/read coefficients while busy).

---

## 6. Zeta Representation & Scaling Proof

*   **Modulus**: $q = 3329$
*   **Montgomery factor**: $R = 2^{16} = 65536 \equiv 2285 \pmod q$.
*   **Inverse scale**: FIPS 203 Algorithm 10 uses $3303 = 128^{-1} \pmod q$ for final scaling.
*   **Mathematical Proof**:
    *   $3303 \cdot 128 = 422784 = 127 \cdot 3329 + 1 \equiv 1 \pmod q$
    *   $512 \equiv 3303 \cdot R \pmod q$ (since $-26 \cdot 2285 = -59410 \equiv 512 \pmod q$)
    *   $1441 \equiv 3303 \cdot R^2 \pmod q$ (since $512 \cdot 2285 = 1169920 \equiv 1441 \pmod q$)

---

## 7. M3.6 Measured Closure

The unified M3 regression freezes the implemented timing and bandwidth:

| Phase | Pair issues | Measured cycles | Issue utilization |
| :--- | ---: | ---: | ---: |
| Forward NTT | 896 | 955 start-to-done | 93.82% |
| Inverse butterflies | 896 | 954 through stage completion | 93.92% |
| Two-lane scaler | 128 | 135 through final ownership | 94.81% |
| Full inverse | 1024 | 1090 start-to-done | mixed operation |

Both butterfly schedulers issue 128 consecutive pairs per stage. The measured
gap after one stage's last issue and before the next stage's first issue is
eight no-issue cycles. Butterfly issue-to-committed-write latency is seven
cycles; scaler issue-to-committed-write latency is six cycles. These are cycle
contracts only. M2.3b synthesis remains pending, so no clock frequency or Fmax
is selected or claimed.
