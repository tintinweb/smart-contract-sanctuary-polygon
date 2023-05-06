/**
 *Submitted for verification at polygonscan.com on 2023-05-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract CanoERC20 {
    string name;
    uint maxTotalSupply = 100;

    function setName(string memory newName) public {
        name = newName;
    }

    function getName() public view returns (string memory) {
        return name;
    }

    function getMaxTotalSupply() public view returns (uint) {
        return maxTotalSupply;
    }

}