// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// testing functionalities
import "forge-std/Test.sol";

// Ethernaut game components
import {Ethernaut} from "src/core/Ethernaut-08.sol";
import {PreservationFactory, Preservation} from "src/levels/16-Preservation/PreservationFactory.sol"; //change this @todo

//change this @todo
contract PreservationTest is
    Test //change this @todo
{
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    address attacker = makeNameForAddress("attacker");

    function setUp() public {
        emit log_string("Setting up Fallback level..."); //change this @todo
        ethernaut = new Ethernaut();
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function testFallbackExploit() public {
        //change this @todo
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        PreservationFactory preservationFactory = new PreservationFactory(); //change this @todo

        ethernaut.registerLevel(preservationFactory); //change this @todo
        vm.startPrank(attacker);

        address levelAddress = ethernaut.createLevelInstance(
            preservationFactory
        ); //change this @todo
        Preservation preservationContract = Preservation(payable(levelAddress)); //change this @todo

        emit log_string("Starting the exploit...");
        emit log_named_address("Attacker's address", attacker);

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/

        // @todo

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
