/**
 *Submitted for verification at polygonscan.com on 2022-02-28
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.10;

contract Storage {

    string public name = "STORAGE";

    function getName() external view returns(string memory) {
        return name;
    }

    function setName(string calldata _name) external {
        name = _name;
    }

}