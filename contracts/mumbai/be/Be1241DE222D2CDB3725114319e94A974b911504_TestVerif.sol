/**
 *Submitted for verification at polygonscan.com on 2022-02-17
*/

// SPDX-FileCopyrightText: © 2022 Virtually Human Studio

// SPDX-License-Identifier: No-license

pragma solidity 0.8.11;

contract TestVerif {
    uint256 num = 1;

    function getNum() external view returns (uint256) {
        return num;
    }
}