# Level 17 - Recovery

## Objectives

- Recover (or remove) the 0.001 ether from the lost contract address.

## Contract Overview

The contract is comprised of two separate contracts, `Recovery` and `SimpleToken`. Overall, the contracts provide a simple token generation and transfer system, where tokens can be generated with an initial supply and then transferred between addresses. The contract also includes a way to collect ether in exchange for tokens and destroy the contract if needed.

## Static analysis (slither)

Here are the logs from the slither:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Recovery_slither.png)

## Finding the weak spots

The `SimpleToken` contract has at least two different problems:

- `transfer` function is always resetting the `_to` balance
- `destroy` function has no authentication requirements

### `transfer` function is always resetting the `_to` balance

The issue with the transfer function is that it does not correctly update the balances of both the sender and receiver. While the balance of the sender (msg.sender) is correctly updated, the balance of the receiver (\_to) is not updated properly. Instead, it is reset to the transfer amount (\_amount) rather than adding it to the existing balance.

This means that if a malicious actor were to call the transfer function with a transfer amount of 0, they could completely reset the balance of the victim to 0. This would result in the loss of all the victim's tokens, making this vulnerability a critical security issue.

### `destroy` function has no authentication requirements

The `destroy` function in the `SimpleToken` contract executes the `selfdestruct` opcode, which destroys the contract and sends any remaining ETH balance to the specified address. Moreover, this function does not have any authentication requirements, which means that anyone can call this function and destroy the contract, along with all the token balances of the users, and steal the deposited ETH.

## Potential attack scenario (hypothesis)

Attacker retrive the lost address of the deployed `SimpleToken`by computing it and than can call the `destroy` function that will execute a `selfdestruct(_to)` sending all the contract's balance to the `_to` address.

## Retrieve the lost address

According to the Ethereum Yellow Paper

> The address of the new account is defined as being the rightmost 160 bits of the Keccak hash of the RLP encoding of the structure containing only the sender and the account nonce.
>
> \_Reference: https://ethereum.github.io/yellowpaper/paper.pdf

Specifically, the new address is the rightmost 160 bits of the keccak256 hash of the RLP encoding of the sender/creator's address and the nonce.

- sender address - It is the address that created the contract.
- The nonce represents the number of contracts created by the factory contract or, if it's an EOA, the number of transactions by that account. In this case, since it's the first contract created by the factory contract, the nonce will be 1.
- The RLP encoding is used to encode arbitrarily nested arrays of binary data, and it's the primary encoding method used to serialize objects in Ethereum's execution layer. The RLP encoding for a 20-byte address is 0xd6, 0x94 according to the Ethereum Yellow Paper and other sources. And since the nonce is a single byte with a value of 1, its RLP encoding will be 0x01 because for all values under the range [0x00, 0x7f] (decimal [0, 127]), that byte is its own RLP encoding.

According to [ethereum.stackexchange.com](https://ethereum.stackexchange.com/questions/760/how-is-the-address-of-an-ethereum-contract-computed) it should look like:
`nonce1= address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, bytes1(0x01))))));`

## Plan of the attack

1. Attacker retrieves the lost address
2. Attacker calls the `destroy` function that will execute a `selfdestruct(_to)` sending all the contract's balance to the attacker address.
3. Function `attack` makes two calls to the `Preservation` contract.
4. The first call executes a function `setFirstTime` with an address of `PreservationAttack` casted to `uint256`.
5. Because the first call modified the address of `timeZone1LibraryAddress`, the second call will execute a malicious `setFirstTime` function on the `PreservationAttack` contract.
6. The malicious `setTime` function changes the state variable `owner` to be the address of attacker.

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/17-Recoverya.t.sol))

```solidity
        // 1. Attacker creates the `PreservationAttack` contract.
        PreservationAttack preservationAttack = new PreservationAttack(
            address(preservationContract)
        );

        emit log_string(
            "--------------------------------------------------------------------------"
        );
        emit log_named_address("Address of attacker: ", attacker);
        emit log_named_address(
            "Address of the contract owner before attack: ",
            preservationContract.owner()
        );
        emit log_string(
            "--------------------------------------------------------------------------"
        );
        emit log_string("Starting the exploit...");
        emit log_string(
            "--------------------------------------------------------------------------"
        );
        // 2. Attacker calls the `attack` function on the `PreservationAttack` contract.
        preservationAttack.attack();

        emit log_named_address(
            "Address of the contract owner after attack: ",
            preservationContract.owner()
        );

        // Test assertion
        assertEq(preservationContract.owner(), attacker);
```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Preservation.png)

## Recommendations

- `transfer` function is always resetting the `_to` balance
  To fix this, the transfer function should subtract the transfer amount (\_amount) from the balance of the sender and add it to the balance of the receiver. The corrected transfer function would look like this:

```solidity
function transfer(address _to, uint _amount) public {
    require(balances[msg.sender] >= _amount);
    balances[msg.sender] -= _amount;
    balances[_to] += _amount;
}
```

- `destroy` function has no authentication requirements
  One way to fix this would be to add an access control mechanism that restricts the calling of the destroy function to only the contract owner or an authorized admin. This can be achieved by adding a modifier that checks if the caller is the contract owner, and only allowing the destroy function to be executed if this condition is met.

```solidity
modifier onlyOwner() {
    require(msg.sender == owner, "Only the contract owner can call this function.");
    _;
}

function destroy(address payable _to) public onlyOwner {
    selfdestruct(_to);
}

```

## References

- [Blog Aditya Dixit](https://blog.dixitaditya.com/series/ethernaut)
- [Blog Stermi](https://stermi.xyz/blog/ethernaut-challenge-17-solution-recovery)
- [D-Squared YT - Ethernaut CTF Series](https://www.youtube.com/watch?v=_ylKN2R_o-Y&list=PLiAoBT74VLnmRIPZGg4F36fH3BjQ5fLnz)
- [Smart Contract Programmer YT - Ethernaut](https://www.youtube.com/playlist?list=PLO5VPQH6OWdWh5ehvlkFX-H3gRObKvSL6)
- [Mastering Ethereum book](https://github.com/ethereumbook/ethereumbook)

## Acknowledgements

The structure of my reports is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [Joran Honig Twitter thread](https://twitter.com/joranhonig/status/1539578735631949825?s=20&t=Kp6iDNXfRKQUBbsb_Yj5SQ)
