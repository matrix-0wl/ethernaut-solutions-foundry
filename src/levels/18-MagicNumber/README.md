# Level 18 - Magic Number

## Objectives

- Create and deploy a smart contract that weight less than 10 bytes and answer 42 when `whatIsTheMeaningOfLife` function is called.

## Contract Overview

The `MagicNum` contract allows a user to set a `solver` address, which can then be used to solve a "magic number" puzzle.

## Static analysis (slither)

Here are the logs from the slither:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/MagicNum_slither.png)

## Malicious contract (MagicNumAttack.sol)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MagicNum.sol";

contract MagicNumAttack {
    MagicNum magicNum;

    constructor(address _magicNum) {
        magicNum = MagicNum(_magicNum);

        // we know it from https://solidity-by-example.org/app/simple-bytecode-contract/
        bytes memory bytecode = hex"69602a60005260206000f3600052600a6016f3";
        address _solver;

        // we have to manually deploy this bytecode
        assembly {
            // we are going to call create function -> create(value, offset, size)
            // 0 value
            // offset is where our code starts. First 32 bytes stores the length of array so we have to skip first 32 bytes (in haxadecimal 0x20)
            /* using node to calculate size
                 > text = "69602a60005260206000f3600052600a6016f3"
                '69602a60005260206000f3600052600a6016f3'
                > text.length
                38
                > 38 / 2
                19
                > size = 19
                19
                > size.toString(16)
                '13'
                >
            */
            _solver := create(0, add(bytecode, 0x20), 0x13)
        }

        magicNum.setSolver(_solver);
    }
}
```

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/18-MagicNum.t.sol))

```solidity
    MagicNumAttack magicNumAttack = new MagicNumAttack(
            address(magicNumContract)
        );
```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/MagicNum.png)

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
