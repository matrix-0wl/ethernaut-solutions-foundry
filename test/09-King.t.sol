// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// testing functionalities
import "forge-std/Test.sol";

// Ethernaut game components
import "src/levels/09-King/KingFactory.sol";
import "src/levels/09-King/KingAttack.sol";
import "src/core/Ethernaut.sol";

//change this @todo
contract KingTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    address attacker = makeNameForAddress("attacker");

    function setUp() public {
        emit log_string("Setting up King level...");
        ethernaut = new Ethernaut();
        // We need to give attacker some funds to attack the contract
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function testKingExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        KingFactory kingFactory = new KingFactory();

        ethernaut.registerLevel(kingFactory);
        vm.startPrank(attacker);
        vm.deal(attacker, 2 ether);

        address levelAddress = ethernaut.createLevelInstance{value: 1 ether}(
            kingFactory
        );
        King kingContract = King(payable(levelAddress));

        emit log_named_address("Original king: ", kingContract._king());

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/

        emit log_string(
            "Deploying the attack contract and sending ether to claim kingship...."
        );
        KingAttack kingAttack = new KingAttack{value: kingContract.prize()}(
            payable(levelAddress)
        );

        emit log_named_address("Attacker address: ", address(kingAttack));

        emit log_named_address("New king: ", kingContract._king());

        // Test assertion
        assertEq(kingContract._king(), address(kingAttack));

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
