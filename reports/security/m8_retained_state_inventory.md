# M8 Retained-State Inventory v0.1

## Scope and counting method

This inventory is for the elaborated `mlkem768_top` at development HEAD
`54910f6` with the intended dirty M8 worktree.  It covers only RTL-owned state;
caller-owned input/output memory is excluded.  The hierarchy was elaborated
with the same RTL file set as `run_mlkem768_top.sh`.  Source modules containing
clocked state were intersected with the elaborated hierarchy.  Combinational
temporary arrays, ROM constants, and debug-only function locals were excluded.

The result is 50 state-owning module types, 449 elaborated instances, 4,190
elaborated register/array objects, and 1,020,266 retained bits.  An inventory
entry below is one owner-type state family; exact instance multiplicity and
aggregate retained bits include structural duplication across public modes.
Classification and mechanism counts are non-exclusive because one owner can
hold public input, secret intermediate, and designated output state.

- 50 retained-state owner entries
- 27 secret-bearing entries
- 45 ephemeral-bearing entries
- 17 public-bearing entries
- 10 designated-output-bearing entries
- 18 RAM/array-scan entries
- 24 pipeline-flush entries
- 46 direct-scalar-clear entries
- 33 child-propagation entries
- 0 unresolved ownership entries

`LI` means reset clears control validity/ownership but does not establish
physical payload destruction.  All proposed latencies are fixed upper bounds
from request acceptance through the final committed overwrite; they must be
replaced by measured values in the coverage manifest.

## Major retained arrays and buffers

| ID | Module / hierarchy pattern | State (width x count, aggregate bits) | Class and populated operations | Last needed | Reset / current zeroize | Owner / proposed destruction | Fixed cycles / verification / status |
|---|---|---|---|---|---|---|---|
| M8-TOP | `mlkem768_top` | active/owned/zeroizing/done/error (6 bits) | ephemeral; all public modes | termination | LI / private-reset shortcut is invalid | top; direct clear after child acknowledgements | 2 / top protocol TB / missing |
| M8-PKG | `top.kg` | entropy 8x64 plus control (562 bits) | secret; public KeyGen | internal input accepted | LI / sequential entropy scan exists only on normal path | `mlkem_keygen`; 64-address scan | 66 / fill-read hierarchy and clean KeyGen / missing explicit request |
| M8-PEN | `top.en` | ek 8x1184, m 8x32 plus control (9,788 bits) | public+secret; public Encaps | internal input accepted | LI / normal-path scan only | `mlkem_encaps`; 1184-address scan | 1186 / valid/noncanonical/RNG/restart / missing explicit request |
| M8-PDE | `top.de` | dk 8x2400, c 8x1088 plus control (27,966 bits) | secret+public; public Decaps | internal input accepted | LI / normal-path scan only | `mlkem_decaps`; 2400-address scan | 2402 / hash-check, implicit-reject, restart / missing explicit request |
| M8-IKG | `top.kg.core` | d,z,h 8x32; ek 8x1184; dkPKE 8x1152; dk 8x2400; control (38,825 bits) | secret+public+designated outputs; KeyGen_internal | final EK/DK transfer | LI / automatic local scan and child request | `mlkem_keygen_internal`; 2400-address scan then child wait | 2404+children / differential KeyGen and hierarchy readback / incomplete child closure |
| M8-IEN | `top.en.core` | ek 8x1184; m,h,K,r 8x32; c 8x1088; control (19,342 bits) | secret+public+designated outputs; Encaps_internal | final K/c transfer | LI / automatic local scan and child request | `mlkem_encaps_internal`; 1184-address scan then child wait | 1188+children / differential Encaps / incomplete child closure |
| M8-IDE | `top.de.core` | dk 8x2400; c,c_prime 8x1088; m',K',r',Kbar,Kout 8x32; control (38,084 bits) | secret+ephemeral+designated K; Decaps_internal | final K transfer | LI / automatic scan; mismatch/mask direct clear | `mlkem_decaps_internal`; 2400-address scan then four child waits | 2406+children / valid/fallback and hierarchy readback / incomplete child closure |
| M8-EKC | `top.en.chk` | ek 8x1184 plus decode/check state (9,574 bits) | public+ephemeral; public Encaps check | checked result consumed | LI / 1184-address scan | `mlkem_ek_check`; memory scan+direct metadata clear | 1186 / canonical and malformed streams / complete locally |
| M8-DKC | `top.de.chk` | dk 8x2400, c 8x1088, digest 8x32 plus state (28,249 bits) | secret+public+ephemeral; public Decaps check | pass/fail consumed | LI / local scan plus M5 H request | `mlkem_decaps_input_check`; 2400-address scan+child ack | 2404 / hash mismatch positions and readback / incomplete child protocol |
| M8-LAYOUT | standalone M8 layout/buffer/compare owners | configured byte arrays; largest 8x2400 | secret/public/ephemeral; layout and compare/select | result accepted | LI / sequential address scans | each primitive; scan all configured addresses | capacity+2 / existing unit TBs / complete locally |

## K-PKE controller-owned state

| ID | Module / hierarchy pattern | State (width x count, aggregate bits) | Class and operations | Last needed | Reset / current zeroize | Owner / proposed destruction | Fixed cycles / verification / status |
|---|---|---|---|---|---|---|---|
| M7-KG | `*.kpke_keygen` (1 instance) | d/rho/sigma 8x32 each; ek 8x1184; dk 8x1152; six 12x768 vectors; dot 12x256; control = 78,036 bits | secret+ephemeral+designated; K-PKE KeyGen | final output accepted | LI / 1,184-step local scan plus seven child acknowledgements | controller; local scan plus explicit child requests/acks | max(1,186, children)+2 / K-PKE differential+zeroize TB / complete |
| M7-EN | `*.kpke_encrypt` (2 instances) | per instance ek 8x1184; m/r/rho 8x32; c 8x1088; six 12x768 and six 12x256 arrays; aggregate 185,708 bits | secret+ephemeral+designated c; K-PKE Encrypt/re-encrypt | final c accepted | LI / 1,184-step local scan plus eleven child acknowledgements | controller; scan plus all child requests/acks | max(1,186, children)+2 / Encrypt differential+zeroize TB / complete |
| M7-DE | `*.kpke_decrypt` (1 instance) | dk 8x1152; c 8x1088; msg 8x32; three 12x768 and four 12x256 arrays; 58,237 bits | secret+ephemeral+designated m'; K-PKE Decrypt | message accepted by Decaps | LI / 1,152-step local scan plus eight child acknowledgements | controller; scan plus all child requests/acks | max(1,154, children)+2 / Decrypt differential+zeroize TB / complete |
| M7-MAT | `*.kpke_matrix_row_sampler` (3) | rho_q 256, row/transpose/element and control; 807 bits | public; matrix A-hat | row captured | reset invalidates control / direct scalar clear plus SampleNTT child acknowledgement | sampler; direct clear and child request/ack | child+2 / matrix/transpose ordinary and hierarchy zeroize / complete; public exception not relied upon |
| M7-NOISE | `*.kpke_noise_vector_sampler` (3) | seed_q 256, nonce/eta/element/control; 852 bits | secret+ephemeral; KeyGen/Encrypt noise | sampled vector captured | reset invalidates control / direct scalar clear plus noise-child acknowledgement | sampler; direct clear+noise child zeroize | child+2 / nonce ordinary and hierarchy zeroize / complete |

## Reused storage and execution engines

| ID | Module / hierarchy pattern | State (instances; aggregate bits) | Class / populated operations / last needed | Reset / current zeroize | Owner / destruction method | Fixed cycles / verification / status |
|---|---|---|---|---|---|---|
| P-WS | `*.poly_workspace` | 102; bank_even/bank_odd each 12x128 plus metadata, 346,290 bits (313,344 payload bits) | secret/ephemeral/public; all poly/polyvec paths; until result consumed | LI / explicit scan implemented | workspace; parallel two-bank 128-address scan, block all ports | measured 130 / 260 locations, reset-interrupt, reload / complete owner primitive; parent propagation pending |
| PV-WS | `*.polyvec_workspace` | 20 wrappers; metadata 20 bits, child P-WS owns coefficients | secret/ephemeral/public; vector operations | LI / child propagation implemented | polyvec wrapper; request three workspaces in parallel and AND acks | measured 132 / 780 locations across all three polynomials / complete owner primitive; engine propagation pending |
| NTT-BANK | `*.ntt_pingpong_banks.*.sync_1r1w_ram` | 7 bank owners, 28 RAMs; 12x128 each plus read staging, 43,372 bits | secret/ephemeral or public matrix transform; until transform result consumed | LI / explicit four-bank scan implemented | ping-pong owner; write zero to all four banks at each of 128 addresses | measured 130 / 512 locations, reset interruption, normal write / complete |
| NTT-PRE | `*.ntt_core_pipe` | 4; preload_lo 12x128 plus staging/control, 7,828 bits | secret/ephemeral; forward transforms | LI / preload scan and five-child join implemented | NTT core; clear preload during bank scan, flush registered lanes | bounded 134 / combined core test and ordinary M3 oracle / complete core; parent propagation pending |
| INTT-PRE | `*.intt_core_pipe` | 3; preload_first 12x128 plus scaler/staging/control, 6,432 bits | secret/ephemeral; inverse transforms | LI / preload scan and six-child join implemented | INTT core; clear preload during bank scan, flush scaler lanes | bounded 138 / combined core test and ordinary M3 oracle / complete core; parent propagation pending |
| P-XFORM | `*.poly_transform_pipe` | 7; transfer/index/result metadata, 224 bits plus child storage | secret/ephemeral; NTT/INTT adapters | LI / two workspaces and NTT/INTT core acknowledgement join | transform owner; child workspace/core requests and ack join | max(children)+2 / ordinary transform+hierarchy readback / complete |
| PV-ELEM | `*.polyvec_elementwise_pipe` | 4; state/index/result metadata, 140 bits plus child storage | secret/ephemeral; polyvec NTT and arithmetic | LI / three polyvec workspaces and selected child acknowledgement join | vector owner; child/vector-workspace requests and ack join | max(children)+2 / ordinary polyvec tests+hierarchy zeroize / complete |
| P-BIN | `*.poly_binary_pipe` | 4; state/pair/result metadata, 112 bits plus three workspaces/pipelines | secret/ephemeral; poly add/sub | LI / three workspace scans plus two arithmetic lane acknowledgements | binary owner; workspace scans plus two lane clears | bounded 134 / add/sub oracle and hierarchy readback / complete |
| PV-BM | `*.polyvec_basemul_acc_pipe` | 4; state/index/result metadata, 172 bits plus workspaces/child | secret/ephemeral; dot products | LI / two vector workspaces, accumulator workspace, basemul and add acknowledgements | accumulator owner; all workspace/child requests and ack join | bounded 140 / BaseCaseMultiply differential+hierarchy readback / complete |
| P-BM | `*.poly_basemul_pipe` | 4; pair/index/result metadata, 132 bits plus 3 workspaces and lanes | secret/ephemeral; MultiplyNTTs | LI / three workspaces, basecase pipeline and metadata delay acknowledgements | basemul owner; workspace scans plus pipeline flush | bounded 136 / ordinary basemul+hierarchy readback / complete |

## Pipelines, codecs, samplers, and Keccak

| ID | Module family / hierarchy | Retained state (instances; aggregate bits) | Class / lifetime | Reset / current zeroize | Proposed method | Fixed cycles / verification / status |
|---|---|---|---|---|---|---|
| FLD | `fixed_latency_delay` | 40; payload/metadata/valid stages, 6,210 bits | secret/ephemeral; arithmetic/NTT metadata until drain | valid reset only / valid-zero flush implemented | valid zero-data flush for LATENCY stages, outputs suppressed | measured LATENCY+2 / every stage and clean restart / complete primitive |
| MOD-ADD | `mod_add_pipe` | 25; 325 bits | secret/ephemeral pipeline | control reset; payload retained / explicit clear implemented | direct registered-payload clear | measured 2 / lane TB+stage inspection / complete primitive |
| MOD-SUB | `mod_sub_pipe` | 9; 117 bits | secret/ephemeral pipeline | same | direct registered-payload clear | measured 2 / lane TB / complete primitive |
| MOD-MUL | `mod_mul_pipe` | 13; 325 bits | secret/ephemeral pipeline | payload retained / child reduction ack implemented | direct local clear plus child request | bounded 5 / multiplier+reduction hierarchy TB / complete primitive |
| MOD-NMUL | `mod_mul_normal_pipe` | 20; 500 bits | secret/ephemeral pipeline | valid-only reset / local product clear plus Barrett child acknowledgement | direct clear and child request | measured 4 / normal multiply oracle+stage inspection / complete |
| MONT | `montgomery_reduce_pipe` | 13; 1,599 bits | secret/ephemeral pipeline | valid reset only / explicit register clear implemented | direct clear of all three retained stages | measured 2 / reduction TB+stage inspection / complete primitive |
| BAR | `barrett_reduce_pipe` | 20; 3,620 bits | secret/ephemeral pipeline | valid-only reset / all three payload stages directly cleared | direct clear | measured 2 / reduction oracle+stage inspection / complete |
| BFLY | `butterfly_pipe`/`intt_butterfly_pipe` | 4+3 wrappers; child pipelines plus 36 local bits | secret/ephemeral NTT lanes | valid reset only / coordinated child zeroize implemented | coordinated lane clear/flush and acknowledgement join | bounded 8 / butterfly ordinary tests plus NTT/INTT hierarchy readback / complete primitive |
| CODEC-D | `byte_decode_poly_pipe` | 7; reservoir, coefficient/output state, 1,379 bits | secret/public/ephemeral; decode until coefficient consumed | existing reset behavior retained / explicit clear implemented | direct reservoir, temporary, output, counter, and metadata clear | measured 2 / canonical/noncanonical oracle plus hierarchy inspection / complete owner primitive |
| CODEC-E | `byte_encode_poly_pipe` | 6; reservoir/input/output state, 1,404 bits | secret/public/ephemeral; encode until word consumed | existing reset behavior retained / explicit clear implemented | direct reservoir, temporary, output, counter, and metadata clear | measured 2 / encode differential plus hierarchy inspection / complete owner primitive |
| CODEC-V | `polyvec_codec_pipe` | 7; wrapper state 105 bits plus codec children | secret/public/ephemeral | LI / explicit child request and acknowledgement implemented | direct wrapper clear, hold child request through acknowledgement | measured child+2 / M6 polyvec oracle and zeroize TB / complete |
| CBD | `cbd_pair_pipe`/`sample_poly_cbd_pipe` | 5; stream/CBD/output state, 755 bits | secret/ephemeral noise | existing reset behavior retained / explicit clear implemented | direct reservoir, coefficient, output, counter, and metadata clear | measured 2 / CBD oracle+stage inspection / complete |
| NTT-PARSER | `sample_ntt_parser` | 3; candidate group/output/count state, 402 bits | public for A-hat; ephemeral ownership | existing reset behavior retained / explicit clear implemented | direct candidate/output/counter clear | measured 2 / parser regression and hierarchy inspection / complete; public payload exception not relied upon |
| SAMPLE-NTT | `mlkem_sample_ntt` | 3; controller state 15 bits plus XOF/parser children | public A-hat | reset abort only / XOF and parser acknowledgement join implemented | direct controller clear and held parallel child request | measured max(children)+2 / SampleNTT oracle, reset interruption, hierarchy inspection / complete |
| NOISE | `mlkem_noise_sampler` | 5; local control 20 bits plus PRF/CBD child | secret/ephemeral | reset abort / PRF and CBD acknowledgement join implemented | direct controller clear and held parallel child request | measured max(children)+2 / M6 noise oracle, reset interruption, hierarchy inspection / complete |
| PRF | `mlkem_prf` | 5; seed_reg 256, nonce/eta/word/control, 1,380 bits | secret/ephemeral noise generation | reset clears scalars; explicit child acknowledgement implemented | direct scalar clear+hash child request held through ack | bounded 8 / 128-vector PRF oracle plus reset-interrupt zeroize / complete including noise-parent propagation |
| XOF | `mlkem_xof` | 3; 272-bit input_reg and control, 843 bits | public for A-hat; secret if reused generically | reset clears scalar payload; explicit child acknowledgement implemented | direct input clear+sponge child request held through ack | bounded 8 / 64-vector XOF oracle plus reset-interrupt zeroize / complete including SampleNTT-parent propagation |
| HSTREAM | `keccak_hash_stream` | 12; mode/length/state/control, 876 bits | secret/public ephemeral | reset abort / zeroize connected through H/G/J and PRF services | direct scalar clear+sponge ack | 6 / H/G/J and PRF ordinary/zeroize tests / complete for M5/M6 service paths |
| SPONGE | `keccak_sponge_ctx` | 15; state_reg and perm_state_in 1600 each plus staging, 51,315 bits | secret/public ephemeral | reset invalidates; explicit clear implemented | direct clear+permutation ack | 4 / hierarchical M5 plus PRF/XOF tests / complete for H/G/J/PRF/XOF paths |
| PERM | `keccak_f1600_core` | 15; state_reg/state_out 1600 each plus control, 48,135 bits | secret/public ephemeral | reset abort; explicit clear implemented | direct clear | 2 / M5 permutation zeroize / complete where requested |
| H/G/J | `mlkem_h/g/j` | 3/3/1; local zeroize control, 14 bits plus child state | secret/public hash service | LI / explicit request/busy/done implemented | propagate and wait; mask all normal protocol visibility | measured 4 maximum / 123-check focused zeroize plus 240-vector H/G/J oracle / complete |

## Control and ownership metadata coverage

All state-owning types not carrying a separately listed payload array are
covered by their family row: `ntt_scheduler_pipe`, `intt_scheduler_pipe`,
`kpke_matrix_row_sampler`, codec/sampler wrapper state, and arithmetic valid/
metadata stages.  Their indices, counters, result-valid flags, domain tags,
owners, errors, and done bits are ephemeral control state.  They require direct
clear when zeroize is accepted, remain inaccessible while `zeroize_busy`, and
must be checked invalid before `zeroize_done`.

Public A-hat coefficient payload in matrix/SampleNTT paths is exempt from
confidentiality overwrite, but its owner/result-valid/domain metadata is not
exempt.  The strict top policy may scrub public EK/ciphertext copies for a
uniform implementation.  Internal d and z copies are always secret and must be
scrubbed; no FIPS seed-retention exception is selected.

## Ownership conclusion

Every retained state family has an identified owner.  No ownership
contradiction blocks bottom-up implementation.  The unresolved items are
implementation and verification gaps, not ambiguous ownership.  M8 completion
remains blocked until every `missing` or `partially complete` entry maps to a
passing coverage-manifest check.

## Implementation checkpoint 2026-07-16

Bottom-up owner closure has reached M7 without changing mathematical outputs.
M6 codec/sampler propagation is committed at `399e727`. Transform adapters,
normal multiply/Barrett pipelines, M7 sampler parents, and all three K-PKE
controllers now use explicit child request/acknowledgement joins. The
nonrecursive M7 ordinary regression passes 11/11 with 497,775 accounted checks; its
21,462-check scrub test covers 21,408 controller-local locations, 16
representative child locations, all 26 direct child acknowledgements, repeated
scrub, active abort, reset interruption, and clean restart. This is not M8
completion: M8 internal controllers, public wrappers, automatic cleanup, and
unified boot scrub remain open.
