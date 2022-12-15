# Level 1 - Fallback
## Objectives
- claim ownership of the contract
- reduce its balance to 0

## Contract Overview
The fallback contract allows users to contribute ether to the contract. The contract is supposed to work as follows:
- if a user has contributed more than the owner, he then becomes the owner
- the owner can withdraw all of the funds
- `contribute()` function is restricted to payments smaller than `0.001` ether
	- claiming ownership this way would be very tedious because contributions of the initial owner are set to 1000 ether

## Finding the weak spots
The fallback contract contains a `receive()` function that at first glance contains flawed logic. The `receive()` function bypasses the main logic of a contract. It does not check if the amount of ether contributed by the user is larger than that of the owner. 

## Potential attack scenario - hypothesis
*Eve is our attacker.*

If Eve sends ether directly to the contract via external call, Eve can become the owner of the contract without the need to contribute more than the owner. 

## Plan of the attack
1. Eve must first contribute a small amount of ether to be listed in the `contributions` mapping. 
2. Eve can send ether via an external call to the `Fallback` contract and claim the ownership.
3. Eve can withdraw all the funds.

## Proof of Concept - hypothesis test ✅
Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/test/01-Fallback.t.sol))

```solidity
// eve calls `contribute()` function
// her address is added to the contributions mapping
fallbackContract.contribute.value(1 wei)();

// eve sends ether directly to the contract via external call
// this makes her the owner of the contract
(bool success, ) = address(fallbackContract).call.value(1 wei)("");
require(success);

// eve can now withdraw contract balance
fallbackContract.withdraw();
```

Here are the logs from the exploit contract:

![alt text](https://github.com/ChmielewskiKamil/ethernaut-foundry/blob/main/img/Fallback.png?raw=true)

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