/**
 *Submitted for verification at polygonscan.com on 2022-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract BasePay  {

    mapping(address => uint256) public tradeFeeOf;

    mapping(address => mapping(address => uint256)) public merchantFunds;


}

contract Pay is BasePay {

   
    function set() external {

        tradeFeeOf[msg.sender] += 1;
        merchantFunds[msg.sender][msg.sender] += 1;
    }

}