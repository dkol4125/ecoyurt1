#!/usr/bin/env bash
# Purpose: Operator-friendly smoke test driven by a Foundry script.
# What it does:
# - Boots a local Anvil node with the standard mnemonic
# - Runs script/LocalAnvilTest.s.sol to deploy and exercise flows
# - Verifies whitelisting, share transfers, income claim, exit redemption
# Why this matters: Provides a single command to validate the end-to-end
# behavior exactly as described in the README, boosting operator confidence
# before real deployments or after changes.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RPC_URL="${RPC_URL:-http://127.0.0.1:8545}"
ANVIL_BIN="${ANVIL_BIN:-anvil}"
MNEMONIC="${ANVIL_MNEMONIC_OVERRIDE:-test test test test test test test test test test test junk}"
ANVIL_LOG="${ANVIL_LOG:-/tmp/eyr-local-anvil.log}"

cleanup() {
    if [[ -n "${ANVIL_PID:-}" ]] && ps -p "${ANVIL_PID}" > /dev/null 2>&1; then
        kill "${ANVIL_PID}" >/dev/null 2>&1 || true
        wait "${ANVIL_PID}" 2>/dev/null || true
    fi
}
trap cleanup EXIT

echo "[*] Launching local Anvil node"
"${ANVIL_BIN}" \
    --host 127.0.0.1 \
    --port "${RPC_URL##*:}" \
    --mnemonic "${MNEMONIC}" \
    --chain-id 31337 \
    --silent \
    > "${ANVIL_LOG}" 2>&1 &
ANVIL_PID=$!

RPC_PROBE='{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

echo "[*] Waiting for Anvil to accept RPC connections at ${RPC_URL}"
for _ in {1..30}; do
    if curl -sf -H "Content-Type: application/json" --data "${RPC_PROBE}" "${RPC_URL}" >/dev/null 2>&1; then
        break
    fi
    sleep 0.5
done

if ! curl -sf -H "Content-Type: application/json" --data "${RPC_PROBE}" "${RPC_URL}" >/dev/null 2>&1; then
    echo "[!] Unable to reach Anvil on ${RPC_URL}"
    exit 1
fi

echo "[*] Running LocalAnvilTest Foundry script"
cd "${ROOT_DIR}"
forge script script/LocalAnvilTest.s.sol:LocalAnvilTest \
    --rpc-url "${RPC_URL}" \
    --broadcast \
    --skip-simulation \
    --slow \
    -vvvv

echo "[*] LocalAnvilTest script completed successfully"
