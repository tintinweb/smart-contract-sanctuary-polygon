/**
 *Submitted for verification at polygonscan.com on 2023-05-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract DurskiERC20{
    
    string name;
    uint public maxTotalSupply = 250000000;

    function setName(string memory newName) public {
        name = newName;
    }

    function getName() public view returns (string memory) {
        return name;
    }

}