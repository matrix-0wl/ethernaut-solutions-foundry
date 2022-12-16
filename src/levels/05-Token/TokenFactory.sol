// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "src/core/Level.sol";
import "./Token.sol";

contract TokenFactory is Level {
    // @audit add underscores to improve readability -> 21_000_000
    uint supply = 21000000;
    uint playerSupply = 20;

    function createInstance(
        address _player
    ) public payable override returns (address) {
        Token token = new Token(supply);
        token.transfer(_player, playerSupply);
        return address(token);
    }

    function validateInstance(
        address payable _instance,
        address _player
    ) public override returns (bool) {
        Token token = Token(_instance);
        return token.balanceOf(_player) > playerSupply;
    }
}
