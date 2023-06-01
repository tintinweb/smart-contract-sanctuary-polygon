/**
 *Submitted for verification at polygonscan.com on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract PrimerContrato {
    uint256 age = 2213;
    uint256 public year = 2023;

    function getAge() public view returns(uint256){
        return age;
    }

    function CambiarAge(uint256 newAge) public{
        age = newAge;
    }
}