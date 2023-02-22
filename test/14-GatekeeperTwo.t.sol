// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// testing functionalities
import "forge-std/Test.sol";

// Ethernaut game components
import {GatekeeperTwoFactory, GatekeeperTwo} from "src/levels/14-GatekeeperTwo/GatekeeperTwoFactory.sol";
import {GatekeeperTwoAttack} from "src/levels/14-GatekeeperTwo/GatekeeperTwoAttack.sol";
import "src/core/Ethernaut.sol";

//change this @todo
contract GatekeeperTwoTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    address attacker = makeNameForAddress("attacker");

    function setUp() public {
        emit log_string("Setting up GatekeeperTwo level...");
        ethernaut = new Ethernaut();
        // We need to give attacker some funds to attack the contract
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function test_GatekeeperTwoExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        GatekeeperTwoFactory gatekeeperTwoFactory = new GatekeeperTwoFactory();

        ethernaut.registerLevel(gatekeeperTwoFactory);
        vm.startPrank(attacker);

        address levelAddress = ethernaut.createLevelInstance(
            gatekeeperTwoFactory
        );

        GatekeeperTwo gatekeeperTwoContract = GatekeeperTwo(levelAddress);

        // emit log_string("Starting the exploit...");
        // emit log_named_address("Attacker's address", attacker);
        // emit log_named_address("This is tx.origin: ", tx.origin);

        emit log_string("Starting the exploit... ");
        emit log_named_address("Attacker's address", attacker);
        // emit log_named_address("Ethernaut's address", address(ethernaut));
        // emit log_named_address(
        //     "Factory's address",
        //     address(gatekeeperTwoFactory)
        // );
        // emit log_named_address(
        //     "Instance's address",
        //     address(gatekeeperTwoContract)
        // );
        // it turns out that there is a default value for tx.origin
        // set up by Foundry
        // 0x00a329c0648769a73afac7f9381e08fb43dbea72
        // this is the reason why this script was not working for Eve
        // she is not the tx.origin
        // Test contract is
        // startPrank sets msg.sender not tx.origin
        // it is possible to set tx.origin tho, but its buggy as hell
        emit log_named_address("This is tx.origin: ", tx.origin);

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/

        GatekeeperTwoAttack gatekeeperTwoAttack;

        gatekeeperTwoAttack = new GatekeeperTwoAttack(
            address(gatekeeperTwoContract)
        );

        emit log_named_address(
            "Address of the entrant: ",
            gatekeeperTwoContract.entrant()
        );

        assertEq(gatekeeperTwoContract.entrant(), tx.origin);

        /*//////////////////////////////////////////////////////////////
                                LEVEL SUBMISSION
        //////////////////////////////////////////////////////////////*/

        bool challengeCompleted = ethernaut.submitLevelInstance(
            payable(levelAddress)
        );
        vm.stopPrank();
        // assert(challengeCompleted);
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
