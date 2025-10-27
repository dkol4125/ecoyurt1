// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console2} from "forge-std/Script.sol";
import {YurtFraction} from "../src/YurtFraction.sol";

contract Deploy is Script {
    function run() external {
        // Use Anvil's first account by default; set with env if you like
        uint256 pk = vm.envUint("DEPLOYER_PK");
        vm.startBroadcast(pk);

        YurtFraction token = new YurtFraction(
            "Blue Meadow Yurt Shares",
            "YURT",
            1_000_000 ether,
            "ipfs://bafy...bundle",
            vm.addr(pk)
        );

        console2.log("Token:", address(token));

        vm.stopBroadcast();
    }
}
