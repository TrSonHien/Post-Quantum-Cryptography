# Project Specification

## Project

Full RTL-to-GDSII Hardware Implementation of ML-KEM-768 / Kyber-768.

## Scope

This repository targets a learning-oriented but professional hardware implementation flow for ML-KEM-768:

- Reference study and golden model setup
- RTL design
- Unit, block, and system verification
- Cadence Genus synthesis
- Server-side physical design execution
- Timing, power, and area reporting
- Final technical report

## Current Status

The repository is in M1: Project Foundation. Existing Verilog is scaffolding only and has not been reviewed as an ML-KEM design.

## Non-Claims

- No cryptographic correctness is claimed until test-vector comparison exists.
- No synthesizability is claimed until RTL review and synthesis reports exist.
- No ASIC readiness is claimed until constraints, scripts, reports, and checks exist from the selected local or server-side flow.
