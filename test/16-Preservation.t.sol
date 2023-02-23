// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// testing functionalities
import "forge-std/Test.sol";

// Ethernaut game components
import {Ethernaut} from "src/core/Ethernaut-08.sol";
import {PreservationFactory, Preservation} from "src/levels/16-Preservation/PreservationFactory.sol";
import {PreservationAttack} from "src/levels/16-Preservation/PreservationAttack.sol";

contract PreservationTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    address attacker = makeNameForAddress("attacker");

    function setUp() public {
        emit log_string("Setting up Preservation level...");
        ethernaut = new Ethernaut();
        // We need to give attacker some funds to attack the contract
        vm.deal(attacker, 10 wei);
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function test_PreservationExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        PreservationFactory preservationFactory = new PreservationFactory();

        ethernaut.registerLevel(preservationFactory);
        vm.startPrank(attacker);

        address levelAddress = ethernaut.createLevelInstance(
            preservationFactory
        );

        Preservation preservationContract = Preservation(levelAddress);

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/

        // 1. Attacker creates the `PreservationAttack` contract.
        PreservationAttack preservationAttack = new PreservationAttack(
            address(preservationContract)
        );

        emit log_string(
            "--------------------------------------------------------------------------"
        );
        emit log_named_address("Address of attacker: ", attacker);
        emit log_named_address(
            "Address of the contract owner before attack: ",
            preservationContract.owner()
        );
        emit log_string(
            "--------------------------------------------------------------------------"
        );
        emit log_string("Starting the exploit...");
        emit log_string(
            "--------------------------------------------------------------------------"
        );
        // 2. Attacker calls the `attack` function on the `PreservationAttack` contract.
        preservationAttack.attack();

        emit log_named_address(
            "Address of the contract owner after attack: ",
            preservationContract.owner()
        );

        // Test assertion
        assertEq(preservationContract.owner(), attacker);

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
