# Developer Setup (Mac OS & Linux)

These steps assume a clean machine with only the OS pre-installed. Commands prefixed with `macOS$` are for Mac OS terminals; `linux$` denotes Linux shells (Ubuntu/Debian). Run everything from your home directory unless stated otherwise.

---

## 1. Install Command-Line Basics

### Mac OS

```sh
macOS$ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
macOS$ echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
macOS$ eval "$(/opt/homebrew/bin/brew shellenv)"
macOS$ brew install git curl
```

### Linux (Ubuntu/Debian)

```sh
linux$ sudo apt update
linux$ sudo apt install -y build-essential git curl pkg-config libssl-dev
```

---

## 2. Install Foundry Toolchain

Foundry provides `forge`, `anvil`, and other tools used throughout the project.

```sh
curl -L https://foundry.paradigm.xyz | bash
source ~/.foundry/bin/foundryup
```

(Re-run `foundryup` whenever you need the latest version.)

---

## 3. Retrieve the Repository

```sh
git clone https://github.com/dkol4125/ecoyurt1.git
cd ecoyurt1
```

---

## 4. Install Solidity Dependencies

```sh
forge install OpenZeppelin/openzeppelin-contracts@v5.4.0
forge install foundry-rs/forge-std@v1.9.6
```

These commands populate the `lib/` directory with audited building blocks and the Foundry standard library.

---

## 5. Validate the Toolchain

```sh
forge build                     # Compile smart contracts
forge test -vv                  # Run the full test suite with verbose output
forge coverage --report lcov --out lcov.info
python3 build/scripts/check-lcov-coverage.py  # Enforce 100% src/ coverage
```

If the coverage script reports failure, examine the generated `lcov.info` (or re-run `forge coverage`) to determine what needs additional testing.

---

## 6. Useful Local Commands

| Task                                 | Command |
|--------------------------------------|---------|
| Format contracts & tests             | `forge fmt` |
| Update README translations           | `./build/scripts/update-localized-readmes.sh` |
| Refresh test scenario summary        | `./build/scripts/update-test-scenarios.sh` |
| Run smoke script against local Anvil | `forge script script/LocalAnvilTest.s.sol:LocalAnvilTest --rpc-url http://127.0.0.1:8545 --broadcast` |

---

## 7. Optional: macOS GUI Tools

* [iTerm2](https://iterm2.com/) or [Warp](https://www.warp.dev/) for a modern terminal.
* [Visual Studio Code](https://code.visualstudio.com/) with the Solidity and EditorConfig extensions for smart-contract editing.

---

With these steps complete, you can modify the contracts, run the test suite, and generate coverage locally on Mac OS or Linux without any prior blockchain experience.
