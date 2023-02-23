// SPDX-License-Identifier: MIT
/// @source https://github.com/OpenZeppelin/ethernaut/blob/master/contracts/contracts/levels/base/Level-08.sol
/// @notice this is needed for levels that use Solidity versions ^0.8.0

pragma solidity ^0.8.0;

import "src/utilities/Ownable-08.sol";

abstract contract Level is Ownable {
    function createInstance(
        address _player
    ) public payable virtual returns (address);

    function validateInstance(
        address payable _instance,
        address _player
    ) public virtual returns (bool);
}
