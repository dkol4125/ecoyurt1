# Operations Checklist (Linux Deployment Hosts)

These instructions target a clean Linux server (Ubuntu/Debian) with no blockchain tooling installed. They take you from a blank machine to a verified build ready for further integration or auditing. No production deployment is described, as the contracts remain a technical reference only.

---

## 1. Install Required Packages

```sh
sudo apt update
sudo apt install -y build-essential git curl pkg-config libssl-dev
```

---

## 2. Install Foundry

```sh
curl -L https://foundry.paradigm.xyz | bash
source ~/.foundry/bin/foundryup    # loads forge/anvil into PATH
```

Run `foundryup` again in the future to pick up new releases.

---

## 3. Fetch the Repository

```sh
git clone https://github.com/dkol4125/ecoyurt1.git
cd ecoyurt1
```

If you are checking out a specific release, use the corresponding Git tag:

```sh
git fetch --tags
git checkout v0.1.0   # example tag
```

---

## 4. Install Solidity Dependencies

```sh
forge install OpenZeppelin/openzeppelin-contracts@v5.4.0
forge install foundry-rs/forge-std@v1.9.6
```

This ensures the exact audited versions referenced by the project are present under `lib/`.

---

## 5. Run Integrity Checks

```sh
forge build
forge test -vv
forge coverage --report lcov --out lcov.info
python3 build/scripts/check-lcov-coverage.py
```

All commands must succeed; the coverage checker enforces 100 % line coverage for contracts under `src/`.

---

## 6. Next Steps & Compliance

* Review `DISCLAIMER.md` and consult qualified legal counsel before any real-world use.
* Ensure downstream systems integrate with the repository’s CI pipeline (`.github/workflows/ci.yml`) so every build enforces unit tests and coverage.
* Maintain release notes and version tags through Git; do **not** distribute unsigned artifacts.

---

The above checklist prepares a Linux host to audit or extend the project while guaranteeing that all enforced quality gates (tests + coverage) pass exactly as in CI.
