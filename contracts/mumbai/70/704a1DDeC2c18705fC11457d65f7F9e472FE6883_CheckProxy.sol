/**
 *Submitted for verification at polygonscan.com on 2022-02-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CheckProxy {

    address public delegateContract = 0xAAA6eF85caaFAD034065a9760f57f2a3a934A2B9;

    function implementation() public view returns(address) {
        return delegateContract;
    }

}