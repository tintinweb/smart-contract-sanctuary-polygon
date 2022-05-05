/**
 *Submitted for verification at polygonscan.com on 2022-05-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract RewardContract {
    mapping(address => bool) managers;

    constructor() {
        managers[msg.sender] == true;
    }

    function addManager(address _addr) external {
        require(managers[msg.sender] == true, 'Error, you are not allowed');
        managers[_addr] = true;
    }

    function removeManger(address _addr) external {
        require(managers[msg.sender] == true, 'Error, you are not allowed');
        managers[_addr] = false;
    }

    function fund() external payable {}

    function distributeRewards(address[] memory holders, uint length, uint amount) external {
        require(managers[msg.sender] == true, 'Error, you are not allowed');

        for (uint i = 0; i < length; i ++) {
            payable(holders[i]).transfer(amount);
        }   
    }
}