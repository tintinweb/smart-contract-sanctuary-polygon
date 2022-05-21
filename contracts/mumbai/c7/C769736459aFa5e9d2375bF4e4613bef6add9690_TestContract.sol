/**
 *Submitted for verification at polygonscan.com on 2022-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract TestContract {

    string public name;
    uint public amount;

    event UpdateName ( string oldValue, string newValue);
    event UpdateAmount ( uint oldValue, uint newValue);

    constructor(
        string memory _name,
        uint _amount
    ){
        name = _name;
        amount = _amount;
    }

    function updateName(string calldata newName) public {
        name = newName;
    }
    
    function updateAmount(uint newAmount) public {
        amount = newAmount;      
    }
}