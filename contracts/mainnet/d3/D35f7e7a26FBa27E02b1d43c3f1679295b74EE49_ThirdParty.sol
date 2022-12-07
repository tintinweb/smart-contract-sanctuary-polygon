/**
 *Submitted for verification at polygonscan.com on 2022-12-07
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract ThirdParty {
    mapping (address => bool) private allowed;
    address public owner;


    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
        allowed[msg.sender] = true;
    }

    function setAllowedState(address user, bool newAllowance) external onlyOwner {
        allowed[user] = newAllowance;
    }

    function isAllowed(address user) external view returns (bool) {
        return allowed[user];
    }

    function changeOwner(address newOwner) external onlyOwner {
        owner = newOwner;
        allowed[newOwner] = true;
    }
}