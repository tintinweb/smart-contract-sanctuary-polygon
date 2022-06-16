// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.4;

contract Testing {

    uint256 public number;

    event Set(address indexed user, uint256 amount);

    function set(uint256 num) public {
        number = num;
        emit Set(msg.sender, num);
    }
}