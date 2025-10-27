# Owner Operations Guide (Multisig Administrator)

> **Context**: The `YurtFraction` contract is designed for a single privileged owner, typically controlled by a multisignature wallet. This document describes how that multisig should manage the token lifecycle end to end. All transactions should be proposed and executed through your multisig UI (e.g., Safe / Gnosis Safe). Replace placeholder values with your actual addresses.

---

## 1. Prerequisites

- Contract address: `0x...` (fill in after deployment)
- Multisig owner address: `0x...`
- Stablecoin(s) used for income/exit distributions (e.g., UZS-pegged ERC‑20)
- RPC access to the chain (testnet or mainnet) and a block explorer for verification

Keep the `YurtFraction` ABI handy (from `forge build` or Etherscan) so you can craft calldata accurately.

---

## 2. Initial Deployment & Setup

1. **Deploy** the contract via the approved deployment process (see `SETUP.prod.md`).
2. **Confirm Ownership**: In the block explorer, verify `owner()` equals your multisig address.
3. **Whitelist Initial Holders**:
   - Function: `addToWhitelist(address[] accounts)`
   - Inputs: array of investor addresses (including the multisig itself)
   - Rationale: only whitelisted accounts can send/receive tokens.
4. **Distribute Tokens** (if not done at deployment): use the private distribution agreement to send tokens from the multisig to investors while both parties are whitelisted.
5. **Record Metadata**: Set initial property URI if needed via `setPropertyURI(string newURI)` (e.g., IPFS link to disclosures).

Always submit these actions as multisig proposals and collect the required signatures before execution.

---

## 3. Routine Administrative Tasks

### 3.1 Whitelisting & Offboarding Investors

- **Add**: `addToWhitelist(address[] accounts)`
- **Remove**: `removeFromWhitelist(address[] accounts)`

Keep your compliance ledger in sync with on-chain whitelisting. Remove addresses promptly when investors exit.

### 3.2 Pause / Unpause Transfers

- `pause()` temporarily blocks all transfers (except mint/burn inside contract logic).
- `unpause()` resumes transfers.

Use only during emergencies or regulatory mandates. Notify investors before pausing when possible.

### 3.3 Metadata Updates

- `setPropertyURI(string newURI)` to publish updated disclosure documents (IPFS hash, HTTPS URL, etc.).

Document every metadata change and keep prior versions archived for audits.

---

## 4. Income Distribution Workflow

1. **Collect Stablecoin Income** off-chain into the multisig.
2. **Whitelist Stablecoin**: confirm the payout token contract address (should already be approved during deployment).
3. **Deposit Funds**:
   - Function: `depositIncome(address asset, uint256 amount)`
   - `asset` = stablecoin address, `amount` = total distribution amount.
   - Ensure `approve` has been granted from the multisig to the `YurtFraction` contract for at least `amount`.
4. **Start Distribution**:
   - `startDistribution(address asset)`
   - Takes a snapshot of balances and locks the distribution pot.
   - Returns a snapshot ID (record it for reporting).
5. **Investor Claims**: Holders call `claimIncome(uint256 id)` individually. Monitor outstanding balances via `claimableIncome`.

The multisig does not need further action after step 4 unless investors report issues.

---

## 5. Exit / Redemption Process

1. **Enter Exit Mode**: After selling the underlying asset, call `triggerExit()`.
2. **Deposit Proceeds**:
   - `depositExitProceeds(address asset, uint256 amount)` for each payout asset (repeat if multiple).
   - Ensure sufficient stablecoin allowance to the token contract.
3. **Investor Redemption**: Holders call `redeemOnExit(address asset)` to burn their tokens and receive payouts.
4. **Monitoring**: Track remaining `exitPot[asset]` and `totalSupply()` until both reach zero. Investigate any residual balances and resolve before closing the book.

Exit mode permanently blocks new transfers; only redemptions (burns) are allowed afterwards.

---

## 6. Emergency & Governance Procedures

1. **Emergency Pause**:
   - If suspicious activity is detected, call `pause()` immediately.
   - Conduct incident response, then `unpause()` once resolved.
2. **Key Rotation**:
   - If the multisig participants change, deploy a new multisig and transfer ownership via `transferOwnership(newOwner)` (executed from the old multisig).
3. **Contract Upgrades**:
   - Not supported. Any fixes require a new deployment and token migration plan.
4. **Audit Trail**:
   - Maintain a chronological log of all multisig transactions (Safe transaction list or custom ledger).
   - Cross-reference with off-chain compliance records.

---

## 7. Reporting Checklist

For each distribution or exit, update your internal reports with:

| Item | Details |
|------|---------|
| Snapshot / Distribution ID | Returned by `startDistribution` |
| Asset Address | Stablecoin contract used |
| Amount Deposited | Exact on-chain value |
| Transaction Hash | For both deposit and trigger calls |
| Claim Completion | Percentage of investors who have claimed |

Share the report with compliance officers and external auditors as required.

---

## 8. Security Recommendations

- Use hardware wallets to confirm each multisig signature.
- Enable on-chain module(s) (e.g., Safe guards) to require two-step approvals for critical functions.
- Limit RPC endpoints to trusted providers with rate limiting and monitoring.
- Periodically run `forge test` and `forge coverage` against the deployed commit to ensure no untracked changes are waiting to be redeployed without review.

---

Following this playbook ensures the multisig administrator can onboard investors, manage regular income distributions, handle exit redemptions, and respond to emergencies—all while keeping detailed records suitable for regulators and auditors.
