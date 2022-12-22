// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "src/core/Level.sol";
import "./Vault.sol";

contract VaultFactory is Level {
    function createInstance(
        address _player
    ) public payable override returns (address) {
        _player;
        bytes32 password = "A very strong secret password :)";
        Vault instance = new Vault(password);
        return address(instance);
    }

    function validateInstance(
        address payable _instance,
        address
    ) public override returns (bool) {
        Vault instance = Vault(_instance);
        return !instance.locked();
    }
}
