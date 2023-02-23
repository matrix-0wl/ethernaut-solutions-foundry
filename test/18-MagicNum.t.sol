// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// testing functionalities
import "forge-std/Test.sol";

// Ethernaut game components
import {Ethernaut} from "src/core/Ethernaut-08.sol";
import {MagicNumFactory, MagicNum} from "src/levels/18-MagicNumber/MagicNumFactory.sol";
import {MagicNumAttack} from "src/levels/18-MagicNumber/MagicNumAttack.sol";

contract MagicNumTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    address attacker = makeNameForAddress("attacker");

    function setUp() public {
        emit log_string("Setting up MagicNum level...");
        ethernaut = new Ethernaut();
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function testMagicNumExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        MagicNumFactory magicNumFactory = new MagicNumFactory();

        ethernaut.registerLevel(magicNumFactory);
        vm.startPrank(attacker);

        address levelAddress = ethernaut.createLevelInstance(magicNumFactory);
        MagicNum magicNumContract = MagicNum(payable(levelAddress));

        emit log_string("Starting the exploit...");
        emit log_named_address("Attacker's address", attacker);

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/

        MagicNumAttack magicNumAttack = new MagicNumAttack(
            address(magicNumContract)
        );

        // Test assertion

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
