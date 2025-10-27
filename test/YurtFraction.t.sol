// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {Test} from "forge-std/Test.sol";
import {YurtFraction} from "../src/YurtFraction.sol";

contract YurtFractionTest is Test {
    YurtFraction internal token;
    ERC20Mock internal uzs;

    address internal constant OWNER = address(0xABCD);
    address internal constant ALICE = address(0xBEEF);
    address internal constant BOB = address(0xCAFE);

    uint256 internal constant TOTAL_SUPPLY = 1_000_000 ether;
    uint256 internal constant SHARES_PER_YURT = 10_000 * 1e18;
    uint256 internal constant INCOME_AMOUNT = 1_000 ether;
    uint256 internal constant EXIT_AMOUNT = 5_000 ether;

    function setUp() public {
        token = new YurtFraction("Blue Meadow Yurt Shares", "YURT", TOTAL_SUPPLY, "ipfs://bafy...bundle", OWNER);
        uzs = new ERC20Mock();

        vm.label(OWNER, "owner");
        vm.label(ALICE, "alice");
        vm.label(BOB, "bob");
        vm.label(address(uzs), "uzsToken");
    }

    /*//////////////////////////////////////////////////////////////
                             INITIAL STATE
    //////////////////////////////////////////////////////////////*/

    function test_InitialState() public view {
        // Mirrors post-deployment state for a new property SPV.
        assertEq(token.name(), "Blue Meadow Yurt Shares");
        assertEq(token.symbol(), "YURT");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), TOTAL_SUPPLY);
        assertEq(token.balanceOf(OWNER), TOTAL_SUPPLY);
        assertEq(token.propertyURI(), "ipfs://bafy...bundle");
        assertEq(token.owner(), OWNER);
        assertTrue(token.isWhitelisted(OWNER));
        assertEq(token.SHARES_PER_YURT(), SHARES_PER_YURT);
    }

    /*//////////////////////////////////////////////////////////////
                              METADATA
    //////////////////////////////////////////////////////////////*/

    function test_SetPropertyURI_OnlyOwner() public {
        // Property manager updates disclosure docs (IPFS pointer) via multisig.
        vm.expectEmit(true, false, false, true);
        emit YurtFraction.PropertyURIUpdated("ipfs://newbundle");

        vm.prank(OWNER);
        token.setPropertyURI("ipfs://newbundle");
        assertEq(token.propertyURI(), "ipfs://newbundle");
    }

    function test_SetPropertyURI_RevertsForNonOwner() public {
        // Investor should not mutate regulated disclosures.
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, ALICE));
        vm.prank(ALICE);
        token.setPropertyURI("ipfs://nope");
    }

    /*//////////////////////////////////////////////////////////////
                           WHITELIST CONTROL
    //////////////////////////////////////////////////////////////*/

    function test_AddAndRemoveWhitelist() public {
        // Admin onboards/offboards investors to satisfy KYC requirements.
        _addWhitelist(ALICE);
        _addWhitelist(BOB);
        assertTrue(token.isWhitelisted(ALICE));
        assertTrue(token.isWhitelisted(BOB));

        _removeWhitelist(ALICE);
        assertEq(token.isWhitelisted(ALICE), false);
        assertTrue(token.isWhitelisted(BOB));
    }

    function test_AddToWhitelist_OnlyOwner() public {
        // Unauthorized wallet attempting to self-whitelist must fail.
        address[] memory accounts = new address[](1);
        accounts[0] = ALICE;

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, ALICE));
        vm.prank(ALICE);
        token.addToWhitelist(accounts);
    }

    function test_RemoveFromWhitelist_OnlyOwner() public {
        // Only compliance admin can revoke investor access.
        _addWhitelist(ALICE);

        address[] memory accounts = new address[](1);
        accounts[0] = ALICE;

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, ALICE));
        vm.prank(ALICE);
        token.removeFromWhitelist(accounts);
    }

    function test_TransferRequiresWhitelistedRecipient() public {
        // Prevent secondary-market trades with unvetted parties.
        vm.expectRevert(abi.encodeWithSelector(YurtFraction.NotWhitelisted.selector));
        vm.prank(OWNER);
        bool revertCheck = token.transfer(ALICE, 1 ether);
        revertCheck;
    }

    function test_TransferRequiresWhitelistedSender() public {
        // Blocks sanctioned wallet from initiating transfers.
        _addWhitelist(ALICE);
        vm.prank(OWNER);
        bool ok = token.transfer(ALICE, 10 ether);
        assertTrue(ok);

        _removeWhitelist(ALICE);

        _addWhitelist(BOB);
        vm.prank(OWNER);
        ok = token.transfer(BOB, 10 ether);
        assertTrue(ok);

        vm.expectRevert(abi.encodeWithSelector(YurtFraction.NotWhitelisted.selector));
        vm.prank(ALICE);
        bool revertCheckSender = token.transfer(BOB, 1 ether);
        revertCheckSender;
    }

    /*//////////////////////////////////////////////////////////////
                            PAUSE MECHANISM
    //////////////////////////////////////////////////////////////*/

    function test_PauseAndUnpause() public {
        // Simulates regulator-imposed pause and subsequent reopening.
        _addWhitelist(ALICE);
        vm.prank(OWNER);
        bool ok = token.transfer(ALICE, 10 ether);
        assertTrue(ok);

        vm.prank(OWNER);
        token.pause();

        vm.expectRevert(abi.encodeWithSelector(YurtFraction.TransfersPaused.selector));
        vm.prank(ALICE);
        bool pausedCheck = token.transfer(OWNER, 1 ether);
        pausedCheck;

        vm.prank(OWNER);
        token.unpause();

        vm.prank(ALICE);
        ok = token.transfer(OWNER, 1 ether);
        assertTrue(ok);
        assertEq(token.balanceOf(OWNER), TOTAL_SUPPLY - 9 ether);
    }

    function test_Pause_Unpause_OnlyOwner() public {
        // Verifies only governance entity can pause/unpause flow.
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, ALICE));
        vm.prank(ALICE);
        token.pause();

        vm.prank(OWNER);
        token.pause();

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, ALICE));
        vm.prank(ALICE);
        token.unpause();
    }

    /*//////////////////////////////////////////////////////////////
                            INCOME DISTRIBUTION
    //////////////////////////////////////////////////////////////*/

    function test_DepositIncome_HappyPath() public {
        // Property manager deposits rental income from stablecoin reserves.
        _fundIncome(INCOME_AMOUNT);
        assertEq(uzs.balanceOf(address(token)), INCOME_AMOUNT);
    }

    function test_DepositIncome_RevertsInvalidAsset() public {
        // Prevent mistakes that send raw ether or zero address asset.
        vm.expectRevert(abi.encodeWithSelector(YurtFraction.InvalidAsset.selector));
        vm.prank(OWNER);
        token.depositIncome(address(0), INCOME_AMOUNT);
    }

    function test_DepositIncome_RevertsZeroAmount() public {
        // Protect against accidental zero-value bookkeeping entries.
        vm.expectRevert(abi.encodeWithSelector(YurtFraction.ZeroAmount.selector));
        vm.prank(OWNER);
        token.depositIncome(address(uzs), 0);
    }

    function test_DepositIncome_OnlyOwner() public {
        // Only treasury wallet can fund income pot.
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, ALICE));
        vm.prank(ALICE);
        token.depositIncome(address(uzs), INCOME_AMOUNT);
    }

    function test_StartDistribution_RevertsWithoutPot() public {
        // Admin cannot trigger distribution if treasury forgot to deposit cash.
        vm.expectRevert(abi.encodeWithSelector(YurtFraction.ZeroAmount.selector));
        vm.prank(OWNER);
        token.startDistribution(address(uzs));
    }

    function test_StartDistribution_RecordsState() public {
        // Snapshot locks pro-rata entitlements for current investor ledger.
        _prepareDistributionShares();
        _fundIncome(INCOME_AMOUNT);

        vm.prank(OWNER);
        uint256 id = token.startDistribution(address(uzs));

        assertEq(id, 1);
        assertEq(token.distributionAsset(id), address(uzs));
        assertEq(token.distributionPot(id), INCOME_AMOUNT);
        assertEq(token.totalSupplyAt(id), TOTAL_SUPPLY);
    }

    function test_ClaimIncome_ProRataAndSingleUse() public {
        // Investors harvest their share of rental income exactly once.
        _prepareDistributionShares();
        _fundIncome(INCOME_AMOUNT);

        vm.prank(OWNER);
        uint256 id = token.startDistribution(address(uzs));

        uint256 aliceShare = token.balanceOf(ALICE);
        uint256 bobShare = token.balanceOf(BOB);
        uint256 ownerShare = token.balanceOf(OWNER);

        uint256 expectedAlice = (INCOME_AMOUNT * aliceShare) / TOTAL_SUPPLY;
        uint256 expectedBob = (INCOME_AMOUNT * bobShare) / TOTAL_SUPPLY;
        uint256 expectedOwner = (INCOME_AMOUNT * ownerShare) / TOTAL_SUPPLY;

        (address assetBefore, uint256 claimableAlice) = token.claimableIncome(id, ALICE);
        assertEq(assetBefore, address(uzs));
        assertEq(claimableAlice, expectedAlice);

        vm.prank(ALICE);
        token.claimIncome(id);
        assertEq(uzs.balanceOf(ALICE), expectedAlice);

        (assetBefore, claimableAlice) = token.claimableIncome(id, ALICE);
        assertEq(assetBefore, address(uzs));
        assertEq(claimableAlice, 0);

        vm.expectRevert(abi.encodeWithSelector(YurtFraction.AlreadyClaimed.selector));
        vm.prank(ALICE);
        token.claimIncome(id);

        vm.prank(BOB);
        token.claimIncome(id);
        assertEq(uzs.balanceOf(BOB), expectedBob);

        vm.prank(OWNER);
        token.claimIncome(id);
        assertEq(uzs.balanceOf(OWNER), expectedOwner);

        assertEq(uzs.balanceOf(address(token)), 0);
    }

    function test_ClaimIncome_ZeroSupply() public {
        YurtFraction zeroToken = new YurtFraction("Zero Supply", "ZERO", 0, "ipfs://bafy...zero", OWNER);
        ERC20Mock stable = new ERC20Mock();
        stable.mint(OWNER, 5 ether);
        vm.prank(OWNER);
        stable.approve(address(zeroToken), 5 ether);
        vm.prank(OWNER);
        zeroToken.depositIncome(address(stable), 5 ether);

        vm.prank(OWNER);
        uint256 id = zeroToken.startDistribution(address(stable));

        vm.prank(OWNER);
        zeroToken.claimIncome(id);

        assertTrue(zeroToken.incomeClaimed(id, OWNER));
        assertEq(stable.balanceOf(address(zeroToken)), 5 ether);
    }

    function test_BalanceOfAt_DefaultsToCurrentBalance() public {
        _fundIncome(INCOME_AMOUNT);
        vm.prank(OWNER);
        uint256 id = token.startDistribution(address(uzs));

        address outsider = address(0xDEAD);
        assertEq(token.balanceOf(outsider), 0);
        assertEq(token.balanceOfAt(outsider, id), 0);
        assertEq(token.balanceOfAt(OWNER, id), token.balanceOf(OWNER));
        assertEq(token.totalSupplyAt(id), token.totalSupply());
    }

    function test_ClaimIncome_RevertsForUnknownDistribution() public {
        // Rejects claims for unannounced distribution IDs.
        vm.expectRevert(abi.encodeWithSelector(YurtFraction.InvalidAsset.selector));
        vm.prank(ALICE);
        token.claimIncome(42);
    }

    function test_ClaimableIncome_NoDistribution() public view {
        // Dashboard query before any distribution should report zero.
        (address asset, uint256 amount) = token.claimableIncome(1, ALICE);
        assertEq(asset, address(0));
        assertEq(amount, 0);
    }

    /*//////////////////////////////////////////////////////////////
                               EXIT FLOW
    //////////////////////////////////////////////////////////////*/

    function test_TriggerExit_BlocksTransfers() public {
        // Property sold; all trading stops pending redemption.
        _addWhitelist(ALICE);
        vm.prank(OWNER);
        bool ok = token.transfer(ALICE, 10 ether);
        assertTrue(ok);

        vm.prank(OWNER);
        token.triggerExit();

        vm.expectRevert(abi.encodeWithSelector(YurtFraction.ExitLive.selector));
        vm.prank(ALICE);
        bool exitCheck = token.transfer(OWNER, 1 ether);
        exitCheck;

        vm.expectRevert(abi.encodeWithSelector(YurtFraction.ExitLive.selector));
        vm.prank(OWNER);
        bool exitCheckOwner = token.transfer(ALICE, 1 ether);
        exitCheckOwner;
    }

    function test_TriggerExit_OnlyOwner() public {
        // Prevent rogue holders from faking an exit event.
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, ALICE));
        vm.prank(ALICE);
        token.triggerExit();
    }

    function test_DepositExitProceeds() public {
        // Manager wires sale proceeds into escrow contract.
        _fundExit(EXIT_AMOUNT);
        assertEq(token.exitPot(address(uzs)), EXIT_AMOUNT);
    }

    function test_DepositExitProceeds_RevertsInvalidAsset() public {
        // Guard against misconfiguring payout token.
        vm.expectRevert(abi.encodeWithSelector(YurtFraction.InvalidAsset.selector));
        vm.prank(OWNER);
        token.depositExitProceeds(address(0), EXIT_AMOUNT);
    }

    function test_DepositExitProceeds_RevertsZeroAmount() public {
        // No no-op deposits; ensures actual liquidity hits the pool.
        vm.expectRevert(abi.encodeWithSelector(YurtFraction.ZeroAmount.selector));
        vm.prank(OWNER);
        token.depositExitProceeds(address(uzs), 0);
    }

    function test_DepositExitProceeds_OnlyOwner() public {
        // Only treasury can inject exit funds.
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, ALICE));
        vm.prank(ALICE);
        token.depositExitProceeds(address(uzs), EXIT_AMOUNT);
    }

    function test_RedeemOnExit_ProRata() public {
        // Investors cash out of the SPV after sale, burning their shares.
        _prepareExitShares();
        _fundExit(EXIT_AMOUNT);

        vm.prank(OWNER);
        token.triggerExit();

        uint256 aliceBalance = token.balanceOf(ALICE);
        uint256 bobBalance = token.balanceOf(BOB);

        uint256 expectedAlice = (EXIT_AMOUNT * aliceBalance) / TOTAL_SUPPLY;
        uint256 expectedBob = (EXIT_AMOUNT * bobBalance) / TOTAL_SUPPLY;

        assertEq(token.claimableExit(address(uzs), ALICE), expectedAlice);

        vm.prank(ALICE);
        token.redeemOnExit(address(uzs));
        assertEq(uzs.balanceOf(ALICE), expectedAlice);
        assertEq(token.balanceOf(ALICE), 0);
        assertEq(token.claimableExit(address(uzs), ALICE), 0);

        vm.expectRevert(abi.encodeWithSelector(YurtFraction.NoBalance.selector));
        vm.prank(ALICE);
        token.redeemOnExit(address(uzs));

        assertEq(token.exitPot(address(uzs)), EXIT_AMOUNT - expectedAlice);

        vm.prank(BOB);
        token.redeemOnExit(address(uzs));
        assertEq(uzs.balanceOf(BOB), expectedBob);
        assertEq(token.exitPot(address(uzs)), EXIT_AMOUNT - expectedAlice - expectedBob);
    }

    function test_RedeemOnExit_RevertsBeforeTrigger() public {
        // No redemption allowed while property still operating.
        vm.expectRevert(abi.encodeWithSelector(YurtFraction.ExitLive.selector));
        vm.prank(OWNER);
        token.redeemOnExit(address(uzs));
    }

    function test_RedeemOnExit_RevertsInvalidAsset() public {
        // Redemption must happen in the pre-agreed stablecoin.
        _prepareExitShares();
        _fundExit(EXIT_AMOUNT);

        vm.prank(OWNER);
        token.triggerExit();

        vm.expectRevert(abi.encodeWithSelector(YurtFraction.InvalidAsset.selector));
        vm.prank(ALICE);
        token.redeemOnExit(address(0));
    }

    function test_ClaimableExit_BeforeTriggerIsZero() public {
        // Portfolio dashboards show zero exit proceeds before sale.
        _prepareExitShares();
        _fundExit(EXIT_AMOUNT);

        assertEq(token.claimableExit(address(uzs), ALICE), 0);
        assertEq(token.claimableExit(address(uzs), BOB), 0);
    }

    /*//////////////////////////////////////////////////////////////
                              HELPERS
    //////////////////////////////////////////////////////////////*/

    function _addWhitelist(address account) internal {
        address[] memory accounts = new address[](1);
        accounts[0] = account;
        vm.prank(OWNER);
        token.addToWhitelist(accounts);
    }

    function _removeWhitelist(address account) internal {
        address[] memory accounts = new address[](1);
        accounts[0] = account;
        vm.prank(OWNER);
        token.removeFromWhitelist(accounts);
    }

    function _prepareDistributionShares() internal {
        _addWhitelist(ALICE);
        _addWhitelist(BOB);

        vm.prank(OWNER);
        bool ok = token.transfer(ALICE, 100_000 ether);
        assertTrue(ok);

        vm.prank(OWNER);
        ok = token.transfer(BOB, 50_000 ether);
        assertTrue(ok);
    }

    function _prepareExitShares() internal {
        _prepareDistributionShares();

        vm.prank(OWNER);
        bool ok = token.transfer(BOB, 50_000 ether); // Bob totals 100k, Owner keeps 800k
        assertTrue(ok);
    }

    function _fundIncome(uint256 amount) internal {
        uzs.mint(OWNER, amount);
        vm.prank(OWNER);
        uzs.approve(address(token), amount);
        vm.prank(OWNER);
        token.depositIncome(address(uzs), amount);
    }

    function _fundExit(uint256 amount) internal {
        uzs.mint(OWNER, amount);
        vm.prank(OWNER);
        uzs.approve(address(token), amount);
        vm.prank(OWNER);
        token.depositExitProceeds(address(uzs), amount);
    }
}
