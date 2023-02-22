# Level 12 - Privacy

## Objectives

- Unlock the contract!
- The goal of this challenge is to be able to unlock `Privacy` contract by discovering the "secret" key stored in it.

## Contract Overview

Access to the `Privacy` contract is protected by a key. It is set during contract construction. The password string is saved as bytes32 in the `private` array `data` as variable number 2. The state of the `Privacy` is represented by the boolean flag `locked`. The contract is `locked` (`locked` is equal to true) and the goal is to change it to `false` by calling `unlock` function. To unlock it we know that our key is equal to `bytes16(data[2]))`;

The contract is straightforward, consisting of multiple state variables, a constructor, and an `unlock` function.

All the state variables are pretty useless, we are just interested in two variables:

- `bool public locked` that is initialized to `true` and hold the value that must be set to `false` to win the challenge
- `bytes32[3] private data` is the variable where our key is stored. We need to find out the value of `data[2]` to solve the challenge

```solidity

  bool public locked = true; // <-- this line over here
  uint256 public ID = block.timestamp;
  uint8 private flattening = 10;
  uint8 private denomination = 255;
  uint16 private awkwardness = uint16(block.timestamp);
  bytes32[3] private data; // <-- this line over here
```

The `constructor(bytes32[3] memory _data)` just initialize the data variable's value

```solidity
  constructor(bytes32[3] memory _data) {
    data = _data;
  }
```

Then we have `unlock(bytes16 _key)` that simply check if the `byte16 _key` input we have passed match the `data[2]` value. If the comparison return, true we have unlocked the contract and passed the challenge.

```solidity
  function unlock(bytes16 _key) public {
    require(_key == bytes16(data[2]));
    locked = false;
  }
```

## Static analysis (slither)

Here are the logs from the slither:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Privacy_slither.png)

## Finding the weak spots

All the storage data on the blockchain is publicly visible and anyone can obtain it.

The `unlock()` function is taking an input `_key` and comparing it with an already set `data` array in the constructor. We can not see the key hardcoded anywhere but the thing about blockchain is all the storage data is publicly visible and anyone can obtain it. The `private` variables are not meant to store "private" data/passwords.

Private state variables (and functions) are only hidden from other contracts. They are visible in the contracts in which they are defined. Any off-chain component can still query contracts storage and access specific storage slot values.

According to Solidity documentation, statically-sized variables (everything except mapping and dynamically-sized array types) are laid out contiguously in storage starting from position 0. Multiple items that need less than 32 bytes are packed into a single storage slot if possible.

This means that each variable type in Solidity is stored on storage slots and each slot is 32 bytes in size. If a variable is smaller than 32 bytes, then the EVM tries to pack multiple variables into a single slot to optimize the storage.

To clear this level we must understand the storage slot of each variable.

```solidity
  bool public locked = true; // slot 0
  uint256 public ID = block.timestamp; // slot 1
  uint8 private flattening = 10; // slot 2
  uint8 private denomination = 255; // slot 2
  uint16 private awkwardness = uint16(now); // slot 2
  bytes32[3] private data; // slot 3 to 6
```

We have to remember that each storage slot is 32 bytes (256 bits) in size.

- `bool locked` - Takes up 8 bits or 1 byte of space. This will be in slot 0.
- `uint256 ID` - Takes up 32 bytes or 256 bits of space. A full slot. This will be in slot 1.
- `uint8 flattening` - Takes up 1 byte of space. This will go in slot 2 as slot 1 is full.
- `uint8 denomination` - Takes up 1 byte of space. This will go in slot 2 as well due to packing.
- `uint16 awkwardness` - Takes up 2 bytes of space. This will go in slot 2 as well since 32 bytes is not completely filled.
- `bytes32[3] data` - Structs and array data always start a new slot and occupy whole slots. This will go in slot 3 and occupy till slot 6 since bytes32 take up a full slot of 32 bytes. The \_key will be on slot 5 according to this.

## Potential attack scenario (hypothesis)

Attacker to unlock contract has to send the value stored inside `bytes32[2] private data` (slot 5) variable as `bytes16` which will allow us to go through the `require` statement and set the `locked` to `false`.

Attacker can query the secret key from the appropriate storage slot via `vm.load()`.

## Plan of the attack

1. Attacker looks at the order of declaration of state variables in the contracts source code.
2. Attacker determines which storage slot will be occupied by the key.
3. Attacker performs a call to read the key from the storage.
4. Attacker can now make a call to the `unlock()` function passing the key (downcastinbg it to the `bytes16` type) as the argument.
5. The `Privacy` contract is unlocked.

## Proof of Concept

Here is a simplified version of the unit test exploiting the vulnerability ([complete version here](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/test/12-Privacy.t.sol))

```solidity
        console.log("Is Privacy contract locked?", privacyContract.locked());

        emit log_string("Starting the exploit...");
        emit log_string(
            "Attacker reads the data from the storage slot number 5..."
        );
        bytes32 key = vm.load(address(privacyContract), bytes32(uint256(5)));

        emit log_named_bytes32("Key is", key);

        emit log_named_bytes32("Downcasted data", bytes16(key));

        emit log_string(
            "Attacker calls the unlock function with the aquired data..."
        );

        privacyContract.unlock(bytes16(key));

        console.log("Is Privacy contract locked?", privacyContract.locked());

        // Test assertion
        assertEq(privacyContract.locked(), false);
```

Here are the logs from the exploit contract:

![alt text](https://github.com/matrix-0wl/ethernaut-solutions-foundry/blob/master/img/Privacy.png)

## Recommendations

- Nothing is private on the public blockchain. Sensitive information like passwords or keys should not be stored in a place where anyone can read them.
- Obfuscate the data or don't store it on the public ledger at all.
- Never store private data on the blockchain even inside private data types as everything is public and can be obtained.
- Slot packing helps a lot when you need to optimize your contracts to save some gas.

## References

- [Blog Aditya Dixit](https://blog.dixitaditya.com/series/ethernaut)
- [Blog Stermi](https://stermi.xyz/blog/ethernaut-challenge-12-solution-privacy)
- [D-Squared YT - Ethernaut CTF Series](https://www.youtube.com/watch?v=_ylKN2R_o-Y&list=PLiAoBT74VLnmRIPZGg4F36fH3BjQ5fLnz)
- [Smart Contract Programmer YT - Ethernaut](https://www.youtube.com/playlist?list=PLO5VPQH6OWdWh5ehvlkFX-H3gRObKvSL6)
- [Mastering Ethereum book](https://github.com/ethereumbook/ethereumbook)
- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)

## Acknowledgements

The structure of my reports is based on the insights provided by:

- [ChmielewskiKamil](https://github.com/ChmielewskiKamil/ethernaut-foundry)
- [Joran Honig Twitter thread](https://twitter.com/joranhonig/status/1539578735631949825?s=20&t=Kp6iDNXfRKQUBbsb_Yj5SQ)
