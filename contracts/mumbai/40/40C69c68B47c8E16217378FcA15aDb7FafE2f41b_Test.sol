/**
 *Submitted for verification at polygonscan.com on 2022-12-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;


contract Test {
    uint256 public number;

    function add() public {
        number += 1;
    }

    function addParam(uint256 _num) public {
        number += _num;
    }

    function addParamPayable() public payable {
        number += msg.value;
    }

    function withdraw() public {
        payable(msg.sender).transfer(address(this).balance);
    }

}