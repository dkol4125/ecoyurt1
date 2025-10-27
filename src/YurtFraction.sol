// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {ERC20Snapshot} from "./utils/ERC20Snapshot.sol";

interface IERC20Like {
    function totalSupply() external view returns (uint256);
    function balanceOf(address a) external view returns (uint256);
    function approve(address s, uint256 amt) external returns (bool);
    function transfer(address to, uint256 amt) external returns (bool);
    function transferFrom(
        address f,
        address t,
        uint256 amt
    ) external returns (bool);
}

/// @title YurtFraction
/// @notice ERC20 representing fractional property shares with income distribution and exit mechanics.
/// @dev Single privileged owner; uses snapshot for distributions; supports whitelist, pause, exit + burn.
contract YurtFraction is ERC20Snapshot, Ownable, ReentrancyGuard {
    // ========= Property metadata =========
    string public propertyURI;
    event PropertyURIUpdated(string newURI);

    // ========= Units per yurt =========
    uint256 public immutable SHARES_PER_YURT;

    // ========= Whitelist & pause =========
    mapping(address => bool) private _whitelisted; // Transfer gating for KYC/AML compliance
    event WhitelistUpdated(address indexed account, bool allowed);
    bool private _paused;
    event Paused(address indexed by);
    event Unpaused(address indexed by);

    // ========= Distributions =========
    mapping(uint256 => address) public distributionAsset;
    mapping(uint256 => uint256) public distributionPot;
    mapping(uint256 => mapping(address => bool)) public incomeClaimed;
    event DistributionStarted(
        uint256 indexed id,
        address indexed asset,
        uint256 snapshotId
    );
    event IncomeDeposited(address indexed asset, uint256 amount);
    event IncomeClaimed(
        uint256 indexed id,
        address indexed holder,
        address indexed asset,
        uint256 amount
    );

    // ========= Exit / Redemption =========
    bool public exitTriggered;
    mapping(address => uint256) public exitPot;
    event ExitTriggered();
    event ExitDeposited(address indexed asset, uint256 amount);
    event Redeemed(
        address indexed holder,
        uint256 burned,
        address indexed asset,
        uint256 paid
    );

    // ========= Errors =========
    error NotWhitelisted();
    error TransfersPaused();
    error ExitLive();
    error ZeroAmount();
    error AlreadyClaimed();
    error InvalidAsset();
    error NoBalance();
    error TransferFailed();

    // ========= Constructor =========
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 totalShares,
        string memory propertyUri,
        address initialOwner
    ) ERC20(tokenName, tokenSymbol) Ownable(initialOwner) {
        propertyURI = propertyUri;
        _whitelisted[initialOwner] = true; // Ensure deployer can recover tokens before minting
        emit WhitelistUpdated(initialOwner, true);

        _mint(initialOwner, totalShares);
        // define 10,000 shares per yurt (token decimals assumed 18)
        SHARES_PER_YURT = 10_000 * (10 ** decimals());
    }

    // ========= Metadata =========
    function setPropertyURI(string calldata newURI) external onlyOwner {
        propertyURI = newURI;
        emit PropertyURIUpdated(newURI);
    }

    // ========= Whitelist & Pause Control =========
    function addToWhitelist(address[] calldata addrs) external onlyOwner {
        for (uint256 i; i < addrs.length; i++) {
            _whitelisted[addrs[i]] = true;
            emit WhitelistUpdated(addrs[i], true);
        }
    }

    function removeFromWhitelist(address[] calldata addrs) external onlyOwner {
        for (uint256 i; i < addrs.length; i++) {
            _whitelisted[addrs[i]] = false;
            emit WhitelistUpdated(addrs[i], false);
        }
    }

    function isWhitelisted(address a) external view returns (bool) {
        return _whitelisted[a];
    }

    function pause() external onlyOwner {
        if (!_paused) {
            _paused = true;
            emit Paused(_msgSender());
        }
    }

    function unpause() external onlyOwner {
        if (_paused) {
            _paused = false;
            emit Unpaused(_msgSender());
        }
    }

    // ========= Income Distributions =========

    function depositIncome(address asset, uint256 amount) external onlyOwner {
        if (asset == address(0)) revert InvalidAsset();
        if (amount == 0) revert ZeroAmount();
        bool ok = IERC20Like(asset).transferFrom(_msgSender(), address(this), amount); // Pull trusted stablecoin from owner
        if (!ok) revert TransferFailed();
        emit IncomeDeposited(asset, amount);
    }

    function startDistribution(
        address asset
    ) external onlyOwner returns (uint256 id) {
        if (asset == address(0)) revert InvalidAsset();
        uint256 pot = IERC20Like(asset).balanceOf(address(this));
        if (pot == 0) revert ZeroAmount();

        uint256 snapshotId = _snapshot();
        id = snapshotId;
        distributionAsset[id] = asset;
        distributionPot[id] = pot;

        emit DistributionStarted(id, asset, snapshotId);
    }

    function claimIncome(uint256 id) external nonReentrant {
        address asset = distributionAsset[id];
        if (asset == address(0)) revert InvalidAsset();
        if (incomeClaimed[id][_msgSender()]) revert AlreadyClaimed();

        uint256 supplyAt = totalSupplyAt(id);
        if (supplyAt == 0) {
            incomeClaimed[id][_msgSender()] = true;
            return;
        }

        uint256 balAt = balanceOfAt(_msgSender(), id);
        uint256 pot = distributionPot[id];
        uint256 payout = (pot * balAt) / supplyAt;

        incomeClaimed[id][_msgSender()] = true;
        if (payout > 0) {
            bool ok = IERC20Like(asset).transfer(_msgSender(), payout);
            if (!ok) revert TransferFailed();
        }
        emit IncomeClaimed(id, _msgSender(), asset, payout);
    }

    function claimableIncome(
        uint256 id,
        address holder
    ) external view returns (address asset, uint256 amount) {
        asset = distributionAsset[id];
        if (asset == address(0) || incomeClaimed[id][holder]) return (asset, 0);
        uint256 supplyAt = totalSupplyAt(id);
        if (supplyAt == 0) return (asset, 0);
        uint256 balAt = balanceOfAt(holder, id);
        amount = (distributionPot[id] * balAt) / supplyAt;
    }

    // ========= Exit / Redemption =========

    function triggerExit() external onlyOwner {
        if (!exitTriggered) {
            exitTriggered = true;
            emit ExitTriggered();
        }
    }

    function depositExitProceeds(
        address asset,
        uint256 amount
    ) external onlyOwner {
        if (asset == address(0)) revert InvalidAsset();
        if (amount == 0) revert ZeroAmount();
        bool ok = IERC20Like(asset).transferFrom(_msgSender(), address(this), amount); // Owner funds pool; contract holds custody
        if (!ok) revert TransferFailed();
        exitPot[asset] += amount;
        emit ExitDeposited(asset, amount);
    }

    function redeemOnExit(address asset) external nonReentrant {
        if (!exitTriggered) revert ExitLive();
        if (asset == address(0)) revert InvalidAsset();

        uint256 bal = balanceOf(_msgSender());
        if (bal == 0) revert NoBalance();

        uint256 supply = totalSupply();
        uint256 pot = exitPot[asset];
        uint256 payout = (pot * bal) / supply;

        _burn(_msgSender(), bal);
        exitPot[asset] -= payout;

        bool ok = IERC20Like(asset).transfer(_msgSender(), payout);
        if (!ok) revert TransferFailed();
        emit Redeemed(_msgSender(), bal, asset, payout);
    }

    function claimableExit(
        address asset,
        address holder
    ) external view returns (uint256) {
        if (!exitTriggered || asset == address(0)) return 0;
        uint256 supply = totalSupply();
        if (supply == 0) return 0;
        uint256 bal = balanceOf(holder);
        return (exitPot[asset] * bal) / supply;
    }

    // ========= Transfer Override =========

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Snapshot) {
        if (_paused) revert TransfersPaused(); // Freeze all movement when paused
        if (exitTriggered && to != address(0)) revert ExitLive(); // No secondary transfers once exit starts

        if (from != address(0) && !_whitelisted[from]) revert NotWhitelisted();
        if (to != address(0) && !_whitelisted[to]) revert NotWhitelisted();

        super._update(from, to, amount);
    }
}
