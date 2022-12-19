/**
 *Submitted for verification at polygonscan.com on 2022-12-18
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.4;

contract Balance {
    function getBalance(address _address) public view returns (uint256) {
        return payable(_address).balance;
    }
}