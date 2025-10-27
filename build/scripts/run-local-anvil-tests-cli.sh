#!/usr/bin/env bash
# Purpose: End-to-end manual confidence test using only CLI tools (anvil/forge/cast).
# What it does:
# - Starts a local Anvil node with deterministic keys
# - Builds contracts and deploys YurtFraction + a mock UZS ERC-20 via raw bytecode
# - Whitelists investors, distributes shares, deposits income and exit proceeds
# - Investors claim income and redeem on exit; final balances and supply are checked
# Why this matters: Gives the contract operator a repeatable, scriptable check that
# the core lifecycle (issue → income → exit) behaves as documented without running
# Solidity scripts, suitable for ops runbooks and pre‑deployment smoke tests.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RPC_URL="${RPC_URL:-http://127.0.0.1:8545}"
export RPC_URL
ANVIL_BIN="${ANVIL_BIN:-anvil}"
MNEMONIC="${ANVIL_MNEMONIC_OVERRIDE:-test test test test test test test test test test test junk}"
ANVIL_LOG="${ANVIL_LOG:-/tmp/eyr-local-anvil-cli.log}"
CHAIN_ID="${CHAIN_ID:-31337}"

if ! command -v forge >/dev/null 2>&1; then
    if [[ -x "${HOME}/.foundry/bin/forge" ]]; then
        export PATH="${HOME}/.foundry/bin:${PATH}"
    fi
fi
command -v forge >/dev/null 2>&1 || { echo "[!] forge not found in PATH"; exit 127; }

if ! command -v cast >/dev/null 2>&1; then
    if [[ -x "${HOME}/.foundry/bin/cast" ]]; then
        export PATH="${HOME}/.foundry/bin:${PATH}"
    fi
fi
command -v cast >/dev/null 2>&1 || { echo "[!] cast not found in PATH"; exit 127; }

command -v jq >/dev/null 2>&1 || { echo "[!] jq not found in PATH"; exit 127; }

parse_host_port() {
    python3 - <<'PY'
import os
from urllib.parse import urlparse

url = os.environ["RPC_URL"]
parsed = urlparse(url)
if not parsed.hostname or not parsed.port:
    raise SystemExit(f"Unsupported RPC_URL format: {url}")
print(parsed.hostname)
print(parsed.port)
PY
}

HOST_PORT=($(parse_host_port))
RPC_HOST="${HOST_PORT[0]}"
RPC_PORT="${HOST_PORT[1]}"

cleanup() {
    if [[ -n "${ANVIL_PID:-}" ]] && ps -p "${ANVIL_PID}" > /dev/null 2>&1; then
        kill "${ANVIL_PID}" >/dev/null 2>&1 || true
        wait "${ANVIL_PID}" 2>/dev/null || true
    fi
}
trap cleanup EXIT

calc_amounts() {
    python3 - <<'PY'
WEI = 10**18
total_supply = 1_000_000 * WEI
alice_share = 100_000 * WEI
bob_share = 100_000 * WEI
income_amount = 1_000 * WEI
exit_amount = 5_000 * WEI
owner_share = total_supply - alice_share - bob_share
print(total_supply)
print(alice_share)
print(bob_share)
print(income_amount)
print(exit_amount)
print(owner_share)
print(income_amount + exit_amount)
alice_income = (income_amount * alice_share) // total_supply
bob_income = (income_amount * bob_share) // total_supply
owner_income = (income_amount * owner_share) // total_supply
alice_exit = (exit_amount * alice_share) // total_supply
bob_exit = (exit_amount * bob_share) // total_supply
owner_exit = (exit_amount * owner_share) // total_supply
print(alice_income)
print(bob_income)
print(owner_income)
print(alice_exit)
print(bob_exit)
print(owner_exit)
print(alice_income + alice_exit)
print(bob_income + bob_exit)
print(owner_income + owner_exit)
print(exit_amount + owner_income)
PY
}

AMOUNTS=()
while IFS= read -r line; do
    AMOUNTS+=("$line")
done < <(calc_amounts)
TOTAL_SUPPLY="${AMOUNTS[0]}"
ALICE_SHARE="${AMOUNTS[1]}"
BOB_SHARE="${AMOUNTS[2]}"
INCOME_AMOUNT="${AMOUNTS[3]}"
EXIT_AMOUNT="${AMOUNTS[4]}"
OWNER_SHARE="${AMOUNTS[5]}"
UZS_MINT_TOTAL="${AMOUNTS[6]}"
ALICE_INCOME_EXPECTED="${AMOUNTS[7]}"
BOB_INCOME_EXPECTED="${AMOUNTS[8]}"
OWNER_INCOME_EXPECTED="${AMOUNTS[9]}"
ALICE_EXIT_EXPECTED="${AMOUNTS[10]}"
BOB_EXIT_EXPECTED="${AMOUNTS[11]}"
OWNER_EXIT_EXPECTED="${AMOUNTS[12]}"
ALICE_TOTAL_EXPECTED="${AMOUNTS[13]}"
BOB_TOTAL_EXPECTED="${AMOUNTS[14]}"
OWNER_TOTAL_EXPECTED="${AMOUNTS[15]}"
OWNER_BALANCE_AFTER_INCOME="${AMOUNTS[16]}"


# Load local secrets if present (never commit .env)
if [[ -f "${ROOT_DIR}/.env" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "${ROOT_DIR}/.env"
    set +a
fi

# Require explicit keys via environment (avoid embedding defaults in repo)
: "${OWNER_PK:?Environment OWNER_PK is required (put it in .env for local runs)}"
: "${ALICE_PK:?Environment ALICE_PK is required (put it in .env for local runs)}"
: "${BOB_PK:?Environment BOB_PK is required (put it in .env for local runs)}"

OWNER_ADDR="$(cast wallet address --private-key "${OWNER_PK}")"
ALICE_ADDR="$(cast wallet address --private-key "${ALICE_PK}")"
BOB_ADDR="$(cast wallet address --private-key "${BOB_PK}")"

RPC_PROBE='{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

echo "[*] Starting Anvil on ${RPC_HOST}:${RPC_PORT}"
"${ANVIL_BIN}" \
    --host "${RPC_HOST}" \
    --port "${RPC_PORT}" \
    --mnemonic "${MNEMONIC}" \
    --chain-id "${CHAIN_ID}" \
    --accounts 10 \
    --derivation-path "m/44'/60'/0'/0/" \
    --silent \
    > "${ANVIL_LOG}" 2>&1 &
ANVIL_PID=$!

echo "[*] Waiting for Anvil JSON-RPC"
for _ in {1..30}; do
    if curl -sf -H "Content-Type: application/json" --data "${RPC_PROBE}" "${RPC_URL}" >/dev/null 2>&1; then
        break
    fi
    sleep 0.5
done

if ! curl -sf -H "Content-Type: application/json" --data "${RPC_PROBE}" "${RPC_URL}" >/dev/null 2>&1; then
    echo "[!] Failed to connect to Anvil at ${RPC_URL}"
    exit 1
fi

echo "[*] Building contracts"
(cd "${ROOT_DIR}" && forge build >/dev/null)

artifact_bytecode() {
    local artifact="$1"
    jq -r '.bytecode.object' "${artifact}"
}

encode_constructor() {
    local signature="$1"; shift
    cast abi-encode "${signature}" "$@"
}

deploy_contract() {
    local bytecode="$1"
    local constructor_data="$2"
    local label="$3"
    local payload="${bytecode}${constructor_data#0x}"
    local json
    json=$(cast send \
        --private-key "${OWNER_PK}" \
        --rpc-url "${RPC_URL}" \
        --chain-id "${CHAIN_ID}" \
        --create "${payload}" \
        --json)
    local address
    address=$(echo "${json}" | jq -r '.contractAddress // .createdContract')
    if [[ -z "${address}" || "${address}" == "null" ]]; then
        echo "[!] Failed to deploy ${label}"
        echo "${json}"
        exit 1
    fi
    echo "    Deployed ${label} at ${address}" >&2
    echo "${address}"
}

echo "[*] Deploying YurtFraction"
YURT_ARTIFACT="${ROOT_DIR}/out/YurtFraction.sol/YurtFraction.json"
YURT_BYTECODE=$(artifact_bytecode "${YURT_ARTIFACT}")
if [[ -z "${YURT_BYTECODE}" || "${YURT_BYTECODE}" == "0x" ]]; then
    echo "[!] Missing YurtFraction bytecode in ${YURT_ARTIFACT}"
    exit 1
fi
YURT_CONSTRUCTOR=$(encode_constructor "constructor(string,string,uint256,string,address)" \
    "Blue Meadow Yurt Shares" "YURT" "${TOTAL_SUPPLY}" "ipfs://bafy...bundle" "${OWNER_ADDR}")
YURT_ADDR=$(deploy_contract "${YURT_BYTECODE}" "${YURT_CONSTRUCTOR}" "YurtFraction")
echo "    Deployed YurtFraction at ${YURT_ADDR}"

echo "[*] Deploying ERC20Mock (UZS stablecoin placeholder)"
UZS_ARTIFACT="${ROOT_DIR}/out/ERC20Mock.sol/ERC20Mock.json"
if [[ ! -f "${UZS_ARTIFACT}" ]]; then
    UZS_ARTIFACT="${ROOT_DIR}/out/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol/ERC20Mock.json"
fi
UZS_BYTECODE=$(artifact_bytecode "${UZS_ARTIFACT}")
if [[ -z "${UZS_BYTECODE}" || "${UZS_BYTECODE}" == "0x" ]]; then
    echo "[!] Missing ERC20Mock bytecode in ${UZS_ARTIFACT}"
    exit 1
fi
EMPTY_ARGS="0x"
UZS_ADDR=$(deploy_contract "${UZS_BYTECODE}" "${EMPTY_ARGS}" "ERC20Mock")
echo "    Deployed ERC20Mock at ${UZS_ADDR}"

echo "[*] Whitelisting investors"
cast send "${YURT_ADDR}" "addToWhitelist(address[])" "[${ALICE_ADDR},${BOB_ADDR}]" \
    --private-key "${OWNER_PK}" \
    --rpc-url "${RPC_URL}" \
    --chain-id "${CHAIN_ID}" >/dev/null

echo "[*] Distributing shares"
cast send "${YURT_ADDR}" "transfer(address,uint256)" "${ALICE_ADDR}" "${ALICE_SHARE}" \
    --private-key "${OWNER_PK}" --rpc-url "${RPC_URL}" --chain-id "${CHAIN_ID}" >/dev/null
cast send "${YURT_ADDR}" "transfer(address,uint256)" "${BOB_ADDR}" "${BOB_SHARE}" \
    --private-key "${OWNER_PK}" --rpc-url "${RPC_URL}" --chain-id "${CHAIN_ID}" >/dev/null

echo "[*] Funding UZS pot"
cast send "${UZS_ADDR}" "mint(address,uint256)" "${OWNER_ADDR}" "${UZS_MINT_TOTAL}" \
    --private-key "${OWNER_PK}" --rpc-url "${RPC_URL}" --chain-id "${CHAIN_ID}" >/dev/null
cast send "${UZS_ADDR}" "approve(address,uint256)" "${YURT_ADDR}" "${UZS_MINT_TOTAL}" \
    --private-key "${OWNER_PK}" --rpc-url "${RPC_URL}" --chain-id "${CHAIN_ID}" >/dev/null

echo "[*] Depositing rental income"
cast send "${YURT_ADDR}" "depositIncome(address,uint256)" "${UZS_ADDR}" "${INCOME_AMOUNT}" \
    --private-key "${OWNER_PK}" --rpc-url "${RPC_URL}" --chain-id "${CHAIN_ID}" >/dev/null

echo "[*] Starting income distribution"
cast send "${YURT_ADDR}" "startDistribution(address)" "${UZS_ADDR}" \
    --private-key "${OWNER_PK}" --rpc-url "${RPC_URL}" --chain-id "${CHAIN_ID}" >/dev/null
DISTRIBUTION_ID=1

validate_balance() {
    local contract="$1"
    local holder="$2"
    local expected="$3"
    local label="$4"
    local hex
    hex=$(cast call "${contract}" "balanceOf(address)(uint256)" "${holder}" --rpc-url "${RPC_URL}")

    # Log both raw and pretty, but never feed pretty text into parsers:
    echo "[debug] ${label} raw = ${hex}" >&2

    # If hex accidentally contains annotations like ' [1e20]', strip them:
    #   - take first whitespace-delimited token
    #   - also chop anything after a '[' just in case
    local cleaned="${hex%% *}"
    cleaned="${cleaned%%[*}"

    local actual
    actual=$(cast --to-dec "${cleaned}")

    if [[ "${actual}" != "${expected}" ]]; then
        echo "[!] ${label} balance mismatch: expected ${expected}, got ${actual}"
        exit 1
    fi
}

echo "[*] Claiming income for Alice"
cast send "${YURT_ADDR}" "claimIncome(uint256)" "${DISTRIBUTION_ID}" \
    --private-key "${ALICE_PK}" --rpc-url "${RPC_URL}" --chain-id "${CHAIN_ID}" >/dev/null
validate_balance "${UZS_ADDR}" "${ALICE_ADDR}" "${ALICE_INCOME_EXPECTED}" "Alice income"

echo "[*] Claiming income for Bob"
cast send "${YURT_ADDR}" "claimIncome(uint256)" "${DISTRIBUTION_ID}" \
    --private-key "${BOB_PK}" --rpc-url "${RPC_URL}" --chain-id "${CHAIN_ID}" >/dev/null
validate_balance "${UZS_ADDR}" "${BOB_ADDR}" "${BOB_INCOME_EXPECTED}" "Bob income"

echo "[*] Claiming income for Owner"
cast send "${YURT_ADDR}" "claimIncome(uint256)" "${DISTRIBUTION_ID}" \
    --private-key "${OWNER_PK}" --rpc-url "${RPC_URL}" --chain-id "${CHAIN_ID}" >/dev/null
validate_balance "${UZS_ADDR}" "${OWNER_ADDR}" "${OWNER_BALANCE_AFTER_INCOME}" "Owner post-income balance"

echo "[*] Depositing exit proceeds"
cast send "${YURT_ADDR}" "depositExitProceeds(address,uint256)" "${UZS_ADDR}" "${EXIT_AMOUNT}" \
    --private-key "${OWNER_PK}" --rpc-url "${RPC_URL}" --chain-id "${CHAIN_ID}" >/dev/null

echo "[*] Triggering exit"
cast send "${YURT_ADDR}" "triggerExit()" \
    --private-key "${OWNER_PK}" --rpc-url "${RPC_URL}" --chain-id "${CHAIN_ID}" >/dev/null

echo "[*] Redeeming Alice"
cast send "${YURT_ADDR}" "redeemOnExit(address)" "${UZS_ADDR}" \
    --private-key "${ALICE_PK}" --rpc-url "${RPC_URL}" --chain-id "${CHAIN_ID}" >/dev/null
validate_balance "${UZS_ADDR}" "${ALICE_ADDR}" "${ALICE_TOTAL_EXPECTED}" "Alice final"
validate_balance "${YURT_ADDR}" "${ALICE_ADDR}" "0" "Alice share balance"

echo "[*] Redeeming Bob"
cast send "${YURT_ADDR}" "redeemOnExit(address)" "${UZS_ADDR}" \
    --private-key "${BOB_PK}" --rpc-url "${RPC_URL}" --chain-id "${CHAIN_ID}" >/dev/null
validate_balance "${UZS_ADDR}" "${BOB_ADDR}" "${BOB_TOTAL_EXPECTED}" "Bob final"
validate_balance "${YURT_ADDR}" "${BOB_ADDR}" "0" "Bob share balance"

echo "[*] Redeeming Owner"
cast send "${YURT_ADDR}" "redeemOnExit(address)" "${UZS_ADDR}" \
    --private-key "${OWNER_PK}" --rpc-url "${RPC_URL}" --chain-id "${CHAIN_ID}" >/dev/null
validate_balance "${UZS_ADDR}" "${OWNER_ADDR}" "${OWNER_TOTAL_EXPECTED}" "Owner final"

echo "[*] Verifying supply and pots are cleared"
TOTAL_SUPPLY_HEX=$(cast call "${YURT_ADDR}" "totalSupply()(uint256)" --rpc-url "${RPC_URL}")
if [[ "$(cast --to-dec "${TOTAL_SUPPLY_HEX}")" != "0" ]]; then
    echo "[!] Total supply not zero after redemptions"
    exit 1
fi

EXIT_POT_HEX=$(cast call "${YURT_ADDR}" "exitPot(address)(uint256)" "${UZS_ADDR}" --rpc-url "${RPC_URL}")
if [[ "$(cast --to-dec "${EXIT_POT_HEX}")" != "0" ]]; then
    echo "[!] Exit pot not fully distributed"
    exit 1
fi

TOKEN_BAL_HEX=$(cast call "${UZS_ADDR}" "balanceOf(address)(uint256)" "${YURT_ADDR}" --rpc-url "${RPC_URL}")
if [[ "$(cast --to-dec "${TOKEN_BAL_HEX}")" != "0" ]]; then
    echo "[!] Token contract still holds residual UZS"
    exit 1
fi

echo "[*] All CLI-based Anvil tests passed"
