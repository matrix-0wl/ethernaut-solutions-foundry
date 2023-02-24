// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "lib/forge-std/src/BaseTest.sol";
import {DenialFactory, Denial} from "src/levels/20-Denial/DenialFactory.sol";
import {DenialAttack} from "src/levels/20-Denial/DenialAttack.sol";

contract TestDenial is BaseTest {
    Denial private level;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new DenialFactory();
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
        level = Denial(levelAddress);

        // Check that the contract is correctly setup
    }

    function exploitLevel() internal override {
        /** CODE YOUR EXPLOIT HERE */
        vm.startPrank(player, player);

        // deploy the exploiter contract
        DenialAttack denialAttack = new DenialAttack(address(level));

        // 3. Owner calls the `withdraw` function that makes call to `fallback()` function in the attacker malicious contract.
        // The `withdraw` function will be called automatically by the `DenialFactory` contract

        vm.stopPrank();
    }
}
