// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// testing functionalities
import "forge-std/Test.sol";

// Ethernaut game components
import "src/levels/03-CoinFlip/CoinFlipFactory.sol";
import "src/core/Ethernaut.sol";
import "src/levels/03-CoinFlip/CoinFlipAttack.sol";

contract CoinFlipTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;
    // CoinFlipAttack coinFlipAttack;

    address attacker = makeNameForAddress("attacker");

    function setUp() public {
        emit log_string("Setting up CoinFlip level...");
        ethernaut = new Ethernaut();
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function test_CoinFlipExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        CoinFlipFactory coinFlipFactory = new CoinFlipFactory();

        ethernaut.registerLevel(coinFlipFactory);
        vm.startPrank(attacker);

        address levelAddress = ethernaut.createLevelInstance(coinFlipFactory);
        CoinFlip coinFlipContract = CoinFlip(payable(levelAddress));
        // coinFlipAttack = new CoinFlipAttack(levelAddress);

        emit log_named_address(
            "Address of the exploit contract: ",
            address(this)
        );
        emit log_named_address("Attackers's address: ", address(attacker));

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/

        // Malicious contract that contains `flip` function that calculates the outcome of the game in advance
        CoinFlipAttack coinFlipAttack = new CoinFlipAttack(levelAddress);

        emit log_named_uint(
            "Attacker's score before the attack: ",
            coinFlipContract.consecutiveWins()
        );
        emit log_string(
            "Attacker runs the exploit for 10 consecutive blocks..."
        );

        // Attack will be repeated in 10 consecutive blocks
        for (uint256 i = 1; i <= 10; i++) {
            vm.roll(i); // cheatcode to simulate running the attack on each subsequent block; we are using vm.roll() to create the next block
            // Calling the `flip` function from the malicious contract
            coinFlipAttack.flip();
            emit log_named_uint(
                "Consecutive wins: ",
                coinFlipContract.consecutiveWins()
            );
        }

        // Test assertion
        assertEq(coinFlipContract.consecutiveWins(), 10);

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
