/**
 *Submitted for verification at polygonscan.com on 2022-12-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract NumberStandard {
    uint public num;
    constructor (uint _num) public {
        num = _num;
    }
    function getNum() public view returns (uint) {
        return num;
    }
    function setNum(uint _num) public {
        num = _num;
    }
    fallback() external payable {}
    receive() external payable {}
}