// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev This contract uses ^0.8.0 compiler version
 * previous imports used the 0.6.0 version of OZ contracts
 *
 * It was necessary to add new OpenZeppelin helpers
 * in the utilities folder
 */
import "src/core/Level.sol";
import {GatekeeperTwo} from "./GatekeeperTwo.sol";

contract GatekeeperTwoFactory is Level {
    function createInstance(
        address _player
    ) public payable override returns (address) {
        _player;
        GatekeeperTwo instance = new GatekeeperTwo();
        return address(instance);
    }

    function validateInstance(
        address payable _instance,
        address _player
    ) public override returns (bool) {
        GatekeeperTwo instance = GatekeeperTwo(_instance);
        return instance.entrant() == _player;
    }
}
