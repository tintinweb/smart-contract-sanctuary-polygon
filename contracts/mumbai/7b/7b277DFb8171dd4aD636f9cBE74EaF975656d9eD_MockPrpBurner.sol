// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2023 Panther Ventures Limited Gibraltar
pragma solidity 0.8.16;

contract MockPrpBurner {
    function burnPrp(uint256 amount, bytes calldata proof)
        external
        returns (bool)
    {
        return true;
    }
}