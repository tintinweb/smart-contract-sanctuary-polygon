/**
 *Submitted for verification at polygonscan.com on 2022-12-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract Immutable {

    uint public num0;
    uint public immutable num1;
    uint public num2;

    constructor () {
        num0 = 1;
        num1 = 2;
        num2 = 3;
    }
    function getNumber() public view returns (uint, uint, uint) {return (num0, num1, num2);}
    fallback() external {}
    //receive() external payable {}
}