# Production Deployment Guide (Ethereum Testnet & Mainnet)

> **Warning**
>
> The contracts in this repository are provided for educational purposes only (see `DISCLAIMER.md`). Do **not** deploy to public networks without regulatory approval, professional audits, and appropriate operational controls. The instructions below outline a technical workflow for teams who have already satisfied those requirements.

This document assumes a hardened Linux host with no blockchain tooling pre-installed. Replace placeholder values (`...`) with your own infrastructure secrets.

---

## 1. Base System Preparation (Linux)

```sh
sudo apt update
sudo apt install -y build-essential git curl pkg-config libssl-dev
```

---

## 2. Install Foundry Toolchain

```sh
curl -L https://foundry.paradigm.xyz | bash
source ~/.foundry/bin/foundryup   # loads forge/anvil into PATH
```

Re-run `foundryup` periodically to receive security updates.

---

## 3. Fetch the Release Snapshot

```sh
git clone https://github.com/dkol4125/ecoyurt1.git
cd ecoyurt1
git fetch --tags
git checkout v0.1.0   # replace with the audited release tag
```

---

## 4. Install Solidity Dependencies

```sh
forge install OpenZeppelin/openzeppelin-contracts@v5.4.0
forge install foundry-rs/forge-std@v1.9.6
```

---

## 5. Pre-Deployment Verification

```sh
forge build
forge test -vv
forge coverage --report lcov --out lcov.info
python3 build/scripts/check-lcov-coverage.py   # must report 100% coverage
```

Archive `lcov.info` along with the release artifacts for audit trails, then remove it from the working tree (`rm lcov.info`).

---

## 6. Secure Environment Configuration

Create `/etc/ecoyurt/credentials` (or a similar secure location) with root-readable permissions only (e.g., `chmod 600`). Define the following shell variables before broadcasting any transactions:

```sh
export TESTNET_RPC_URL=https://sepolia.infura.io/v3/...
export MAINNET_RPC_URL=https://mainnet.infura.io/v3/...
export DEPLOYER_PK=0x...            # Prefer hardware wallets; never hard-code in scripts
export ETHERSCAN_API_KEY=...
```

Never commit these values to version control. Use short-lived session shells or a secret manager.

---

## 7. Dry-Run on Ethereum Testnet (e.g., Sepolia)

```sh
$ forge script script/Deploy.s.sol:Deploy \
    --rpc-url "$TESTNET_RPC_URL" \
    --broadcast \
    --skip-simulation \
    --etherscan-api-key "$ETHERSCAN_API_KEY" \
    --verify
```

*Record the deployed contract address and transaction hash.* Run integration checks:

```sh
$ forge script script/LocalAnvilTest.s.sol:LocalAnvilTest \
    --rpc-url "$TESTNET_RPC_URL" \
    --broadcast
```

The smoke script should pass without reverts. If it fails, diagnose and redeploy.

---

## 8. Mainnet Deployment

After successful testnet validation and stakeholder approval:

```sh
$ forge script script/Deploy.s.sol:Deploy \
    --rpc-url "$MAINNET_RPC_URL" \
    --broadcast \
    --skip-simulation \
    --etherscan-api-key "$ETHERSCAN_API_KEY" \
    --verify
```

Immediately export the deployed address, transaction hash, and the exact Git commit SHA into your compliance records.

---

## 9. Post-Deployment Checklist

- ✅ Confirm the contract appears on Etherscan with verified source.
- ✅ Update internal documentation with the deployed addresses and ABI.
- ✅ Run a final coverage check and store the artifacts.
- ✅ Rotate any exposed API keys or temporary secrets used during deployment.

---

## 10. Regulatory & Operational Notes

- Consult Uzbek financial regulators and legal counsel prior to any mainnet use.
- Maintain multi-signature controls for the privileged owner account and segregate keys from deployment hosts.
- Schedule recurring third-party audits after each significant code change, even if coverage is enforced.

---

Following this guide ensures every production deployment is reproducible: the source is tied to a signed Git tag, all tests and coverage checks are executed, and the broadcast steps are tracked on both testnet and mainnet.
