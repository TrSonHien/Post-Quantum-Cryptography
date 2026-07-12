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
*   **Initial Input Layout**: Canonical Standard Order ($p=7, r=7, xor=0$).
*   **Final Output Layout**: Bit-Reversed Order ($p=1, r=7, xor=1$).

| Stage | Source Layout (p, r, xor) | Destination Layout (p, r, xor) | Conflict/Bijection Result |
| :---: | :---: | :---: | :---: |
| **1** | $p=7, r=7, xor=0$ | $p=6, r=7, xor=1$ | Bijection, Conflict-Free |
| **2** | $p=6, r=7, xor=1$ | $p=5, r=7, xor=1$ | Bijection, Conflict-Free |
| **3** | $p=5, r=7, xor=1$ | $p=4, r=7, xor=1$ | Bijection, Conflict-Free |
| **4** | $p=4, r=7, xor=1$ | $p=3, r=7, xor=1$ | Bijection, Conflict-Free |
| **5** | $p=3, r=7, xor=1$ | $p=2, r=7, xor=1$ | Bijection, Conflict-Free |
| **6** | $p=2, r=7, xor=1$ | $p=1, r=7, xor=1$ | Bijection, Conflict-Free |
| **7** | $p=1, r=7, xor=1$ | $p=1, r=7, xor=1$ | Bijection, Conflict-Free |

### 2.2 Inverse NTT Layout Transitions
*   **Initial Input Layout**: Bit-Reversed Order ($p=1, r=7, xor=1$).
*   **Final Output Layout**: Canonical Standard Order ($p=7, r=7, xor=0$).

| Stage | Source Layout (p, r, xor) | Destination Layout (p, r, xor) | Conflict/Bijection Result |
| :---: | :---: | :---: | :---: |
| **1** | $p=1, r=7, xor=1$ | $p=2, r=7, xor=1$ | Bijection, Conflict-Free |
| **2** | $p=2, r=7, xor=1$ | $p=3, r=7, xor=1$ | Bijection, Conflict-Free |
| **3** | $p=3, r=7, xor=1$ | $p=4, r=7, xor=1$ | Bijection, Conflict-Free |
| **4** | $p=4, r=7, xor=1$ | $p=5, r=7, xor=1$ | Bijection, Conflict-Free |
| **5** | $p=5, r=7, xor=1$ | $p=6, r=7, xor=1$ | Bijection, Conflict-Free |
| **6** | $p=6, r=7, xor=1$ | $p=7, r=7, xor=0$ | Bijection, Conflict-Free |
| **7** | $p=7, r=7, xor=0$ | $p=7, r=7, xor=0$ | Bijection, Conflict-Free |

---

## 3. Cycle Timeline

Accounting for nonblocking assignments in both sequential RAM and pipelined butterfly modules, the edge-by-edge timeline for the final transaction (launched at clock edge $M$) is:

| Clock Edge | State / Action | Description |
| :---: | :--- | :--- |
| **$M$** | Read request accepted | Controller updates logical registers. RAM read initiated (`src_rd_en = 1`). |
| **$M+1$** | RAM read complete / outputs visible | RAM internal registers update. Outputs `rd_valid`/`rd_data` visible. |
| **$M+2$** | Butterfly input sampled / Stage 1 registered | Butterfly inputs sampled and registered into Stage 1 (mod_mul_pipe multiplier). |
| **$M+3$** | Butterfly Stage 2 registered | `mod_mul_pipe` Stage 1 product registered / Stage 2 registered. $u$ delayed. |
| **$M+4$** | Butterfly Stage 3 registered | Montgomery reduction Stage 1 registered. |
| **$M+5$** | Butterfly Stage 4 registered | Montgomery reduction Stage 2 registered. |
| **$M+6$** | Butterfly Stage 5 registered | Montgomery reduction Stage 3 registered ($t$ available). |
| **$M+7$** | Butterfly Stage 5 complete / Output visible | Parallel add/sub complete. Output visible. RAM write port samples it. |
| **$M+8$** | RAM write committed | Data written to RAM memory array. Write occupies exactly **1 clock cycle** (Edge $M+7 \rightarrow M+8$). |
| **$M+9$** | Role Swap / Done | Safe state transition. Role swap or done assertion occurs on this edge. |

*Note: The synchronous destination write occupies exactly **1 clock cycle** (from Edge $M+7$ to Edge $M+8$) to commit data to the RAM memory array.*

---

## 4. Final INTT Scaling

The final scaling by $128^{-1} \pmod q$ is performed using two parallel `mod_mul_pipe` lanes (scaling two coefficients per cycle) for 128 cycles of requests:
*   **Final Scaler Operand**: **512** ($3303 \cdot R \pmod q$). Since `mod_mul_pipe` divides by $R$, multiplying by 512 results in a canonical normal-domain output scaled by $128^{-1} \equiv 3303 \pmod q$.
*   **Legacy Operand**: **1441** ($3303 \cdot R^2 \pmod q$) is used only for legacy `tomont` representation.
*   **Scaling Timeline** (final request launched at Edge $K$):
    *   **Edge $K$**: Final read request launched.
    *   **Edge $K+1$**: RAM outputs visible.
    *   **Edge $K+2$**: Scaler inputs sampled (Stage 1).
    *   **Edge $K+6$**: Scaler output visible (4-cycle latency). RAM write port samples it.
    *   **Edge $K+7$**: RAM write committed.
    *   **Edge $K+8$**: State transition to idle / assert `done`.

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
