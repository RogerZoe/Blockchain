// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import {Box1} from "../src/Box1.sol";
import {BoxV2} from "../src/Box2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployAndUpgradeTest is Test {
    address public proxy;
    address public owner = makeAddr("owner");

    function setUp() public {
        // Deploy implementation
        Box1 implV1 = new Box1();

        // Deploy proxy
        proxy = address(new ERC1967Proxy(address(implV1), ""));

        // Initialize with the specific owner address
        vm.prank(owner);
        Box1(proxy).initialize();

        // Sanity check
        assertEq(Box1(proxy).version(), 1);
        assertEq(Box1(proxy).owner(), owner); // Verify owner is set correctly
    }

    function testProxyStartsAsBoxV1() public {
        // Should revert because BoxV1 has no setNumber
        vm.expectRevert();
        BoxV2(proxy).setNumber(7);
        assertEq(BoxV2(proxy).getNumber(), 0);
    }

    function testUpgradeToV2() public {
        // Deploy V2 impl
        BoxV2 implV2 = new BoxV2();

        // Only owner can upgrade
        vm.prank(owner);
        BoxV2(proxy).upgradeToAndCall(address(implV2), "");

        // Verify upgrade
        assertEq(BoxV2(proxy).version(), 2);

        // Now setNumber should work
        BoxV2(proxy).setNumber(42);
        assertEq(BoxV2(proxy).getNumber(), 42);
    }

    function testNonOwnerCannotUpgrade() public {
        BoxV2 implV2 = new BoxV2();
        address attacker = makeAddr("attacker");

        vm.prank(attacker);
        vm.expectRevert(); // because _authorizeUpgrade requires owner
        BoxV2(proxy).upgradeToAndCall(address(implV2), "");
    }
}