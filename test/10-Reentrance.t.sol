// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// testing functionalities
import "forge-std/Test.sol";

// Ethernaut game components
import "src/levels/10-Reentrance/ReentranceFactory.sol";
import "src/levels/10-Reentrance/ReentranceAttack.sol";
import "src/core/Ethernaut.sol";

contract ReentranceTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    address attacker = makeNameForAddress("attacker");

    function setUp() public {
        emit log_string("Setting up Reentrance level...");
        ethernaut = new Ethernaut();
        // We need to give attacker some funds to attack the contract
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function testReentranceExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        ReentranceFactory reentranceFactory = new ReentranceFactory();

        ethernaut.registerLevel(reentranceFactory);
        vm.startPrank(attacker);
        vm.deal(attacker, 0.001 ether);

        address payable levelAddress = payable(
            ethernaut.createLevelInstance{value: 0.001 ether}(reentranceFactory)
        );
        Reentrance reentranceContract = Reentrance(levelAddress);
        vm.deal(address(reentranceContract), 1 ether);
        emit log_named_uint(
            "Victim contract ether balance before withdrawal",
            address(reentranceContract).balance
        );

        // vm.deal(attacker, 1 ether);
        vm.deal(attacker, 1 ether);
        // emit log_named_uint("Attackers's ether balance", attacker.balance);
        // vm.deal(address(reentranceContract), 1 ether);
        // emit log_named_uint(
        //     "Balance of the vulnerable contract (initial)",
        //     address(reentranceContract).balance
        // );

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/

        ReentranceAttack reentranceAttack = new ReentranceAttack(
            address(reentranceContract)
        );
        emit log_named_uint(
            "Attackers's ether balance before attack",
            address(reentranceAttack).balance
        );

        emit log_named_uint(
            "Attacker contract balance in the victim contract before donation and withdrawal",
            reentranceContract.balanceOf(address(reentranceAttack))
        );

        emit log_string("Starting the exploit...");

        emit log_string("Starting the attack...");
        reentranceAttack.attack{value: 1 ether}();

        emit log_named_uint(
            "Attacker contract balance in the victim contract after donation and withdrawal",
            reentranceContract.balanceOf(address(reentranceAttack))
        );

        emit log_named_uint(
            "Victim contract ether balance after withdrawal",
            address(reentranceContract).balance
        );

        emit log_named_uint(
            "Attackers's ether balance after attack",
            address(reentranceAttack).balance
        );

        // Test assertion
        assertEq(address(reentranceContract).balance, 0);

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
