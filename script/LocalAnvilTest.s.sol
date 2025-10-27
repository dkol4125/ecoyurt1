// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console2} from "forge-std/Script.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {YurtFraction} from "../src/YurtFraction.sol";

contract LocalAnvilTest is Script {
    uint256 private constant TOTAL_SUPPLY = 1_000_000 ether;
    uint256 private constant ALICE_SHARE = 100_000 ether;
    uint256 private constant BOB_SHARE = 100_000 ether;
    uint256 private constant INCOME_AMOUNT = 1_000 ether;
    uint256 private constant EXIT_AMOUNT = 5_000 ether;
    string private constant DEFAULT_MNEMONIC =
        "test test test test test test test test test test test junk";

    uint256 private ownerKey;
    uint256 private aliceKey;
    uint256 private bobKey;
    address private ownerAddr;
    address private aliceAddr;
    address private bobAddr;
    YurtFraction private token;
    ERC20Mock private uzs;

    function run() external {
        string memory mnemonic = vm.envOr("ANVIL_MNEMONIC", DEFAULT_MNEMONIC);
        ownerKey = vm.envOr("ANVIL_OWNER_PK", vm.deriveKey(mnemonic, 0));
        aliceKey = vm.envOr("ANVIL_ALICE_PK", vm.deriveKey(mnemonic, 1));
        bobKey = vm.envOr("ANVIL_BOB_PK", vm.deriveKey(mnemonic, 2));

        ownerAddr = vm.addr(ownerKey);
        aliceAddr = vm.addr(aliceKey);
        bobAddr = vm.addr(bobKey);

        uint256 distributionId;

        vm.startBroadcast(ownerKey);
        token = new YurtFraction(
            "Blue Meadow Yurt Shares",
            "YURT",
            TOTAL_SUPPLY,
            "ipfs://bafy...bundle",
            ownerAddr
        );
        uzs = new ERC20Mock();

        address[] memory whitelist = new address[](2);
        whitelist[0] = aliceAddr;
        whitelist[1] = bobAddr;
        token.addToWhitelist(whitelist);

        require(token.transfer(aliceAddr, ALICE_SHARE), "transfer alice");
        require(token.transfer(bobAddr, BOB_SHARE), "transfer bob");

        uzs.mint(ownerAddr, INCOME_AMOUNT + EXIT_AMOUNT);
        uzs.approve(address(token), INCOME_AMOUNT + EXIT_AMOUNT);

        token.depositIncome(address(uzs), INCOME_AMOUNT);
        distributionId = token.startDistribution(address(uzs));
        vm.stopBroadcast();

        uint256 expectedAliceIncome = _incomeShare(token, aliceAddr);
        uint256 expectedBobIncome = _incomeShare(token, bobAddr);
        uint256 expectedOwnerIncome = _incomeShare(token, ownerAddr);

        vm.startBroadcast(aliceKey);
        token.claimIncome(distributionId);
        vm.stopBroadcast();
        require(
            uzs.balanceOf(aliceAddr) == expectedAliceIncome,
            "alice income mismatch"
        );

        vm.startBroadcast(bobKey);
        token.claimIncome(distributionId);
        vm.stopBroadcast();
        require(
            uzs.balanceOf(bobAddr) == expectedBobIncome,
            "bob income mismatch"
        );

        vm.startBroadcast(ownerKey);
        token.claimIncome(distributionId);
        require(
            uzs.balanceOf(ownerAddr) == EXIT_AMOUNT + expectedOwnerIncome,
            "owner income mismatch"
        );

        token.depositExitProceeds(address(uzs), EXIT_AMOUNT);
        token.triggerExit();
        vm.stopBroadcast();

        uint256 expectedAliceExit = _exitShare(token, address(uzs), aliceAddr);

        vm.startBroadcast(aliceKey);
        token.redeemOnExit(address(uzs));
        vm.stopBroadcast();
        require(
            uzs.balanceOf(aliceAddr) ==
                expectedAliceIncome + expectedAliceExit,
            "alice exit mismatch"
        );
        require(
            token.balanceOf(aliceAddr) == 0,
            "alice balance not burned"
        );

        uint256 expectedBobExit = _exitShare(token, address(uzs), bobAddr);

        vm.startBroadcast(bobKey);
        token.redeemOnExit(address(uzs));
        vm.stopBroadcast();
        require(
            uzs.balanceOf(bobAddr) == expectedBobIncome + expectedBobExit,
            "bob exit mismatch"
        );
        require(token.balanceOf(bobAddr) == 0, "bob balance not burned");

        uint256 expectedOwnerExit = _exitShare(token, address(uzs), ownerAddr);

        vm.startBroadcast(ownerKey);
        token.redeemOnExit(address(uzs));
        vm.stopBroadcast();
        require(
            uzs.balanceOf(ownerAddr) ==
                expectedOwnerIncome + expectedOwnerExit,
            "owner exit mismatch"
        );

        require(token.totalSupply() == 0, "total supply not zeroed");
        require(token.exitPot(address(uzs)) == 0, "exit pot leftover");
        require(
            uzs.balanceOf(address(token)) == 0,
            "token holds residual uzs"
        );

        console2.log("Local Anvil smoke test passed");
    }

    function _incomeShare(
        YurtFraction tkn,
        address account
    ) private view returns (uint256) {
        return (INCOME_AMOUNT * tkn.balanceOf(account)) / TOTAL_SUPPLY;
    }

    function _exitShare(
        YurtFraction tkn,
        address asset,
        address account
    ) private view returns (uint256) {
        uint256 supply = tkn.totalSupply();
        if (supply == 0) return 0;
        uint256 pot = tkn.exitPot(asset);
        return (pot * tkn.balanceOf(account)) / supply;
    }
}
