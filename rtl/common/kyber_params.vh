/*
 * Shared ML-KEM-768 parameter include.
 *
 * This include is an ACTIVE_SHARED_LEAF dependency rather than a module.  It
 * defines the frozen ML-KEM-768 dimensions, byte sizes, and implementation
 * widths used throughout the synthesizable release hierarchy.  The macros
 * describe canonical parameter values; they do not carry runtime payload
 * state.  Include it before declarations that use these widths.
 */
`ifndef KYBER_PARAMS_VH
`define KYBER_PARAMS_VH

`define KYBER_K 3
`define KYBER_N 256
`define KYBER_Q 3329
`define KYBER_ETA1 2
`define KYBER_ETA2 2
`define KYBER_DU 10
`define KYBER_DV 4

`define KYBER_SYMBYTES 32
`define KYBER_SSBYTES 32
`define KYBER_POLYBYTES 384
`define KYBER_POLYVECBYTES 1152
`define KYBER_PUBLICKEYBYTES 1184
`define KYBER_SECRETKEYBYTES 2400
`define KYBER_CIPHERTEXTBYTES 1088

`define KYBER_Q_WIDTH 12
`define KYBER_SUM_WIDTH 13
`define KYBER_N_WIDTH 8
`define KYBER_K_WIDTH 2

`endif
