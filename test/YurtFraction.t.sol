// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

import "forge-std/Test.sol";
import "../src/YurtFraction.sol";

contract YurtFractionTest is Test {
    YurtFraction token;
    address owner = address(0xABCD);
    address alice = address(0xBEEF);

    function setUp() public {
        token = new YurtFraction(
            "Blue Meadow Yurt Shares",
            "YURT",
            1_000_000 ether, // 1,000,000 shares at 18 decimals
            "ipfs://bafy...bundle",
            owner
        );
    }

    function test_InitialState() public view {
        assertEq(token.name(), "Blue Meadow Yurt Shares");
        assertEq(token.symbol(), "YURT");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 1_000_000 ether);
        assertEq(token.propertyURI(), "ipfs://bafy...bundle");
        assertEq(token.balanceOf(owner), 1_000_000 ether);
        assertEq(token.owner(), owner);
    }

    function test_Transfer() public {
        vm.prank(owner);
        token.transfer(alice, 10 ether);
        assertEq(token.balanceOf(alice), 10 ether);
        assertEq(token.balanceOf(owner), 1_000_000 ether - 10 ether);
    }

    function test_SetPropertyURI_OnlyOwner() public {
        vm.prank(owner);
        vm.expectEmit();
        emit YurtFraction.PropertyURIUpdated("ipfs://newbundle");
        token.setPropertyURI("ipfs://newbundle");
        assertEq(token.propertyURI(), "ipfs://newbundle");
    }

    function test_SetPropertyURI_RevertsForNonOwner() public {
        vm.prank(alice);
        // Expect custom error from OZ v5 Ownable
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                alice
            )
        );
        token.setPropertyURI("ipfs://nope");
    }
}
