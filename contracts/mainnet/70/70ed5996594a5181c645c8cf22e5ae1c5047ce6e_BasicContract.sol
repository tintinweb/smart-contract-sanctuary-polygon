/**
 *Submitted for verification at polygonscan.com on 2022-02-14
*/

// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BasicContract{

    mapping (address=>string)public addressName;
    mapping (address=>uint256)public addressAge;

    function editName(string memory _name)public {

        addressName[msg.sender]=_name;
    }
    function editName(uint256 _age)public {

        addressAge[msg.sender]=_age;
    }




}