#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEBUG_WAVES="${DEBUG_WAVES:-0}"
START_SECONDS="$(date +%s)"
TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/mlkem-m3-regression.XXXXXX")"
TEST_ROOT="${TEMP_ROOT}/repo"
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
INTERNAL_CHECKS=0

cleanup() {
    if [[ "${DEBUG_WAVES}" == "1" ]]; then
        DEBUG_DIR="${ROOT_DIR}/sim/waves/m3_regression_debug"
        mkdir -p "${DEBUG_DIR}"
        find "${TEST_ROOT}/sim/waves" -type f \( -name '*.vcd' -o -name '*.fst' \) \
            -exec cp -f {} "${DEBUG_DIR}/" \; 2>/dev/null || true
        echo "DEBUG_WAVES_DIR=${DEBUG_DIR}"
    fi
    rm -rf "${TEMP_ROOT}"
}
trap cleanup EXIT INT TERM

print_summary() {
    local status="$1"
    local elapsed
    elapsed=$(($(date +%s) - START_SECONDS))
    echo "M3_REGRESSION_STATUS=${status}"
    echo "TESTS_RUN=${TESTS_RUN}"
    echo "TESTS_PASSED=${TESTS_PASSED}"
    echo "TESTS_FAILED=${TESTS_FAILED}"
    echo "INTERNAL_CHECKS=${INTERNAL_CHECKS}"
    echo "ELAPSED_SECONDS=${elapsed}"
}

run_test() {
    local name="$1"
    local limit="$2"
    local checks="$3"
    local log_file
    local started
    local elapsed
    local status
    shift 3
    TESTS_RUN=$((TESTS_RUN + 1))
    log_file="${TEMP_ROOT}/test_${TESTS_RUN}.log"
    started=$(date +%s)
    set +e
    timeout "${limit}" "$@" >"${log_file}" 2>&1
    status=$?
    set -e
    elapsed=$(($(date +%s) - started))
    if [[ ${status} -eq 0 ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        INTERNAL_CHECKS=$((INTERNAL_CHECKS + checks))
        printf 'M3_TEST name=%q status=PASS elapsed_s=%d checks=%d\n' "${name}" "${elapsed}" "${checks}"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        printf 'M3_TEST name=%q status=FAIL exit=%d elapsed_s=%d\n' "${name}" "${status}" "${elapsed}"
        tail -80 "${log_file}"
        print_summary FAIL
        exit "${status}"
    fi
}

mkdir -p "${TEST_ROOT}"
tar -C "${ROOT_DIR}" \
    --exclude='./.git' \
    --exclude='./sim/logs/*' \
    --exclude='./sim/outputs/*' \
    --exclude='./sim/waves/*' \
    --exclude='./ref_model/c_ref/build' \
    --exclude='*/__pycache__' \
    -cf - . | tar -C "${TEST_ROOT}" -xf -

cd "${TEST_ROOT}"
export PYTHONPATH="${TEST_ROOT}${PYTHONPATH:+:${PYTHONPATH}}"

echo "M3_REGRESSION_COMMIT=$(git -C "${ROOT_DIR}" rev-parse --short HEAD)"
echo "DEBUG_WAVES=${DEBUG_WAVES}"
echo "IVERILOG_VERSION=$(iverilog -V 2>&1 | sed -n '1p')"
echo "VVP_VERSION=$(vvp -V 2>&1 | sed -n '1p')"
echo "PYTHON_VERSION=$(python3 --version 2>&1)"

run_test layout_proof 30s 1800 python3 tb/tools/check_ntt_layouts.py
run_test forward_scheduler 30s 896 ./sim/scripts/run_ntt_scheduler_pipe.sh
run_test forward_core 45s 7168 ./sim/scripts/run_ntt_core_pipe.sh
run_test inverse_scheduler 30s 896 ./sim/scripts/run_intt_scheduler_pipe.sh
run_test inverse_scaler 30s 3336 ./sim/scripts/run_intt_scaler_pipe.sh
run_test inverse_core 60s 7936 ./sim/scripts/run_intt_core_pipe.sh
run_test pipelined_roundtrip 60s 15360 ./sim/scripts/run_ntt_intt_pipe_roundtrip.sh
run_test m2_1_primitives 60s 5417 ./sim/scripts/run_m2_1_primitives.sh
run_test m2_2_regression 120s 312935 ./sim/scripts/run_m2_2_regression.sh
run_test legacy_forward_ntt 60s 512 ./sim/scripts/run_ntt_core.sh
run_test legacy_inverse_ntt 60s 768 ./sim/scripts/run_intt_core.sh
run_test legacy_roundtrip 60s 1024 ./sim/scripts/run_ntt_intt_roundtrip.sh
run_test poly_add 60s 1024 ./sim/scripts/run_poly_add.sh
run_test poly_sub 60s 1024 ./sim/scripts/run_poly_sub.sh
run_test basemul 60s 514 ./sim/scripts/run_basemul_unit.sh
run_test basemul_address 60s 256 ./sim/scripts/run_poly_basemul_addr_gen.sh
run_test poly_basemul 60s 768 ./sim/scripts/run_poly_basemul_montgomery.sh
run_test python_selftest 30s 1 python3 -m ref_model.python_model.selftest
run_test python_foundations 30s 13 python3 -m ref_model.python_model.test_foundations
run_test python_schema_compare 30s 5 python3 -m ref_model.compare.test_compare_tools
run_test smoke_vector_compare 30s 1 bash -c \
    'python3 -m ref_model.compare.generate_vectors --output "$1/smoke.json" && python3 -m ref_model.compare.compare_vectors ref_model/compare/vectors/mlkem768_smoke.json "$1/smoke.json"' \
    _ "${TEMP_ROOT}"
run_test deterministic_m3_vectors 30s 2 bash -c \
    'mkdir -p "$1/a" "$1/b" && python3 tb/tools/gen_ntt_core_pipe_vectors.py --output "$1/a/fwd.mem" --random-count 20 && python3 tb/tools/gen_ntt_core_pipe_vectors.py --output "$1/b/fwd.mem" --random-count 20 && python3 tb/tools/gen_intt_pipe_vectors.py --intt-output "$1/a/intt.mem" --roundtrip-output "$1/a/roundtrip.mem" && python3 tb/tools/gen_intt_pipe_vectors.py --intt-output "$1/b/intt.mem" --roundtrip-output "$1/b/roundtrip.mem" && cmp "$1/a/fwd.mem" "$1/b/fwd.mem" && cmp "$1/a/intt.mem" "$1/b/intt.mem" && cmp "$1/a/roundtrip.mem" "$1/b/roundtrip.mem"' \
    _ "${TEMP_ROOT}"

print_summary PASS
