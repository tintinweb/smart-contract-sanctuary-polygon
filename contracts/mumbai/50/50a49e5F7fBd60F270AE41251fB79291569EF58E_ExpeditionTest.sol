// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract ExpeditionTest {
    event ExpeditionEnd(uint256 input1, uint256 input2);

    function endExpedition(uint256 input1, uint256 input2) external {
        emit ExpeditionEnd(input1, input2);
    }
}