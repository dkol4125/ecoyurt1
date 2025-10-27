# EcoYurt (EYR) — Fractional Real-Estate Token

[🇬🇧 English](./README.md)  
[🇺🇿 Oʻzbekcha](./README.uz.md)  
[🇷🇺 Русский](./README.ru.md)

---

![CI](https://github.com/dkol4125/ecoyurt1/actions/workflows/ci.yml/badge.svg)
![Coverage](https://img.shields.io/badge/Coverage-100%25-brightgreen)
![License](https://img.shields.io/badge/License-MIT-blue)
![Version](https://img.shields.io/badge/Version-0.1.0-informational)
![Dependencies](https://img.shields.io/badge/Dependencies-Forge%20std%20%26%20OpenZeppelin-success)

> **LEGAL DISCLAIMER:** This repository provides an illustrative, example-only ERC‑20 token design intended for educational and demonstration purposes. It is **not** a production‑grade implementation, has **not** undergone security review, and should **not** be deployed for real‑world financial activity. Nothing herein constitutes legal, financial, or regulatory advice.

A minimal ERC-20 token for fractional ownership of yurts in Uzbekistan, with built-in income distribution and exit mechanics. This implementation is intended strictly as an example and must not be used as-is in production environments.

---

## Highlights

- Fixed supply: designed for “10,000 EYR = 1 yurt”.  
- Whitelist-gated transfers (KYC/AML ready).  
- Snapshot-based income payouts (in a UZS-pegged stable token).  
- Clean exit flow: sale proceeds in UZS-token → holders redeem pro-rata and burn.
- Example‑only reference implementation; **not** production ready.

---

## Key Flows

### Admin Setup

1. Deploy with total shares = **number of yurts × 10,000 EYR × 10ⁿ decimals**.  
2. Whitelist the admin and initial investors.  
3. Transfers among whitelisted wallets only.

### Income Distribution

1. Admin deposits UZS-stable asset (e.g., pilot token) via `depositIncome`.  
2. Call `startDistribution` → snapshot taken.  
3. Investors call `claimIncome` → get their share based on snapshot.

### Exit & Redemption

1. Admin deposits exit proceeds in UZS-asset via `depositExitProceeds`.  
2. Call `triggerExit()` → all transfers now blocked.  
3. Investors call `redeemOnExit(asset)` → receive payout and tokens burn.

---

## Configuration Notes

- **Payout asset**: Use a UZS-pegged ERC-20 (e.g., the state-backed token in Uzbekistan).  
- **Supply unit**: `SHARES_PER_YURT = 10,000 × 10^decimals()` (constant in contract).  
- **Whitelisting & pause**: Controlled by owner (ideally a multisig).  
- **No upgrades**, no speculative token behavior — purely asset-backed.
This design intentionally omits critical production concerns such as audits, compliance modules, extensibility, and operational hardening.

---

## Dev Setup

```bash
# use Foundry
forge install OpenZeppelin/openzeppelin-contracts
forge build
forge test -vv
# run coverage
forge coverage --report lcov --out lcov.info
python3 build/scripts/check-lcov-coverage.py
```

---

## Automated Test Scenarios

See `TESTS.md` for a continuously updated list of real-world scenarios covered by the automated test suite.

---

## Legal & Regulatory Notice

This codebase is provided **as‑is** with **no warranties** of any kind. Deploying tokenized assets may require regulatory authorization depending on jurisdiction. Consult qualified legal counsel and conduct independent audits before using any blockchain software in production.

---
