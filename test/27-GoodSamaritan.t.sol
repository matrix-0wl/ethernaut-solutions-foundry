// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "ds-test/test.sol";
import "forge-std/Vm.sol";

import "src/core/Ethernaut.sol";
import "src/levels/27-GoodSamaritan/GoodSamaritanFactory.sol";
import "src/levels/27-GoodSamaritan/GoodSamaritanAttack.sol";

contract GoodSamaritanTest is DSTest {
    Vm vm = Vm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));
    Ethernaut ethernaut;
    address hacker = vm.addr(1);

    function setUp() public {
        ethernaut = new Ethernaut();
    }

    function testGoodSamaritanHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        GoodSamaritanFactory goodSamaritanFactory = new GoodSamaritanFactory();
        ethernaut.registerLevel(goodSamaritanFactory);
        vm.startPrank(hacker);
        address levelAddress = ethernaut.createLevelInstance(
            goodSamaritanFactory
        );
        GoodSamaritan ethernautGoodSamaritan = GoodSamaritan(
            payable(levelAddress)
        );

        //////////////////
        // LEVEL ATTACK //
        //////////////////

        // 1. Attacker creates `GoodSamaritanAttack` contract providing the address of the `GoodSamaritan` contract.
        GoodSamaritanAttack goodSamaritanAttack = new GoodSamaritanAttack(
            address(ethernautGoodSamaritan)
        );

        emit log_named_uint(
            "Balance of GoodSamaritan Wallet before attack",
            ethernautGoodSamaritan.coin().balances(
                address(ethernautGoodSamaritan.wallet())
            )
        );

        emit log_named_uint(
            "Balance of GoodSamaritanAttack contract before attack",
            ethernautGoodSamaritan.coin().balances(address(goodSamaritanAttack))
        );

        emit log_string(
            "--------------------------------------------------------------------------"
        );

        // 2. Attacker calls the `attack()` function in the `GoodSamaritanAttack` contract that is invoking `requestDonation` on `GoodSamaritan` contract. The code proceeds to execute the `wallet.donate10(msg.sender)` function call.
        goodSamaritanAttack.attack();

        emit log_named_uint(
            "Balance of GoodSamaritan Wallet after attack",
            ethernautGoodSamaritan.coin().balances(
                address(ethernautGoodSamaritan.wallet())
            )
        );

        emit log_named_uint(
            "Balance of GoodSamaritanAttack contract after attack",
            ethernautGoodSamaritan.coin().balances(address(goodSamaritanAttack))
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
