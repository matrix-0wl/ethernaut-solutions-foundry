// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

// testing functionalities
import "forge-std/Test-05.sol";

// Ethernaut game components
import {Ethernaut} from "src/core/Ethernaut-05.sol";
import {AlienCodexFactory, AlienCodex} from "src/levels/19-AlienCodex/AlienCodexFactory.sol";
import {AlienCodexAttack} from "src/levels/19-AlienCodex/AlienCodexAttack.sol";

contract AlienCodexTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    address attacker = makeNameForAddress("attacker");

    function setUp() public {
        emit log_string("Setting up AlienCodex level...");
        ethernaut = new Ethernaut();
        // We need to give attacker some funds to attack the contract
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function testAlienCodexExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        AlienCodexFactory alienCodexFactory = new AlienCodexFactory();

        ethernaut.registerLevel(alienCodexFactory);
        vm.startPrank(attacker);

        address levelAddress = ethernaut.createLevelInstance(alienCodexFactory);
        AlienCodex alienCodexContract = AlienCodex(payable(levelAddress));

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/

        emit log_named_address(
            "The original owner of the contract: ",
            alienCodexContract.owner()
        );

        emit log_named_address("Attacker's address: ", address(attacker));

        emit log_string("Starting the exploit...");
        AlienCodexAttack alienCodexAttack = new AlienCodexAttack(
            address(alienCodexContract)
        );
        alienCodexAttack.attack();

        // Test assertion
        assertEq(alienCodexContract.owner(), attacker);

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
