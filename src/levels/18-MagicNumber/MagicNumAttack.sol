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
