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

## References

- [Solidity by example](https://solidity-by-example.org/app/simple-bytecode-contract/)
