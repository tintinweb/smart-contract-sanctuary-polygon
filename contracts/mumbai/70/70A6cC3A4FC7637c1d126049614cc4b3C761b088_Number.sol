/**
 *Submitted for verification at polygonscan.com on 2022-09-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Number{

    // Mapping of User address to bool 
    mapping ( address => bool) private userToBool;

    // The number
    uint256 private number = 0;

    // number of Users
    uint256 private numberOfUsers = 0;

    // Decimals
    uint8 public constant decimals = 18;

    
    function updateNumber(uint256 _number) public {
        if(!userToBool[msg.sender]){
            numberOfUsers = numberOfUsers + 1;
            userToBool[msg.sender] = true;
        }
        number = _number;
    }

    function getInfo() public view returns(uint256, uint256){
        return (number , numberOfUsers);
    }


}