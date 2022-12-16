// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// testing functionalities
import "forge-std/Test.sol";

// Ethernaut game components
import "src/levels/01-Fallback/FallbackFactory.sol"; //change this @todo
import "src/core/Ethernaut.sol";

//change this @todo
contract FallbackTest is
    Test //change this @todo
{
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    address attacker = makeNameForAddress("attacker");

    function setUp() public {
        emit log_string("Setting up Fallback level..."); //change this @todo
        ethernaut = new Ethernaut();
        // We need to give attacker some funds to attack the contract
        vm.deal(attacker, 10 wei);
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function testFallbackExploit() public {
        //change this @todo
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        FallbackFactory fallbackFactory = new FallbackFactory(); //change this @todo

        ethernaut.registerLevel(fallbackFactory); //change this @todo
        vm.startPrank(attacker);

        address levelAddress = ethernaut.createLevelInstance(fallbackFactory); //change this @todo
        Fallback fallbackContract = Fallback(payable(levelAddress)); //change this @todo

        emit log_named_address(
            "The original owner of the contract: ",
            fallbackContract.owner() //change this @todo
        );
        emit log_named_address(
            "Address of the exploit contract: ",
            address(this)
        );
        emit log_named_address("Attacker's address: ", address(attacker));
        emit log_named_uint("Balance of attacker (before): ", attacker.balance);
        emit log_named_uint(
            "Contract balance (before): ",
            address(fallbackContract).balance //change this @todo
        );

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/

        // @todo

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
