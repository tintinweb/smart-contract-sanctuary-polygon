/**
 *Submitted for verification at polygonscan.com on 2022-03-15
*/

/// type of licence for our contract
// SPDX-License-Identifier: MIT
/// version of solidity
pragma solidity >=0.8.0 <0.9.0;
/// the contract code in this example we're going to save the name and the age of
/// the owner of an specific address (a wallet address "your id in the blockchain")
contract PT_PolygonContract {
    /// mapping is like a dictionary where the key is our wallet address 
    /// we need a mapping for the names
    mapping(address => string) public adressToName;
    /// and a mapping for the ages
    mapping(address => uint256) public adressToAge;
    /// we need a function for adding a new name to the adressToName mapping
    function editName(string memory  _name) public {
        adressToName[msg.sender] = _name;
    }
    /// we need a function for adding a new age to the adressToAge mapping
    function editAge(uint256 _age) public {
        adressToAge[msg.sender] = _age;
    }
}