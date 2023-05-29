// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;


contract SuaveContract {

    string public name;
    address public owner;

    event NewName(address indexed owner, string indexed  nName);
    
    constructor(string memory nomeNovo) {
        name = nomeNovo;
        owner = msg.sender;
    }
    
   function setName(string memory _newName) public {
       name = _newName;
       emit NewName(msg.sender, _newName);
   }

}