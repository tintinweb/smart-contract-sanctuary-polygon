/**
 *Submitted for verification at polygonscan.com on 2022-03-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract BasicContract {
    mapping (address => string) public addressToName;
    mapping (address => uint256) public addressToAge;

    function editName(string memory _name) public {
        addressToName[msg.sender] = _name;
    }

    function editAge(uint256 _age) public {
        addressToAge[msg.sender] = _age;
    }
}