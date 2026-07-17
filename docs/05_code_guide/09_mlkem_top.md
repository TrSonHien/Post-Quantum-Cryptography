# ML-KEM top-level controllers

## mlkem

### Purpose
FIPS 203 Algorithms 16--21 ML-KEM support

### Active modules

- `mlkem768_top`
- `mlkem_decaps`
- `mlkem_decaps_input_check`
- `mlkem_decaps_internal`
- `mlkem_ek_check`
- `mlkem_encaps`
- `mlkem_encaps_internal`
- `mlkem_keygen`
- `mlkem_keygen_internal`

### Retained support / legacy modules

- `mlkem_byte_buffer`
- `mlkem_ct_compare_select`
- `mlkem_dk_assemble`
- `mlkem_dk_parse`
- `mlkem_zeroize_controller`

### Reading notes

- Use the module catalog for parents, children, domain, handshake, state ownership, TB, and runner links.
- Treat named domain signals as authoritative; NORMAL and NTT are distinct representations.
- Fixed cycle counts are stated only where the implementation contract proves them; controllers otherwise use done/busy completion.
