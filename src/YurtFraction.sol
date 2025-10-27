// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol"; // Reuse OZ implementation so auditors focus on distribution policy
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol"; // Concentrate privileged operations under one accountable entity
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // External token transfers require reentrancy protection to secure pots

interface IERC20Like {
    function totalSupply() external view returns (uint256);
    function balanceOf(address a) external view returns (uint256);
    function approve(address s, uint256 amt) external returns (bool);
    function transfer(address to, uint256 amt) external returns (bool);
    function transferFrom(address f, address t, uint256 amt) external returns (bool);
}

/// @title YurtFraction
/// @notice ERC20 representing fractional property shares with income distribution and exit mechanics.
/// @dev Single privileged owner; uses snapshot for distributions; supports whitelist, pause, exit + burn.
contract YurtFraction is ERC20, Ownable, ReentrancyGuard {
    // ========= Property metadata =========
    string public propertyURI; // Publish disclosure bundle so investors know which asset backs the shares
    event PropertyURIUpdated(string newURI);

    // ========= Units per yurt =========
    uint256 public immutable SHARES_PER_YURT; // Hard-code economic ratio to avoid governance drift from offering documents

    // ========= Whitelist & pause =========
    mapping(address => bool) private _whitelisted; // Enforce that only vetted wallets can transfer, satisfying compliance obligations
    event WhitelistUpdated(address indexed account, bool allowed);
    bool private _paused;
    event Paused(address indexed by);
    event Unpaused(address indexed by);

    // ========= Distributions =========
    mapping(uint256 => address) public distributionAsset;
    mapping(uint256 => uint256) public distributionPot;
    mapping(uint256 => mapping(address => bool)) public incomeClaimed;
    event DistributionStarted(uint256 indexed id, address indexed asset, uint256 snapshotId);
    event IncomeDeposited(address indexed asset, uint256 amount);
    event IncomeClaimed(uint256 indexed id, address indexed holder, address indexed asset, uint256 amount);

    // ========= Exit / Redemption =========
    bool public exitTriggered; // Once set we disallow secondary transfers so redemption math stays fixed
    mapping(address => uint256) public exitPot;
    event ExitTriggered();
    event ExitDeposited(address indexed asset, uint256 amount);
    event Redeemed(address indexed holder, uint256 burned, address indexed asset, uint256 paid);

    // ========= Errors =========
    error NotWhitelisted();
    error TransfersPaused();
    error ExitLive();
    error ZeroAmount();
    error AlreadyClaimed();
    error InvalidAsset();
    error NoBalance();
    error TransferFailed();
    error InvalidSnapshot();

    // ========= Snapshot storage =========
    address[] private _holders; // Maintain roster so snapshots can be materialized without iterating all addresses on demand
    mapping(address => bool) private _isHolder; // Prevent duplicate roster entries, keeping iteration bounded
    mapping(address => uint256) private _holderIndex; // Track positions to allow constant-time removals when balances drop to zero

    uint256 private _snapshotCounter; // Monotonic ids let auditors reconcile distributions chronologically
    mapping(uint256 => bool) private _snapshotSupplyWritten; // Avoid falling back to live supply when a snapshot intentionally stored zero
    mapping(uint256 => uint256) private _snapshotTotalSupply; // Freeze supply at distribution start so later burns do not change payouts
    mapping(uint256 => mapping(address => bool)) private _snapshotBalanceWritten; // Only persist balances that existed to minimize gas and storage
    mapping(uint256 => mapping(address => uint256)) private _snapshotBalances; // Preserve holder balances so reentrancy or transfers cannot skew entitlements

    // ========= Constructor =========
    /// @notice Deploys the EYR share token with a fixed supply per yurt, whitelists the issuer, and records the disclosure URI.
    /// @dev README outlines a 10,000 EYR per yurt ratio, so we mint exact shares scaled to 18 decimals and register the property pack link.
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 totalShares,
        string memory propertyUri,
        address initialOwner
    ) ERC20(tokenName, tokenSymbol) Ownable(initialOwner) {
        propertyURI = propertyUri;
        _whitelisted[initialOwner] = true; // Allow issuer to receive initial supply without tripping whitelist guards
        emit WhitelistUpdated(initialOwner, true);

        _mint(initialOwner, totalShares);
        _addHolder(initialOwner); // Seed roster so first snapshot accounts for issuer stake
        SHARES_PER_YURT = 10_000 * (10 ** decimals()); // Lock fractional ratio promised in off-chain prospectus despite future code upgrades
    }

    // ========= Metadata =========
    /// @notice Updates the property disclosure bundle URI so buyers always see current documents.
    /// @dev Keeps off-chain diligence material in sync without touching on-chain supply or UZS payout logic.
    function setPropertyURI(string calldata newURI) external onlyOwner {
        propertyURI = newURI;
        emit PropertyURIUpdated(newURI);
    }

    // ========= Whitelist & Pause Control =========
    /// @notice Grants KYC-cleared wallets permission to move EYR, aligning with regulated distribution described in the README.
    /// @dev Batch add reduces admin cost when onboarding multiple Uzbekistan investors at once.
    function addToWhitelist(address[] calldata addrs) external onlyOwner {
        for (uint256 i; i < addrs.length; i++) {
            _whitelisted[addrs[i]] = true;
            emit WhitelistUpdated(addrs[i], true);
        }
    }

    /// @notice Revokes transfer rights from wallets that failed compliance or offboarded.
    /// @dev Maintains the closed ecosystem required before exit, as outlined in the README scenarios.
    function removeFromWhitelist(address[] calldata addrs) external onlyOwner {
        for (uint256 i; i < addrs.length; i++) {
            _whitelisted[addrs[i]] = false;
            emit WhitelistUpdated(addrs[i], false);
        }
    }

    /// @notice Lets investors and integrators verify if a wallet may transfer EYR.
    /// @dev Mirrors whitelisting status without exposing internal mappings.
    function isWhitelisted(address a) external view returns (bool) {
        return _whitelisted[a];
    }

    /// @notice Temporarily halts share transfers when the issuer needs to investigate or satisfy regulator requests.
    /// @dev README mentions strong admin control; pause enforces that.
    function pause() external onlyOwner {
        if (!_paused) {
            _paused = true;
            emit Paused(_msgSender());
        }
    }

    /// @notice Restores normal trading once the issuer clears an incident or regulator inquiry.
    /// @dev Keeps investors informed via events while respecting whitelist gates.
    function unpause() external onlyOwner {
        if (_paused) {
            _paused = false;
            emit Unpaused(_msgSender());
        }
    }

    // ========= Income Distributions =========

    /// @notice Admin escrows UZS-pegged stablecoins (as recommended in the README) for the next rental-income distribution.
    /// @dev Requires the issuer to pre-fund the contract so holders never wait on off-chain promises.
    function depositIncome(address asset, uint256 amount) external onlyOwner {
        if (asset == address(0)) revert InvalidAsset(); // Force payouts to occur in ERC20 assets, not raw ETH or null
        if (amount == 0) revert ZeroAmount();
        bool ok = IERC20Like(asset).transferFrom(_msgSender(), address(this), amount); // Require issuer to escrow funds before promising distribution
        if (!ok) revert TransferFailed();
        emit IncomeDeposited(asset, amount);
    }

    /// @notice Locks a snapshot and records the pooled UZS-token amount so holders can claim rental income pro-rata.
    /// @dev This is step 2 of the README income flow; asset should match the stablecoin deposited previously.
    function startDistribution(address asset) external onlyOwner returns (uint256 id) {
        if (asset == address(0)) revert InvalidAsset();
        uint256 pot = IERC20Like(asset).balanceOf(address(this)); // Read actual balance to catch missed approvals or prior residuals
        if (pot == 0) revert ZeroAmount();

        uint256 snapshotId = ++_snapshotCounter;
        _recordSnapshot(snapshotId); // Persist state immediately so later transfers cannot retroactively change pro-rata weights

        id = snapshotId;
        distributionAsset[id] = asset;
        distributionPot[id] = pot;

        emit DistributionStarted(id, asset, snapshotId);
    }

    /// @notice Investors pull their portion of UZS income tied to a specific distribution snapshot.
    /// @dev Non-reentrancy plus stored balances guarantee each holder receives at most the amount earned, in the exact asset the admin deposited.
    function claimIncome(uint256 id) external nonReentrant {
        address asset = distributionAsset[id];
        if (asset == address(0)) revert InvalidAsset();
        if (incomeClaimed[id][_msgSender()]) revert AlreadyClaimed();

        uint256 supplyAt = _snapshotTotalSupply[id];
        if (supplyAt == 0) {
            incomeClaimed[id][_msgSender()] = true;
            return;
        }

        uint256 balAt = _snapshotBalances[id][_msgSender()];
        uint256 pot = distributionPot[id];
        uint256 payout = (pot * balAt) / supplyAt;

        incomeClaimed[id][_msgSender()] = true;
        if (payout > 0) {
            bool ok = IERC20Like(asset).transfer(_msgSender(), payout);
            if (!ok) revert TransferFailed();
        }
        emit IncomeClaimed(id, _msgSender(), asset, payout);
    }

    /// @notice Read-only estimator showing how much UZS-token income a wallet could still claim from a given distribution.
    /// @dev Off-chain apps display this so investors see pending payouts without sending a transaction.
    function claimableIncome(uint256 id, address holder) external view returns (address asset, uint256 amount) {
        asset = distributionAsset[id];
        if (asset == address(0) || incomeClaimed[id][holder]) return (asset, 0);
        uint256 supplyAt = _snapshotTotalSupply[id];
        if (supplyAt == 0) return (asset, 0);
        uint256 balAt = _snapshotBalances[id][holder];
        amount = (distributionPot[id] * balAt) / supplyAt;
    }

    /// @notice Returns how many EYR shares an address held when a distribution snapshot was taken.
    /// @dev Lets auditors reconcile payouts with historical balances during UZS income cycles.
    function balanceOfAt(address account, uint256 snapshotId) public view returns (uint256) {
        if (snapshotId == 0 || snapshotId > _snapshotCounter) revert InvalidSnapshot();
        if (!_snapshotBalanceWritten[snapshotId][account]) return balanceOf(account);
        return _snapshotBalances[snapshotId][account];
    }

    /// @notice Reports the total EYR supply recorded at a snapshot so distribution math remains transparent.
    /// @dev Prevents later burns or mints from skewing the divisor used for UZS payouts.
    function totalSupplyAt(uint256 snapshotId) public view returns (uint256) {
        if (snapshotId == 0 || snapshotId > _snapshotCounter) revert InvalidSnapshot();
        if (!_snapshotSupplyWritten[snapshotId]) return totalSupply();
        return _snapshotTotalSupply[snapshotId];
    }

    // ========= Exit / Redemption =========

    /// @notice Signals that the yurt portfolio is being liquidated and future transfers must stop ahead of redemptions.
    /// @dev Maps to step 2 of the README exit plan, guarding against secondary trades during payout preparation.
    function triggerExit() external onlyOwner {
        if (!exitTriggered) {
            exitTriggered = true;
            emit ExitTriggered();
        }
    }

    /// @notice Admin escrows sale proceeds in the agreed UZS stablecoin ahead of investor redemptions.
    /// @dev Requires the same ERC-20 asset described in the README exit flow, ensuring consistent currency for claims.
    function depositExitProceeds(address asset, uint256 amount) external onlyOwner {
        if (asset == address(0)) revert InvalidAsset();
        if (amount == 0) revert ZeroAmount();
        bool ok = IERC20Like(asset).transferFrom(_msgSender(), address(this), amount); // Owner funds pool; contract holds custody
        if (!ok) revert TransferFailed();
        exitPot[asset] += amount;
        emit ExitDeposited(asset, amount);
    }

    /// @notice Lets investors burn their EYR shares and pull their slice of the UZS exit pot once liquidation is live.
    /// @dev Uses current balances because transfers are frozen post-trigger, ensuring payout matches ownership at redemption.
    function redeemOnExit(address asset) external nonReentrant {
        if (!exitTriggered) revert ExitLive();
        if (asset == address(0)) revert InvalidAsset();

        uint256 bal = balanceOf(_msgSender());
        if (bal == 0) revert NoBalance();

        uint256 supply = totalSupply();
        uint256 pot = exitPot[asset];
        uint256 payout = (pot * bal) / supply; // Single pro-rata burn prevents leftover dust for honest redeemers

        _burn(_msgSender(), bal);
        exitPot[asset] -= payout;

        bool ok = IERC20Like(asset).transfer(_msgSender(), payout);
        if (!ok) revert TransferFailed();
        emit Redeemed(_msgSender(), bal, asset, payout);
    }

    /// @notice View helper showing how many UZS tokens a holder could redeem if they burned now.
    /// @dev Useful for dashboards mirroring the README exit checklist prior to interacting on-chain.
    function claimableExit(address asset, address holder) external view returns (uint256) {
        if (!exitTriggered || asset == address(0)) return 0;
        uint256 supply = totalSupply();
        if (supply == 0) return 0;
        uint256 bal = balanceOf(holder);
        return (exitPot[asset] * bal) / supply;
    }

    // ========= Transfer Override =========

    /// @notice Internal hook enforcing whitelist, pause, and exit restrictions whenever EYR moves.
    /// @dev Ensures every transfer respects the regulated Uzbek real-estate model, blocking trades after exit trigger.
    function _update(address from, address to, uint256 amount) internal override {
        if (_paused) revert TransfersPaused(); // Allow issuer to freeze in emergencies or regulatory holds
        if (exitTriggered && to != address(0)) revert ExitLive(); // Block secondary trades once exit terms are locked

        if (from != address(0) && !_whitelisted[from]) revert NotWhitelisted();
        if (to != address(0) && !_whitelisted[to]) revert NotWhitelisted();

        super._update(from, to, amount); // Delegate arithmetic to vetted OZ logic so business layer stays thin

        if (from != address(0) && balanceOf(from) == 0) {
            _removeHolder(from);
        }
        if (to != address(0) && balanceOf(to) > 0) {
            _addHolder(to);
        }
    }

    /// @notice Captures the holder roster and balances for a distribution so UZS income math is immutable.
    /// @dev Private helper called from `startDistribution`; keeps history reliable for auditors and dashboards.
    function _recordSnapshot(uint256 snapshotId) private {
        _snapshotSupplyWritten[snapshotId] = true;
        _snapshotTotalSupply[snapshotId] = totalSupply(); // Capture supply now so later burns cannot retroactively dilute claim checks
        uint256 len = _holders.length;
        for (uint256 i; i < len; ++i) {
            address holder = _holders[i];
            _snapshotBalanceWritten[snapshotId][holder] = true; // Mark stored balances so lookups never fall back to mutable state
            _snapshotBalances[snapshotId][holder] = balanceOf(holder); // Persist balance now to neutralize mid-claim transfer manipulations
        }
    }

    /// @notice Registers a wallet in the holder roster so future snapshots include its balance.
    /// @dev Keeps iteration bounded to current investors, preventing needless gas during Uzbek income runs.
    function _addHolder(address account) private {
        if (account == address(0) || _isHolder[account] || balanceOf(account) == 0) {
            return;
        }
        _holders.push(account); // Track addresses so distribution snapshots iterate only current investors
        _isHolder[account] = true; // Flag prevents duplicate entries that would skew pro-rata totals
        _holderIndex[account] = _holders.length; // Store 1-based index so removals keep array compact without linear search
    }

    /// @notice Evicts a wallet from the roster once it no longer holds EYR, trimming snapshot loops.
    /// @dev Avoids rewarding zero-balance wallets during UZS distributions or redemptions.
    function _removeHolder(address account) private {
        if (account == address(0) || !_isHolder[account] || balanceOf(account) != 0) {
            return;
        }
        uint256 index = _holderIndex[account];
        if (index == 0) return;
        uint256 lastIndex = _holders.length;
        if (index != lastIndex) {
            address last = _holders[lastIndex - 1];
            _holders[index - 1] = last; // Backfill hole with tail entry so loop bounds stay tight for next snapshot
            _holderIndex[last] = index; // Update cached index so swapped holder still resolves in O(1)
        }
        _holders.pop(); // Shrink array to avoid iterating stale addresses indefinitely
        _isHolder[account] = false; // Reset flag so re-adding later respects dedupe guard
        _holderIndex[account] = 0; // Zero out index to distinguish absent holders during future checks
    }
}
