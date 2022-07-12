/**
 *Submitted for verification at polygonscan.com on 2022-07-12
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract Test1 {
    uint public myUint;

    function setUint(uint _myUint) public {
        myUint = _myUint;
    }

    function killme() public {
        selfdestruct(payable(msg.sender));
    }
}