/**
 *Submitted for verification at polygonscan.com on 2022-03-16
*/

/// type of licence for our contract
// SPDX-License-Identifier: MIT
/// version of solidity
pragma solidity >=0.8.0 <0.9.0;

contract PT_PolygonConract {
    mapping(address => string) public addressToName;
    mapping(address => uint) public addressToAge;

    function editName(string memory _name) public {
        addressToName[msg.sender] = _name;
    }

    function editAge(uint _age) public {
        addressToAge[msg.sender] = _age;
    }
}