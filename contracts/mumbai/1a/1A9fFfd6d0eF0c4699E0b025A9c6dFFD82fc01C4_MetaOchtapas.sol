// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

contract MetaOchtapas {
    uint public val;

    function donate() public payable {
        val = msg.value;
    }
}