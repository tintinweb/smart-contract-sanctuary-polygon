//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

contract TestTreasury {
    string public name = "Tresury";
    event Received(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}