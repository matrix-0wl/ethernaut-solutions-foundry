# Level 6 - Delegation

## Objectives

- claim ownership of the contract

## Contract Overview

`Delegation.sol` contains two contracts. A `Delegate` contract handles the logic of changing the owner of the `Delegation` contract.

It is similar to the proxy pattern, where two contracts are needed. The first one is
the proxy contract (also known as the storage layer). In our case, this is the
`Delegation` contract. It delegates calls to the second type of contract via
`delegatecall` in the `fallback()` function. This second contract is the
implementation contract (also known as the logic layer). In our case, this is
the `Delegate` contract.

## Static analysis (slither)

Here are the logs from the slither:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Delegation_slither.png)

## Finding the weak spots

The first weak spot of the `Delegation` contract is a `delegatecall`. In our case we're leveraging the `delegatecall` as a way to gain ownership (`pwn` in `Delegate` contract) thanks to updates happening in the middle-man contract (e.g. `Delegation` contract).

```solidity
  fallback() external {
    (bool result,) = address(delegate).delegatecall(msg.data); // <-- this line over here
    if (result) {
      this;
    }
  }
```

A `delegatecall` is a special low-level call in Solidity to make external calls to another contract.

When contract `A` executes `delegatecall` to contract `B`, `B`'s code is executed with contract `A`'s storage, `msg.sender` and `msg.value`.
_Reference: https://solidity-by-example.org/delegatecall/_

Delegate call code
![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Delegation_delegatecall.png)

Call code
![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Delegation_call.png)

This means that it is possible to modify a contract's storage using a code (malicious code) belonging to another contract.

The delegatecall has the following structure

```solidity
address.delegatecall(abi.encodeWithSignature("func_signature", "arguments"));
```

We can see that the contract is making a `delegatecall` to the `address(delegate)` that is the first contract `Delegate`. This call is taking an input of `msg.data` which means whatever data was passed while calling the `fallback` function. Since we can trigger the `fallback` function, we can essentially control the `msg.data` passed inside the delegate call.

An interesting thing to note about `delegatecall` is that whenever our user makes a call to contract `Delegation`, which in turn is making a delegate call to `Delegate`, the `msg.sender` received by the `Delegate` contract will be our user's address and not `Delegation`'s address.

In the Delegate contract we have an interesting `pwn()`

```solidity
  function pwn() public {
    owner = msg.sender;
  }
```

This will just assign a new owner to whoever calls the function.

The second weak spot is ordering of variables. Storage is placed into slots, commonly starting from slot `0`. If the called contract (e.g. `Delegate` contract) doesn't have the exact ordering of state variables, then funky things can happen with read/writes in the calling contract (e.g. `Delegation` contract).

## Potential attack scenario (hypothesis)

Attacker triggers `Fallback()` function inside the `Delegation` contract to invoke the `pwn()` function via `msg.data`. Then this will make a `delegatecall` to the `Delegate` contract and execute the `pwn()` function making an attacker (`msg.sender`) the owner of the `Delegate` contract. Since the caller contract's storage is modified, the value for the owner will be stored in slot 0 of the `Delegation` contract. Both of these contracts slot 0 variables have the same name, `owner`, which will make an attacker the owner in the `Delegation` contract.

## Plan of the attack

1.  Attacker triggers `Fallback()` function inside the `Delegation` contract to invoke the `pwn()` function via `msg.data`.
2.  Attacker gains an ownership of the `Delegate` contract, because triggerring `Fallback()` function will make a `delegatecall` to the `Delegate` contract and execute the `pwn()` function.
3.  Attacker gains an ownership of the `Delegation` contract, because both of contracts slot 0 variables have the same name, `owner`.

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/06-Delegation.t.sol))

```solidity
        emit log_named_address(
            "Owner of contract (before attack)",
            delegationContract.owner()
        );

        emit log_string("Starting the exploit...");
        (bool success, ) = address(delegationContract).call(
            abi.encodeWithSignature("pwn()")
        );

        emit log_named_address(
            "Owner of contract (after attack)",
            delegationContract.owner()
        );

        // Test assertion
        assertEq(success, true);
        assertEq(delegationContract.owner(), attacker);

```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Delegation.png)

## Recommendations

- The use of the `delegatecall` should be avoided. If it is necessary to use it,
  ensure that only trusted parties can call it. Moreover, particular attention
  needs to be paid to the input that can be provided by the user. It is
  discouraged to let users decide to which address the `delegatecall` should be
  made. Additionally, functions that proxy users are allowed to invoke at the
  destination address should be protected with some form of access control (like
  a whitelist for example).
- Functions in the implementation contracts should be protected. An
  implementation is a standalone contract, so it can be called directly without
  the use of a proxy (see
  [Parity Multi-sig bug 2](https://www.parity.io/blog/a-postmortem-on-the-parity-multi-sig-library-self-destruct/)).
- The return value from low-level calls should be checked. The `fallback()`
  function contains redundant code. The `if` statement does nothing and it
  should be replaced with a proper return value check. For example:

```solidity
require(result, "Delegatecall failed")
```

- Making ownership changes without the 0 address check may lead to the
  [loss of ownership](https://github.com/crytic/slither/wiki/Detector-Documentation#missing-zero-address-validation)
  of the contract. If the address is not specified, the default value of the
  address type will be used -> the 0 address. The contract will be locked
  forever.

## References

- [Blog Aditya Dixit](https://blog.dixitaditya.com/series/ethernaut)
- [D-Squared YT - Ethernaut CTF Series](https://www.youtube.com/watch?v=_ylKN2R_o-Y&list=PLiAoBT74VLnmRIPZGg4F36fH3BjQ5fLnz)
- [Smart Contract Programmer YT - Hack Solidity](https://www.youtube.com/watch?v=bqn-HzRclps&t=0s)
- [Mastering Ethereum book](https://github.com/ethereumbook/ethereumbook)
- [Solidity by example](https://solidity-by-example.org/delegatecall/https://solidity-by-example.org/hacks/delegatecall/)
- [Solidity by example hacks](https://solidity-by-example.org/hacks/delegatecall/)

## Acknowledgements

The structure of my reports is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [Joran Honig Twitter thread](https://twitter.com/joranhonig/status/1539578735631949825?s=20&t=Kp6iDNXfRKQUBbsb_Yj5SQ)

The recommendations section is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
